`timescale 1ns/1ps

// Testbench autoverificavel de SubBytes, ShiftRows e das inversas.
//
// Vetores: FIPS-197.
//   Apendice B   (cifragem):          start of round -> after SubBytes -> after ShiftRows
//   Apendice C.1 (cifragem inversa):  istart -> after InvShiftRows -> after InvSubBytes
//
// Para cada rodada da cifragem verifica:
//   SubBytes(start)        == sub
//   ShiftRows(sub)         == shift
//   InvShiftRows(shift)    == sub      (inversa)
//   InvSubBytes(sub)       == start    (inversa)
// Para cada rodada da cifragem inversa verifica:
//   InvShiftRows(istart)   == ishift
//   InvSubBytes(ishift)    == isub

module minisoc_aes_sub_shift_tb;

    logic [127:0] sb_in,  sb_out;
    logic [127:0] sr_in,  sr_out;
    logic [127:0] isr_in, isr_out;
    logic [127:0] isb_in, isb_out;
    int           errors = 0;
    int           checks = 0;

    minisoc_aes_sub_bytes      u_sb  (.i_state(sb_in),  .o_state(sb_out));
    minisoc_aes_shift_rows     u_sr  (.i_state(sr_in),  .o_state(sr_out));
    minisoc_aes_inv_shift_rows u_isr (.i_state(isr_in), .o_state(isr_out));
    minisoc_aes_inv_sub_bytes  u_isb (.i_state(isb_in), .o_state(isb_out));

    task automatic check(input string what, input logic [127:0] got, input logic [127:0] exp);
        checks++;
        if (got !== exp) begin
            $error("%s\n    obtido   : %032h\n    esperado : %032h", what, got, exp);
            errors++;
        end
    endtask

    // Rodada da cifragem (Apendice B)
    task automatic cipher_round(input int r, input logic [127:0] start,
                                input logic [127:0] sub, input logic [127:0] shift);
        sb_in  = start;
        sr_in  = sub;
        isr_in = shift;
        isb_in = sub;
        #1;
        check($sformatf("B rodada %0d: SubBytes",     r), sb_out,  sub);
        check($sformatf("B rodada %0d: ShiftRows",    r), sr_out,  shift);
        check($sformatf("B rodada %0d: InvShiftRows", r), isr_out, sub);
        check($sformatf("B rodada %0d: InvSubBytes",  r), isb_out, start);
    endtask

    // Rodada da cifragem inversa (Apendice C.1)
    task automatic inv_cipher_round(input int r, input logic [127:0] istart,
                                    input logic [127:0] ishift, input logic [127:0] isub);
        isr_in = istart;
        isb_in = ishift;
        #1;
        check($sformatf("C.1 rodada %0d: InvShiftRows", r), isr_out, ishift);
        check($sformatf("C.1 rodada %0d: InvSubBytes",  r), isb_out, isub);
    endtask

    initial begin
        $display("=== minisoc_aes_sub_shift_tb ===");

        // FIPS-197 Apendice B: start of round, after SubBytes, after ShiftRows
        cipher_round(1,  128'h193de3bea0f4e22b9ac68d2ae9f84808,
                         128'hd42711aee0bf98f1b8b45de51e415230,
                         128'hd4bf5d30e0b452aeb84111f11e2798e5);
        cipher_round(2,  128'ha49c7ff2689f352b6b5bea43026a5049,
                         128'h49ded28945db96f17f39871a7702533b,
                         128'h49db873b453953897f02d2f177de961a);
        cipher_round(9,  128'hea835cf00445332d655d98ad8596b0c5,
                         128'h87ec4a8cf26ec3d84d4c46959790e7a6,
                         128'h876e46a6f24ce78c4d904ad897ecc395);
        cipher_round(10, 128'heb40f21e592e38848ba113e71bc342d2,
                         128'he9098972cb31075f3d327d94af2e2cb5,
                         128'he9317db5cb322c723d2e895faf090794);

        // FIPS-197 Apendice C.1: istart, is_row (InvShiftRows), is_box (InvSubBytes)
        inv_cipher_round(1,  128'h7ad5fda789ef4e272bca100b3d9ff59f,
                             128'h7a9f102789d5f50b2beffd9f3dca4ea7,
                             128'hbd6e7c3df2b5779e0b61216e8b10b689);
        inv_cipher_round(10, 128'h6353e08c0960e104cd70b751bacad0e7,
                             128'h63cab7040953d051cd60e0e7ba70e18c,
                             128'h00102030405060708090a0b0c0d0e0f0);

        if (errors != 0)
            $fatal(1, "FAIL: %0d de %0d verificacoes falharam", errors, checks);

        $display("PASS: SubBytes, ShiftRows e inversas nos vetores da FIPS-197 (%0d verificacoes)", checks);
        $finish;
    end

endmodule
