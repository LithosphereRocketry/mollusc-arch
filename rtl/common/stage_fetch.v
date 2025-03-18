`include "constants.vh"

module stage_fetch(
        input clk,
        input rst,

        input step_valid,

        input [31:0] jump_addr,
        input jump,
        output jump_ready,

        output [31:0] mem_addr,
        output mem_addr_valid,
        input mem_addr_ready,

        output reg [31:0] pc,
        output [31:0] inc_pc
    );

    assign inc_pc = pc + 4;

    reg jump_queued;
    reg [31:0] jump_queue;
    reg first_cycle;
    assign mem_addr = first_cycle ? `RESET_VECTOR
                    : jump_queued ? jump_queue
                    : jump ? jump_addr : inc_pc;
    assign jump_ready = ~jump_queued;

    task reset; begin
        first_cycle <= 1;
        jump_queued <= 0;
    end endtask
    initial reset();

    assign mem_addr_valid = first_cycle | jump | jump_queued | step_valid;

    always @(posedge clk) if(rst) reset(); else begin
        if(mem_addr_valid & mem_addr_ready) begin
            first_cycle <= 0;
            jump_queued <= 0;
            jump_queue <= 'x;
            pc <= mem_addr;
        end else if(jump & jump_ready) begin
            jump_queue <= jump_addr;
            jump_queued <= 1;
        end
    end
endmodule