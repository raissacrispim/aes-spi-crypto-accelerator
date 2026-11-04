`timescale 1ns/1ps

// InvMixColumns: cada coluna do estado e multiplicada, em GF(2^8), pela matriz
//   | 0e 0b 0d 09 |
//   | 09 0e 0b 0d |
//   | 0d 09 0e 0b |
//   | 0b 0d 09 0e |
// (FIPS-197, secao 5.3.3). Puramente combinacional.
//
// Convencao do estado: byte n em [127-8n -: 8], com r = n mod 4, c = n div 4;
// a coluna c ocupa [127-32c -: 32], com s[0][c] no byte mais significativo.

module minisoc_aes_inv_mix_columns (
    input  logic [127:0] i_state,
    output logic [127:0] o_state
);

    // Multiplicacao por 2 em GF(2^8), polinomio x^8 + x^4 + x^3 + x + 1
    function automatic logic [7:0] xtime(input logic [7:0] b);
        return {b[6:0], 1'b0} ^ (b[7] ? 8'h1b : 8'h00);
    endfunction

    // Multiplicacoes por 09, 0b, 0d e 0e, decompostas em potencias de 2
    function automatic logic [7:0] mul09(input logic [7:0] b);
        return xtime(xtime(xtime(b))) ^ b;
    endfunction

    function automatic logic [7:0] mul0b(input logic [7:0] b);
        return xtime(xtime(xtime(b))) ^ xtime(b) ^ b;
    endfunction

    function automatic logic [7:0] mul0d(input logic [7:0] b);
        return xtime(xtime(xtime(b))) ^ xtime(xtime(b)) ^ b;
    endfunction

    function automatic logic [7:0] mul0e(input logic [7:0] b);
        return xtime(xtime(xtime(b))) ^ xtime(xtime(b)) ^ xtime(b);
    endfunction

    function automatic logic [31:0] inv_mix_column(input logic [31:0] col);
        logic [7:0] s0, s1, s2, s3;
        s0 = col[31:24];
        s1 = col[23:16];
        s2 = col[15:8];
        s3 = col[7:0];
        inv_mix_column[31:24] = mul0e(s0) ^ mul0b(s1) ^ mul0d(s2) ^ mul09(s3);
        inv_mix_column[23:16] = mul09(s0) ^ mul0e(s1) ^ mul0b(s2) ^ mul0d(s3);
        inv_mix_column[15:8]  = mul0d(s0) ^ mul09(s1) ^ mul0e(s2) ^ mul0b(s3);
        inv_mix_column[7:0]   = mul0b(s0) ^ mul0d(s1) ^ mul09(s2) ^ mul0e(s3);
    endfunction

    genvar c;
    generate
        for (c = 0; c < 4; c++) begin : g_col
            assign o_state[127-32*c -: 32] = inv_mix_column(i_state[127-32*c -: 32]);
        end
    endgenerate

endmodule
