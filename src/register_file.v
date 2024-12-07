`timescale 1ns/1ps

module reg_forwarder(
        input [31:0] non_forward,
        input [3:0] read_addr,

        input [31:0] mem_fwd_data,
        input [3:0] mem_fwd_addr,

        input [31:0] exe_fwd_data,
        input [3:0] exe_fwd_addr,

        output [31:0] value,
        output forward_used
    );

    assign forward_used = (exe_fwd_addr != 4'b0) & (exe_fwd_addr == read_addr);

    assign value = forward_used ? exe_fwd_data
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
        output [31:0] p_data,

        output fwd_used
    );

    reg [31:0] regs [15:0];
    initial regs[0] = 32'd0;

    wire [3:0] fwd_used_arr;

    reg_forwarder fwd [3:0] (
        .non_forward({
            regs[a_addr],
            regs[b_addr],
            regs[m_addr],
            regs[p_addr]
        }),
        .read_addr({a_addr, b_addr, m_addr, p_addr}),
        
        .mem_fwd_addr(write_addr),
        .mem_fwd_data(write_data),

        .exe_fwd_addr(fwd_addr),
        .exe_fwd_data(fwd_data),

        .value({a_data, b_data, m_data, p_data}),
        .forward_used(fwd_used_arr)
    );

    assign fwd_used = |fwd_used_arr;

    always @(posedge clk) if(write_addr != 4'b0) regs[write_addr] <= write_data;
endmodule