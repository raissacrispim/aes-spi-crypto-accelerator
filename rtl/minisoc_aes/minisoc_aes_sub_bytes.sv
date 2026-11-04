`timescale 1ns/1ps

// SubBytes: aplica a S-box a cada um dos 16 bytes do estado.
//
// Convencao do estado (Block Guide / FIPS-197 secao 3.4):
//   byte n ocupa [127-8n -: 8] (byte 0 em [127:120], byte 15 em [7:0])
//   e corresponde a s[r][c], com r = n mod 4 e c = n div 4.

module minisoc_aes_sub_bytes (
    input  logic [127:0] i_state,
    output logic [127:0] o_state
);

    genvar n;
    generate
        for (n = 0; n < 16; n++) begin : g_sbox
            minisoc_aes_sbox u_sbox (
                .i_data (i_state[127-8*n -: 8]),
                .o_data (o_state[127-8*n -: 8])
            );
        end
    endgenerate

endmodule
