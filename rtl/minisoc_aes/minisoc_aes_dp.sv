`timescale 1ns/1ps

// Datapath AES-128 iterativo: uma rodada por ciclo, cifra e cifra inversa.
//
// Microarquitetura (docs/architecture/microarquitetura_v1.0.md, secao 3.1):
//   - registrador de estado de 128 bits e logica de rodada reutilizada;
//   - ciclo de carga: state = i_block ^ rk0 (cifra) ou i_block ^ rk10 (decifra);
//   - rodadas 1..10, uma por ciclo:
//       cifra   : SubBytes -> ShiftRows -> MixColumns (exceto rodada 10) -> AddRoundKey(rk[r])
//       decifra : InvShiftRows -> InvSubBytes -> AddRoundKey(rk[10-r]) -> InvMixColumns (exceto rodada 10)
//     (FIPS-197, secoes 5.1 e 5.3);
//   - latencia: o_done sobe 11 ciclos apos o i_start; o_block fica estavel
//     ate o proximo i_start.
//
// As round keys sao lidas do minisoc_aes_key_exp pelo indice o_rk_idx; elas
// devem estar prontas (o_ready do key_exp) antes do i_start.

module minisoc_aes_dp (
    input  logic         clk,
    input  logic         rst_n,

    input  logic         i_start,     // pulso: processa i_block (ignorado se busy)
    input  logic         i_decrypt,   // 0 = cifra, 1 = cifra inversa
    input  logic [127:0] i_block,
    output logic         o_busy,
    output logic         o_done,      // pulso de um ciclo ao fim do bloco
    output logic [127:0] o_block,

    output logic [3:0]   o_rk_idx,    // round key pedida ao key_exp
    input  logic [127:0] i_rk
);

    logic [127:0] state_q;
    logic [3:0]   round_q;            // rodada em execucao (1..10)
    logic         decrypt_q;
    logic         busy_q;
    logic         done_q;

    logic         last_round;

    assign last_round = (round_q == 4'd10);

    // Indice da round key:
    //   carga   -> rk0 (cifra) ou rk10 (decifra)
    //   rodada r -> rk[r] (cifra) ou rk[10-r] (decifra)
    always_comb begin
        if (!busy_q)
            o_rk_idx = i_decrypt ? 4'd10 : 4'd0;
        else if (decrypt_q)
            o_rk_idx = 4'd10 - round_q;
        else
            o_rk_idx = round_q;
    end

    // ---------------- Caminho de cifra ----------------

    logic [127:0] sb_out, sr_out, mc_out, enc_pre;

    minisoc_aes_sub_bytes   u_sb (.i_state(state_q), .o_state(sb_out));
    minisoc_aes_shift_rows  u_sr (.i_state(sb_out),  .o_state(sr_out));
    minisoc_aes_mix_columns u_mc (.i_state(sr_out),  .o_state(mc_out));

    assign enc_pre = last_round ? sr_out : mc_out;

    // ---------------- Caminho de cifra inversa ----------------

    logic [127:0] isr_out, isb_out;

    minisoc_aes_inv_shift_rows u_isr (.i_state(state_q), .o_state(isr_out));
    minisoc_aes_inv_sub_bytes  u_isb (.i_state(isr_out), .o_state(isb_out));

    // ---------------- AddRoundKey compartilhado ----------------

    logic [127:0] ark_in, ark_out, imc_out, next_state;

    always_comb begin
        if (!busy_q)
            ark_in = i_block;         // ciclo de carga
        else if (decrypt_q)
            ark_in = isb_out;
        else
            ark_in = enc_pre;
    end

    minisoc_aes_add_round_key   u_ark (.i_state(ark_in), .i_round_key(i_rk), .o_state(ark_out));
    minisoc_aes_inv_mix_columns u_imc (.i_state(ark_out), .o_state(imc_out));

    // Na decifra, InvMixColumns depois do AddRoundKey, exceto na ultima rodada
    assign next_state = (busy_q && decrypt_q && !last_round) ? imc_out : ark_out;

    // ---------------- Controle ----------------

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q   <= '0;
            round_q   <= 4'd0;
            decrypt_q <= 1'b0;
            busy_q    <= 1'b0;
            done_q    <= 1'b0;
        end else begin
            done_q <= 1'b0;

            if (!busy_q) begin
                if (i_start) begin
                    state_q   <= next_state;    // i_block ^ rk0 / rk10
                    decrypt_q <= i_decrypt;
                    round_q   <= 4'd1;
                    busy_q    <= 1'b1;
                end
            end else begin
                state_q <= next_state;
                if (last_round) begin
                    busy_q <= 1'b0;
                    done_q <= 1'b1;
                end else begin
                    round_q <= round_q + 4'd1;
                end
            end
        end
    end

    assign o_busy  = busy_q;
    assign o_done  = done_q;
    assign o_block = state_q;

endmodule
