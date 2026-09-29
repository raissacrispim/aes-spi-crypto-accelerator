`timescale 1ns/1ps

module tb_simple_and;

    logic a;
    logic b;
    logic y;

    simple_and dut (
        .a(a),
        .b(b),
        .y(y)
    );

    initial begin
        $display("=== Teste simple_and ===");

        a = 0; b = 0; #10;
        if (y !== 0) $error("Erro: 0 & 0");

        a = 0; b = 1; #10;
        if (y !== 0) $error("Erro: 0 & 1");

        a = 1; b = 0; #10;
        if (y !== 0) $error("Erro: 1 & 0");

        a = 1; b = 1; #10;
        if (y !== 1) $error("Erro: 1 & 1");

        $display("Todos os testes passaram!");
        $finish;
    end

endmodule
