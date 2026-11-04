`timescale 1ns/1ps

// Testbench autoverificavel das transformacoes de rodada do AES-128.
//
// Parte 1 - testes unitarios (FIPS-197):
//   Apendice B   (cifragem):          MixColumns(after ShiftRows) == after MixColumns
//                                     AddRoundKey(after MixColumns, k) == start da proxima rodada
//                                     InvMixColumns(after MixColumns) == after ShiftRows
//   Apendice C.1 (cifragem inversa):  AddRoundKey(is_box, k) == ik_add
//                                     InvMixColumns(ik_add) == start da proxima rodada
//
// Parte 2 - encadeamento completo:
//   As transformacoes sao compostas na ordem da FIPS-197 (secoes 5.1 e 5.3),
//   com as round keys dos Apendices A.1 e C.1, e devem reproduzir o
//   ciphertext (cifragem) e o plaintext (cifragem inversa) dos Apendices B e C.1.
//   Isso confirma que os modulos funcionam juntos, na convencao de bytes do
//   Block Guide, antes do datapath da Semana 4.

module minisoc_aes_round_tb;

    // Uma instancia de cada transformacao (todas combinacionais)
    logic [127:0] sb_in,  sb_out;
    logic [127:0] sr_in,  sr_out;
    logic [127:0] mc_in,  mc_out;
    logic [127:0] isb_in, isb_out;
    logic [127:0] isr_in, isr_out;
    logic [127:0] imc_in, imc_out;
    logic [127:0] ark_in, ark_key, ark_out;

    minisoc_aes_sub_bytes       u_sb  (.i_state(sb_in),  .o_state(sb_out));
    minisoc_aes_shift_rows      u_sr  (.i_state(sr_in),  .o_state(sr_out));
    minisoc_aes_mix_columns     u_mc  (.i_state(mc_in),  .o_state(mc_out));
    minisoc_aes_inv_sub_bytes   u_isb (.i_state(isb_in), .o_state(isb_out));
    minisoc_aes_inv_shift_rows  u_isr (.i_state(isr_in), .o_state(isr_out));
    minisoc_aes_inv_mix_columns u_imc (.i_state(imc_in), .o_state(imc_out));
    minisoc_aes_add_round_key   u_ark (.i_state(ark_in), .i_round_key(ark_key), .o_state(ark_out));

    int errors = 0;
    int checks = 0;

    // Round keys (FIPS-197, Apendice A.1 e Apendice C.1)
    logic [127:0] rk_b [0:10];
    logic [127:0] rk_c [0:10];

    // Round key r do vetor selecionado (0 = Apendice B, 1 = Apendice C.1)
    function automatic logic [127:0] rk(input bit vec_c, input int r);
        return vec_c ? rk_c[r] : rk_b[r];
    endfunction

    task automatic check(input string what, input logic [127:0] got, input logic [127:0] exp);
        checks++;
        if (got !== exp) begin
            $error("%s\n    obtido   : %032h\n    esperado : %032h", what, got, exp);
            errors++;
        end
    endtask

    // ---------------- Funcoes que usam as instancias ----------------

    task automatic do_sb (input logic [127:0] s, output logic [127:0] o); sb_in  = s; #1; o = sb_out;  endtask
    task automatic do_sr (input logic [127:0] s, output logic [127:0] o); sr_in  = s; #1; o = sr_out;  endtask
    task automatic do_mc (input logic [127:0] s, output logic [127:0] o); mc_in  = s; #1; o = mc_out;  endtask
    task automatic do_isb(input logic [127:0] s, output logic [127:0] o); isb_in = s; #1; o = isb_out; endtask
    task automatic do_isr(input logic [127:0] s, output logic [127:0] o); isr_in = s; #1; o = isr_out; endtask
    task automatic do_imc(input logic [127:0] s, output logic [127:0] o); imc_in = s; #1; o = imc_out; endtask
    task automatic do_ark(input logic [127:0] s, input logic [127:0] k, output logic [127:0] o);
        ark_in = s; ark_key = k; #1; o = ark_out;
    endtask

    // ---------------- Parte 1: testes unitarios ----------------

    // Apendice B: after ShiftRows -> after MixColumns -> (+ k) start da proxima rodada
    task automatic cipher_round(input int r, input logic [127:0] shift, input logic [127:0] mix,
                                input logic [127:0] key, input logic [127:0] next_start);
        logic [127:0] o;
        do_mc (shift, o);     check($sformatf("B rodada %0d: MixColumns",    r), o, mix);
        do_imc(mix, o);       check($sformatf("B rodada %0d: InvMixColumns", r), o, shift);
        do_ark(mix, key, o);  check($sformatf("B rodada %0d: AddRoundKey",   r), o, next_start);
    endtask

    // Apendice C.1: is_box -> (+ k) ik_add -> InvMixColumns -> start da proxima rodada
    task automatic inv_cipher_round(input int r, input logic [127:0] isub, input logic [127:0] key,
                                    input logic [127:0] ark, input logic [127:0] next_start);
        logic [127:0] o;
        do_ark(isub, key, o); check($sformatf("C.1 rodada %0d: AddRoundKey",   r), o, ark);
        do_imc(ark, o);       check($sformatf("C.1 rodada %0d: InvMixColumns", r), o, next_start);
    endtask

    // ---------------- Parte 2: encadeamento completo ----------------

    // Cifragem (FIPS-197, secao 5.1)
    task automatic cipher(input logic [127:0] pt, input bit vec_c, output logic [127:0] ct);
        logic [127:0] s;
        do_ark(pt, rk(vec_c, 0), s);
        for (int r = 1; r <= 10; r++) begin
            do_sb(s, s);
            do_sr(s, s);
            if (r < 10) do_mc(s, s);
            do_ark(s, rk(vec_c, r), s);
        end
        ct = s;
    endtask

    // Cifragem inversa (FIPS-197, secao 5.3)
    task automatic inv_cipher(input logic [127:0] ct, input bit vec_c, output logic [127:0] pt);
        logic [127:0] s;
        do_ark(ct, rk(vec_c, 10), s);
        for (int r = 9; r >= 0; r--) begin
            do_isr(s, s);
            do_isb(s, s);
            do_ark(s, rk(vec_c, r), s);
            if (r > 0) do_imc(s, s);
        end
        pt = s;
    endtask

    initial begin
        logic [127:0] o;

        $display("=== minisoc_aes_round_tb ===");

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

        // Parte 1: Apendice B
        cipher_round(1, 128'hd4bf5d30e0b452aeb84111f11e2798e5, 128'h046681e5e0cb199a48f8d37a2806264c,
                        rk_b[1], 128'ha49c7ff2689f352b6b5bea43026a5049);
        cipher_round(2, 128'h49db873b453953897f02d2f177de961a, 128'h584dcaf11b4b5aacdbe7caa81b6bb0e5,
                        rk_b[2], 128'haa8f5f0361dde3ef82d24ad26832469a);
        cipher_round(9, 128'h876e46a6f24ce78c4d904ad897ecc395, 128'h473794ed40d4e4a5a3703aa64c9f42bc,
                        rk_b[9], 128'heb40f21e592e38848ba113e71bc342d2);
        // Rodada 10 (sem MixColumns): after ShiftRows + k10 = ciphertext
        do_ark(128'he9317db5cb322c723d2e895faf090794, rk_b[10], o);
        check("B rodada 10: AddRoundKey", o, 128'h3925841d02dc09fbdc118597196a0b32);

        // Parte 1: Apendice C.1
        inv_cipher_round(1, 128'hbd6e7c3df2b5779e0b61216e8b10b689, rk_c[9],
                            128'he9f74eec023020f61bf2ccf2353c21c7, 128'h54d990a16ba09ab596bbf40ea111702f);
        inv_cipher_round(2, 128'hfde3bad205e5d0d73547964ef1fe37f1, rk_c[8],
                            128'hbaa03de7a1f9b56ed5512cba5f414d23, 128'h3e1c22c0b6fcbf768da85067f6170495);
        inv_cipher_round(9, 128'h89d810e8855ace682d1843d8cb128fe4, rk_c[1],
                            128'h5f72641557f5bc92f7be3b291db9f91a, 128'h6353e08c0960e104cd70b751bacad0e7);
        // Rodada 10 (sem InvMixColumns): is_box + k0 = plaintext
        do_ark(128'h00102030405060708090a0b0c0d0e0f0, rk_c[0], o);
        check("C.1 rodada 10: AddRoundKey", o, 128'h00112233445566778899aabbccddeeff);

        // Parte 2: encadeamento completo, nos dois sentidos
        cipher(128'h3243f6a8885a308d313198a2e0370734, 1'b0, o);
        check("Apendice B: cifragem completa", o, 128'h3925841d02dc09fbdc118597196a0b32);
        inv_cipher(128'h3925841d02dc09fbdc118597196a0b32, 1'b0, o);
        check("Apendice B: cifragem inversa completa", o, 128'h3243f6a8885a308d313198a2e0370734);

        cipher(128'h00112233445566778899aabbccddeeff, 1'b1, o);
        check("Apendice C.1: cifragem completa", o, 128'h69c4e0d86a7b0430d8cdb78070b4c55a);
        inv_cipher(128'h69c4e0d86a7b0430d8cdb78070b4c55a, 1'b1, o);
        check("Apendice C.1: cifragem inversa completa", o, 128'h00112233445566778899aabbccddeeff);

        if (errors != 0)
            $fatal(1, "FAIL: %0d de %0d verificacoes falharam", errors, checks);

        $display("PASS: MixColumns, InvMixColumns, AddRoundKey e cifra completa nos vetores da FIPS-197 (%0d verificacoes)", checks);
        $finish;
    end

endmodule
