`timescale 1ns/1ps

// Expansao de chave AES-128 (FIPS-197, secao 5.2), pre-computada.
//
// Microarquitetura (docs/architecture/microarquitetura_v1.0.md, secao 3.2):
//   - No i_start, a chave e copiada para rk_q[0] (ciclo de carga) e as round
//     keys 1..10 sao calculadas de forma iterativa, uma por ciclo; o_done sobe
//     11 ciclos apos o i_start.
//   - As 11 round keys ficam armazenadas (11 x 128 bits) e sao lidas pelo
//     datapath pelo indice i_rk_idx (leitura combinacional).
//   - o_ready indica que o banco contem as round keys da ultima chave
//     carregada; o_done e um pulso de um ciclo ao final da expansao.
//
// Round key r (r = 1..10), com palavras w0..w3 da round key r-1:
//   t  = SubWord(RotWord(w3)) ^ {rcon_r, 24'h0}
//   w0' = w0 ^ t;  w1' = w1 ^ w0';  w2' = w2 ^ w1';  w3' = w3 ^ w2'
// rcon_1 = 8'h01 e rcon_{r+1} = xtime(rcon_r).

module minisoc_aes_key_exp (
    input  logic         clk,
    input  logic         rst_n,

    input  logic         i_start,     // pulso: inicia a expansao de i_key
    input  logic [127:0] i_key,
    output logic         o_busy,
    output logic         o_ready,     // round keys validas
    output logic         o_done,      // pulso ao fim da expansao

    input  logic [3:0]   i_rk_idx,    // 0..10
    output logic [127:0] o_rk
);

    logic [127:0] rk_q [0:10];
    logic [127:0] cur_q;              // ultima round key calculada
    logic [3:0]   round_q;            // proxima round key a calcular (1..10)
    logic [7:0]   rcon_q;
    logic         busy_q;
    logic         ready_q;
    logic         done_q;

    // ---------------- Proxima round key (combinacional) ----------------

    logic [31:0]  w0, w1, w2, w3;
    logic [31:0]  rot_w3;
    logic [31:0]  sub_w3;
    logic [31:0]  t;
    logic [127:0] next_rk;

    assign w0     = cur_q[127:96];
    assign w1     = cur_q[95:64];
    assign w2     = cur_q[63:32];
    assign w3     = cur_q[31:0];
    assign rot_w3 = {w3[23:0], w3[31:24]};

    genvar b;
    generate
        for (b = 0; b < 4; b++) begin : g_subword
            minisoc_aes_sbox u_sbox (
                .i_data (rot_w3[31-8*b -: 8]),
                .o_data (sub_w3[31-8*b -: 8])
            );
        end
    endgenerate

    assign t = sub_w3 ^ {rcon_q, 24'h000000};

    assign next_rk[127:96] = w0 ^ t;
    assign next_rk[95:64]  = w1 ^ next_rk[127:96];
    assign next_rk[63:32]  = w2 ^ next_rk[95:64];
    assign next_rk[31:0]   = w3 ^ next_rk[63:32];

    // Multiplicacao por 2 em GF(2^8), para a sequencia de rcon
    function automatic logic [7:0] xtime(input logic [7:0] v);
        return {v[6:0], 1'b0} ^ (v[7] ? 8'h1b : 8'h00);
    endfunction

    // ---------------- Controle e armazenamento ----------------

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i <= 10; i++) rk_q[i] <= '0;
            cur_q   <= '0;
            round_q <= 4'd0;
            rcon_q  <= 8'h00;
            busy_q  <= 1'b0;
            ready_q <= 1'b0;
            done_q  <= 1'b0;
        end else begin
            done_q <= 1'b0;

            if (i_start && !busy_q) begin
                rk_q[0] <= i_key;
                cur_q   <= i_key;
                round_q <= 4'd1;
                rcon_q  <= 8'h01;
                busy_q  <= 1'b1;
                ready_q <= 1'b0;
            end else if (busy_q) begin
                rk_q[round_q] <= next_rk;
                cur_q         <= next_rk;
                rcon_q        <= xtime(rcon_q);
                if (round_q == 4'd10) begin
                    busy_q  <= 1'b0;
                    ready_q <= 1'b1;
                    done_q  <= 1'b1;
                end else begin
                    round_q <= round_q + 4'd1;
                end
            end
        end
    end

    assign o_busy  = busy_q;
    assign o_ready = ready_q;
    assign o_done  = done_q;

    // Leitura das round keys; indices fora de 0..10 retornam zero
    assign o_rk = (i_rk_idx <= 4'd10) ? rk_q[i_rk_idx] : '0;

endmodule
