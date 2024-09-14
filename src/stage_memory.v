module stage_memory(
        input [3:0] dest_in,
        input [31:0] value_in,

        input mem_valid,
        input [31:0] mem_in,
        input is_mem,

        output stall,

        output [3:0] writeback_addr,
        output [31:0] writeback_value
    );

    assign stall = is_mem & ~mem_valid;

    assign writeback_addr = stall ? 4'h0 : dest_in;
    assign writeback_value = is_mem ? mem_in : value_in;

endmodule