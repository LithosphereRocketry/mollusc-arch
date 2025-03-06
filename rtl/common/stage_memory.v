module stage_memory(
        input clk,
        input rst,

        input execute_valid,
        output execute_ready,

        input [31:0] result_in,
        input [31:0] mdata_in,
        input is_mem,
        input mem_write,
        input [3:0] dest_in,

        output [31:0] m_addr,
        output [31:0] m_dout,
        output m_wr,
        output m_addr_valid,
        input m_addr_ready,

        input [31:0] m_din,
        input m_data_valid,
        output m_data_ready,

        output [3:0] dest,
        output [31:0] result
    );

    // For now, we're the last on the line, so we don't ever stall
    assign m_data_ready = 1;

    reg was_mem;

    assign m_addr = result_in;
    assign m_dout = mdata_in;
    assign m_wr = mem_write;
    assign m_addr_valid = execute_valid & is_mem;
    
    reg [3:0] dest_sync;
    reg [31:0] exe_res_sync;
    reg has_instr;
    task reset; begin
        has_instr <= 0;
        was_mem <= 'x;
        dest_sync <= 'x;
        exe_res_sync <= 'x;
    end endtask
    initial reset();

    wire memory_valid = has_instr & (~was_mem | m_data_valid);

    assign dest = memory_valid ? dest_sync : 4'h0;

    assign result = was_mem ? m_din : exe_res_sync;

    assign execute_ready = m_addr_ready;

    always @(posedge clk) if(rst) reset(); else begin
        if(execute_valid & execute_ready) begin
            has_instr <= 1;
            was_mem <= is_mem;
            dest_sync <= dest_in;
            exe_res_sync <= result_in;
        end else if(memory_valid) begin
            has_instr <= 0;
            was_mem <= 'x;
            dest_sync <= 'x;
            exe_res_sync <= 'x;
        end
    end

endmodule