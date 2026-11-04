`timescale 1ns/1ps

// MixColumns: cada coluna do estado e multiplicada, em GF(2^8), pela matriz
//   | 02 03 01 01 |
//   | 01 02 03 01 |
//   | 01 01 02 03 |
//   | 03 01 01 02 |
// (FIPS-197, secao 5.1.3). Puramente combinacional.
//
// Convencao do estado: byte n em [127-8n -: 8], com r = n mod 4, c = n div 4;
// a coluna c ocupa [127-32c -: 32], com s[0][c] no byte mais significativo.

module minisoc_aes_mix_columns (
    input  logic [127:0] i_state,
    output logic [127:0] o_state
);

    // Multiplicacao por 2 em GF(2^8), polinomio x^8 + x^4 + x^3 + x + 1
    function automatic logic [7:0] xtime(input logic [7:0] b);
        return {b[6:0], 1'b0} ^ (b[7] ? 8'h1b : 8'h00);
    endfunction

    function automatic logic [31:0] mix_column(input logic [31:0] col);
        logic [7:0] s0, s1, s2, s3;
        s0 = col[31:24];
        s1 = col[23:16];
        s2 = col[15:8];
        s3 = col[7:0];
        mix_column[31:24] = xtime(s0) ^ (xtime(s1) ^ s1) ^ s2 ^ s3;
        mix_column[23:16] = s0 ^ xtime(s1) ^ (xtime(s2) ^ s2) ^ s3;
        mix_column[15:8]  = s0 ^ s1 ^ xtime(s2) ^ (xtime(s3) ^ s3);
        mix_column[7:0]   = (xtime(s0) ^ s0) ^ s1 ^ s2 ^ xtime(s3);
    endfunction

    genvar c;
    generate
        for (c = 0; c < 4; c++) begin : g_col
            assign o_state[127-32*c -: 32] = mix_column(i_state[127-32*c -: 32]);
        end
    endgenerate

endmodule
