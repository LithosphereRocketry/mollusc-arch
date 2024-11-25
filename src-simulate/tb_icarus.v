`timescale 1ns/1ps;

module tb_icarus();

    reg clk = 0, ioclk = 0, rst = 1;
    core dut(.clk(clk), .ioclk(ioclk), .rst(rst));

    always #(25) clk <= ~clk; // 40MHz
    always #(21) ioclk <= ~ioclk; //48MHz

    initial begin
        $dumpfile("waveforms/icarus.vcd");
        $dumpvars;
        #100;
        rst = 0;
        #250000;
        $finish;
    end
endmodule