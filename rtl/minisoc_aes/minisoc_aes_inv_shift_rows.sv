`timescale 1ns/1ps

// InvShiftRows: rotaciona a linha r do estado r posicoes para a direita.
//   s'[r][c] = s[r][(c - r) mod 4]
// Apenas reordenacao de fios (sem logica).
//
// Convencao do estado: byte n em [127-8n -: 8], com r = n mod 4, c = n div 4.

module minisoc_aes_inv_shift_rows (
    input  logic [127:0] i_state,
    output logic [127:0] o_state
);

    genvar r, c;
    generate
        for (c = 0; c < 4; c++) begin : g_col
            for (r = 0; r < 4; r++) begin : g_row
                assign o_state[127-8*(r+4*c) -: 8] = i_state[127-8*(r+4*((c+4-r)%4)) -: 8];
            end
        end
    endgenerate

endmodule
