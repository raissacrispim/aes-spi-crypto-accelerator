`timescale 1ns/1ps

// Testbench autoverificavel do datapath AES-128 (minisoc_aes_dp) com a
// expansao de chave (minisoc_aes_key_exp).
//
// Verificacoes:
//   1. Expansao de chave: as 11 round keys dos Apendices A.1 e C.1 da FIPS-197
//      e a latencia de 11 ciclos (carga + 10 round keys).
//   2. Cifra e cifra inversa dos Apendices B e C.1, nos dois sentidos, com
//      latencia de 11 ciclos por bloco.
//   3. Oito vetores adicionais (chave, plaintext, ciphertext) gerados por um
//      modelo de referencia AES-128 independente em Python, nos dois sentidos.
//   4. Um i_start com o datapath ocupado e ignorado.

module minisoc_aes_dp_tb;

    localparam int KEY_EXP_CYCLES = 11;   // 1 de carga + 10 round keys
    localparam int BLOCK_CYCLES   = 11;   // 1 de carga + 10 rodadas

    logic         clk = 1'b0;
    logic         rst_n;

    // minisoc_aes_key_exp
    logic         ke_start;
    logic [127:0] ke_key;
    logic         ke_busy, ke_ready, ke_done;
    logic [3:0]   ke_idx;
    logic [127:0] ke_rk;

    // minisoc_aes_dp
    logic         dp_start;
    logic         dp_decrypt;
    logic [127:0] dp_block_in;
    logic         dp_busy, dp_done;
    logic [127:0] dp_block_out;
    logic [3:0]   dp_rk_idx;

    // Leitura das round keys: pelo datapath ou pelo testbench
    logic         tb_read_rk;
    logic [3:0]   tb_rk_idx;

    assign ke_idx = tb_read_rk ? tb_rk_idx : dp_rk_idx;

    minisoc_aes_key_exp u_key_exp (
        .clk      (clk),
        .rst_n    (rst_n),
        .i_start  (ke_start),
        .i_key    (ke_key),
        .o_busy   (ke_busy),
        .o_ready  (ke_ready),
        .o_done   (ke_done),
        .i_rk_idx (ke_idx),
        .o_rk     (ke_rk)
    );

    minisoc_aes_dp u_dp (
        .clk       (clk),
        .rst_n     (rst_n),
        .i_start   (dp_start),
        .i_decrypt (dp_decrypt),
        .i_block   (dp_block_in),
        .o_busy    (dp_busy),
        .o_done    (dp_done),
        .o_block   (dp_block_out),
        .o_rk_idx  (dp_rk_idx),
        .i_rk      (ke_rk)
    );

    always #5 clk = ~clk;

    int errors = 0;
    int checks = 0;

    task automatic check(input string what, input logic [127:0] got, input logic [127:0] exp);
        checks++;
        if (got !== exp) begin
            $error("%s\n    obtido   : %032h\n    esperado : %032h", what, got, exp);
            errors++;
        end
    endtask

    task automatic check_int(input string what, input int got, input int exp);
        checks++;
        if (got != exp) begin
            $error("%s: obtido %0d, esperado %0d", what, got, exp);
            errors++;
        end
    endtask

    // Expande a chave e confere a latencia
    task automatic expand_key(input string name, input logic [127:0] key);
        int cycles;
        @(negedge clk);
        ke_key   = key;
        ke_start = 1'b1;
        @(negedge clk);
        ke_start = 1'b0;
        cycles   = 1;
        while (!ke_done) begin
            @(negedge clk);
            cycles++;
        end
        check_int({name, ": latencia da expansao de chave"}, cycles, KEY_EXP_CYCLES);
        checks++;
        if (!ke_ready) begin
            $error("%s: o_ready nao subiu ao fim da expansao", name);
            errors++;
        end
    endtask

    // Le a round key idx diretamente do banco
    task automatic read_rk(input logic [3:0] idx, output logic [127:0] rk);
        tb_read_rk = 1'b1;
        tb_rk_idx  = idx;
        #1;
        rk = ke_rk;
        tb_read_rk = 1'b0;
    endtask

    // Processa um bloco e confere resultado e latencia
    task automatic run_block(input string what, input logic decrypt,
                             input logic [127:0] in, input logic [127:0] exp);
        int cycles;
        @(negedge clk);
        dp_decrypt  = decrypt;
        dp_block_in = in;
        dp_start    = 1'b1;
        @(negedge clk);
        dp_start = 1'b0;
        cycles   = 1;
        while (!dp_done) begin
            @(negedge clk);
            cycles++;
        end
        check(what, dp_block_out, exp);
        check_int({what, ": latencia"}, cycles, BLOCK_CYCLES);
    endtask

    task automatic check_vector(input int n, input logic [127:0] key,
                                input logic [127:0] pt, input logic [127:0] ct);
        string name;
        name = $sformatf("Vetor %0d", n);
        expand_key(name, key);
        run_block({name, ": cifra"},   1'b0, pt, ct);
        run_block({name, ": decifra"}, 1'b1, ct, pt);
    endtask

    logic [127:0] rk_b [0:10];
    logic [127:0] rk_c [0:10];

    initial begin
        logic [127:0] rk;

        $display("=== minisoc_aes_dp_tb ===");

        rk_b[0 ] = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        rk_b[1 ] = 128'ha0fafe1788542cb123a339392a6c7605;
        rk_b[2 ] = 128'hf2c295f27a96b9435935807a7359f67f;
        rk_b[3 ] = 128'h3d80477d4716fe3e1e237e446d7a883b;
        rk_b[4 ] = 128'hef44a541a8525b7fb671253bdb0bad00;
        rk_b[5 ] = 128'hd4d1c6f87c839d87caf2b8bc11f915bc;
        rk_b[6 ] = 128'h6d88a37a110b3efddbf98641ca0093fd;
        rk_b[7 ] = 128'h4e54f70e5f5fc9f384a64fb24ea6dc4f;
        rk_b[8 ] = 128'head27321b58dbad2312bf5607f8d292f;
        rk_b[9 ] = 128'hac7766f319fadc2128d12941575c006e;
        rk_b[10] = 128'hd014f9a8c9ee2589e13f0cc8b6630ca6;

        rk_c[0 ] = 128'h000102030405060708090a0b0c0d0e0f;
        rk_c[1 ] = 128'hd6aa74fdd2af72fadaa678f1d6ab76fe;
        rk_c[2 ] = 128'hb692cf0b643dbdf1be9bc5006830b3fe;
        rk_c[3 ] = 128'hb6ff744ed2c2c9bf6c590cbf0469bf41;
        rk_c[4 ] = 128'h47f7f7bc95353e03f96c32bcfd058dfd;
        rk_c[5 ] = 128'h3caaa3e8a99f9deb50f3af57adf622aa;
        rk_c[6 ] = 128'h5e390f7df7a69296a7553dc10aa31f6b;
        rk_c[7 ] = 128'h14f9701ae35fe28c440adf4d4ea9c026;
        rk_c[8 ] = 128'h47438735a41c65b9e016baf4aebf7ad2;
        rk_c[9 ] = 128'h549932d1f08557681093ed9cbe2c974e;
        rk_c[10] = 128'h13111d7fe3944a17f307a78b4d2b30c5;

        ke_start    = 1'b0;
        ke_key      = '0;
        dp_start    = 1'b0;
        dp_decrypt  = 1'b0;
        dp_block_in = '0;
        tb_read_rk  = 1'b0;
        tb_rk_idx   = '0;
        rst_n       = 1'b0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        // ---- FIPS-197 Apendice C.1 ----
        expand_key("C.1", 128'h000102030405060708090a0b0c0d0e0f);
        for (int r = 0; r <= 10; r++) begin
            read_rk(r[3:0], rk);
            check($sformatf("C.1: round key %0d", r), rk, rk_c[r]);
        end
        run_block("C.1: cifra",   1'b0, 128'h00112233445566778899aabbccddeeff, 128'h69c4e0d86a7b0430d8cdb78070b4c55a);
        run_block("C.1: decifra", 1'b1, 128'h69c4e0d86a7b0430d8cdb78070b4c55a, 128'h00112233445566778899aabbccddeeff);

        // ---- FIPS-197 Apendices A.1 / B ----
        expand_key("B", 128'h2b7e151628aed2a6abf7158809cf4f3c);
        for (int r = 0; r <= 10; r++) begin
            read_rk(r[3:0], rk);
            check($sformatf("A.1: round key %0d", r), rk, rk_b[r]);
        end
        run_block("B: cifra",   1'b0, 128'h3243f6a8885a308d313198a2e0370734, 128'h3925841d02dc09fbdc118597196a0b32);
        run_block("B: decifra", 1'b1, 128'h3925841d02dc09fbdc118597196a0b32, 128'h3243f6a8885a308d313198a2e0370734);

        // ---- i_start durante o processamento deve ser ignorado ----
        @(negedge clk);
        dp_decrypt  = 1'b0;
        dp_block_in = 128'h3243f6a8885a308d313198a2e0370734;
        dp_start    = 1'b1;
        @(negedge clk);
        dp_block_in = 128'hffffffffffffffffffffffffffffffff;
        dp_decrypt  = 1'b1;              // tentativa de novo start ocupado
        @(negedge clk);
        dp_start = 1'b0;
        while (!dp_done) @(negedge clk);
        check("B: start durante busy ignorado", dp_block_out, 128'h3925841d02dc09fbdc118597196a0b32);
        @(negedge clk);
        checks++;
        if (dp_busy) begin
            $error("start durante busy iniciou nova operacao");
            errors++;
        end

        // ---- Vetores adicionais (modelo de referencia em Python) ----
        check_vector(1, 128'h3ca33472d7fbe17a0129389332e605fb, 128'ha06bcb80b2b6c027ae2d9593ea489e0c, 128'h21233caff9ceefbd741c28a4d555d752);
        check_vector(2, 128'hbcbaecd82eccff3bd9fbcb84d7f50c72, 128'h421934dbf048f6753ee9f080cd9df5cd, 128'h4e91196f7d1503e60bec9bc650840c73);
        check_vector(3, 128'hdd67968904104ceafab86685f8eefede, 128'h1194a2ea32e084e75dd9f52088ffbd31, 128'h69795867ac79405a81949a2d65d06c13);
        check_vector(4, 128'h63d24ae6072f00e72a657e3d1689b64f, 128'h02a0fb4572f243942bd551459cd2c74c, 128'hb74eece67f953c09006dc9f75c89ad9b);
        check_vector(5, 128'h64c00736c7251ab1b40d0df3a79be6a6, 128'h3efeee574e69deacea7723cc11645817, 128'hac098f13945a7a024a97eb0c1d288616);
        check_vector(6, 128'h18e760f70a426f46525fc78bd9d428c4, 128'h9c5fb05986edfed493ef5aa6f6e33d8c, 128'hd45bab95be74454e07cbc93c6bbdbe9c);
        check_vector(7, 128'h306d76022fe8a9d05d0db450b46e388f, 128'h6d968943338731df57361eb65e36a08d, 128'h7b72cfe5cde81438f24af534db4a15f5);
        check_vector(8, 128'h2095a15285832007d283d4071d31780b, 128'h9e3e30b3a1e913cea16eecda3dbf80c7, 128'h7fe0077daf2cee42e7fd12fbf26dce14);

        if (errors != 0)
            $fatal(1, "FAIL: %0d de %0d verificacoes falharam", errors, checks);

        $display("PASS: expansao de chave e datapath AES-128, cifra e decifra (%0d verificacoes)", checks);
        $finish;
    end

    // Protecao contra travamento
    initial begin
        #200000;
        $fatal(1, "FAIL: timeout");
    end

endmodule
