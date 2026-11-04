`timescale 1ns/1ps

// AddRoundKey: XOR do estado com a chave da rodada (FIPS-197, secao 5.1.4).
// E a propria inversa, sendo usada tanto na cifragem quanto na decriptacao.
// Puramente combinacional.

module minisoc_aes_add_round_key (
    input  logic [127:0] i_state,
    input  logic [127:0] i_round_key,
    output logic [127:0] o_state
);

    assign o_state = i_state ^ i_round_key;

endmodule
