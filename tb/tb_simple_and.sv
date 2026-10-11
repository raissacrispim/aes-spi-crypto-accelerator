`timescale 1ns/1ps

module tb_simple_and;

    logic a;
    logic b;
    logic y;
    int   errors = 0;

    simple_and dut (
        .a(a),
        .b(b),
        .y(y)
    );

    task automatic check(input logic ta, input logic tb, input logic expected);
        a = ta; b = tb; #10;
        if (y !== expected) begin
            $error("Erro: %b & %b = %b (esperado %b)", ta, tb, y, expected);
            errors++;
        end
    endtask

    initial begin
        $display("=== Teste simple_and ===");

        check(0, 0, 0);
        check(0, 1, 0);
        check(1, 0, 0);
        check(1, 1, 1);

        if (errors != 0)
            $fatal(1, "%0d teste(s) falharam!", errors);

        $display("Todos os testes passaram!");
        $finish;
    end

endmodule
