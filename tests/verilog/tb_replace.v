`timescale 1ns/1ps
`include "assert.vh"

module tb_replace();
    reg [15:0] din;
    reg [1:0] addr;
    reg [3:0] insert;
    wire [15:0] dout;

    replace #(16, 4) dut(
        .din(din),
        .addr(addr),
        .insert(insert),
        .dout(dout)
    );

    initial begin
        din = 16'hxxxx;
        addr = 2;
        insert = 3;
        #1;
        `assert(dout, 16'hx3xx);
    end

endmodule    