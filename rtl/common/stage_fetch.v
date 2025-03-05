`include "constants.vh"

module stage_fetch(
        input clk,
        input rst,

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

    assign mem_addr = first_cycle ? `RESET_VECTOR
                    : jump ? jump_addr : inc_pc;
    assign jump_ready = mem_addr_ready;

    reg first_cycle;    
    task reset; begin
        first_cycle <= 1;
    end endtask
    initial reset();

    // TOOD is this right?
    assign mem_addr_valid = 1;

    always @(posedge clk) if(rst) reset(); else begin
        if(mem_addr_valid & mem_addr_ready) begin
            first_cycle <= 0;
            pc <= mem_addr;
        end
    end
endmodule