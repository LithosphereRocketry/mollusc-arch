`timescale 1ns/1ps

module reg_forwarder(
        input [31:0] non_forward,
        input [3:0] read_addr,

        input [31:0] mem_fwd_data,
        input [3:0] mem_fwd_addr,

        input [31:0] exe_fwd_data,
        input [3:0] exe_fwd_addr,

        output [31:0] value
    );

    assign value = (exe_fwd_addr != 4'b0) & (exe_fwd_addr == read_addr)
                        ? exe_fwd_data
                 : (mem_fwd_addr != 4'b0) & (mem_fwd_addr == read_addr)
                        ? mem_fwd_data
                        : non_forward; 
endmodule

module register_file(
        input clk,

        // Writeback data
        input [3:0] write_addr,
        input [31:0] write_data,

        // Forwarded data
        input [3:0] fwd_addr,
        input [31:0] fwd_data,

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

    reg_forwarder fwd [3:0] (
        .non_forward({
            reg_outputs[a_addr],
            reg_outputs[b_addr],
            reg_outputs[m_addr],
            reg_outputs[p_addr]
        }),
        .read_addr({a_addr, b_addr, m_addr, p_addr}),
        
        .mem_fwd_addr(write_addr),
        .mem_fwd_data(write_data),

        .exe_fwd_addr(fwd_addr),
        .exe_fwd_data(fwd_data),

        .value({a_data, b_data, m_data, p_data})
    );

    always @(posedge clk) if(write_addr != 4'b0) real_regs[write_addr] <= write_data;
endmodule