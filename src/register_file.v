`timescale 1ns/1ps

module register_file(
        input clk,

        input [3:0] write_addr,
        input [31:0] write_data,

        // ALU A
        input [3:0] a_addr,
        output [31:0] a_data,

        // ALU B
        input [3:0] b_addr,
        output [31:0] b_data,

        // Mem write value
        input [3:0] m_addr,
        output [31:0] m_data,

        // Predicate value
        input [3:0] p_addr,
        output [31:0] p_data
    );

    wire [31:0] reg_outputs [15:0];
    reg [31:0] real_regs [15:1];

    genvar i;
    for(i = 1; i < 16; i = i + 1) assign reg_outputs[i] = real_regs[i];

    assign reg_outputs[0] = 32'h00000000;

    assign a_data = reg_outputs[a_addr];
    assign b_data = reg_outputs[b_addr];
    assign m_data = reg_outputs[m_addr];
    assign p_data = reg_outputs[p_addr];

    always @(posedge clk) if(write_addr != 4'b0) real_regs[write_addr] <= write_data;
endmodule