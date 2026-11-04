`timescale 1ns/1ps

// Testbench autoverificavel da S-box e da S-box inversa.
//
// A referencia NAO e uma copia da tabela do RTL: ela e calculada pela
// definicao da FIPS-197 (secao 5.1.1), isto e, inverso multiplicativo em
// GF(2^8) seguido da transformacao afim. Assim o teste e independente
// da tabela implementada.
//
// Verificacoes:
//   1. sbox(x)            == referencia(x)   para as 256 entradas
//   2. inv_sbox(sbox(x))  == x               para as 256 entradas
//   3. valores do escopo: sbox(8'h00) = 8'h63 e sbox(8'h53) = 8'hed

module minisoc_aes_sbox_tb;

    logic [7:0] x;
    logic [7:0] sbox_out;
    logic [7:0] inv_out;
    int         errors = 0;
    int         checks = 0;

    minisoc_aes_sbox     u_sbox     (.i_data(x),        .o_data(sbox_out));
    minisoc_aes_inv_sbox u_inv_sbox (.i_data(sbox_out), .o_data(inv_out));

    // Multiplicacao em GF(2^8) com o polinomio x^8 + x^4 + x^3 + x + 1
    function automatic logic [7:0] gf_mul(input logic [7:0] a, input logic [7:0] b);
        logic [7:0] p;
        p = 8'h00;
        for (int i = 0; i < 8; i++) begin
            if (b[0]) p = p ^ a;
            a = a[7] ? ((a << 1) ^ 8'h1b) : (a << 1);
            b = b >> 1;
        end
        return p;
    endfunction

    // Inverso multiplicativo em GF(2^8); por definicao, inv(0) = 0
    function automatic logic [7:0] gf_inv(input logic [7:0] a);
        if (a == 8'h00) return 8'h00;
        for (int i = 1; i < 256; i++)
            if (gf_mul(a, i[7:0]) == 8'h01) return i[7:0];
        return 8'h00;
    endfunction

    // S-box de referencia: inverso em GF(2^8) + transformacao afim
    function automatic logic [7:0] sbox_ref(input logic [7:0] a);
        logic [7:0] b;
        b = gf_inv(a);
        return b ^ {b[6:0], b[7]} ^ {b[5:0], b[7:6]} ^ {b[4:0], b[7:5]}
                 ^ {b[3:0], b[7:4]} ^ 8'h63;
    endfunction

    task automatic check(input string what, input logic [7:0] got, input logic [7:0] exp);
        checks++;
        if (got !== exp) begin
            $error("%s: entrada 8'h%02h -> obtido 8'h%02h, esperado 8'h%02h", what, x, got, exp);
            errors++;
        end
    endtask

    initial begin
        $display("=== minisoc_aes_sbox_tb ===");

        for (int i = 0; i < 256; i++) begin
            x = i[7:0];
            #1;
            check("sbox",          sbox_out, sbox_ref(x));
            check("inv_sbox(sbox)", inv_out, x);
        end

        x = 8'h00; #1; check("sbox(00)", sbox_out, 8'h63);
        x = 8'h53; #1; check("sbox(53)", sbox_out, 8'hed);

        if (errors != 0)
            $fatal(1, "FAIL: %0d de %0d verificacoes falharam", errors, checks);

        $display("PASS: S-box e S-box inversa nas 256 entradas (%0d verificacoes)", checks);
        $finish;
    end

endmodule
