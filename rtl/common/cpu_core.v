module cpu_core(
        input clk,
        input rst,

        output [31:0] i_addr,
        output i_addr_valid,
        input i_addr_ready,

        input [31:0] i_data,
        input i_data_valid,
        output i_data_ready,

        output [31:0] d_addr,
        output [31:0] d_dout,
        output d_wr,
        output d_addr_valid,
        input d_addr_ready,

        input [31:0] d_din,
        input d_data_valid,
        output d_data_ready
    );

    wire [31:0] jump_addr, pc, inc_pc;
    wire jump, jump_ready, step_valid;
    stage_fetch fetch(
        .clk(clk),
        .rst(rst),

        .step_valid(step_valid),

        .jump_addr(jump_addr),
        .jump(jump),
        .jump_ready(jump_ready),

        .mem_addr(i_addr),
        .mem_addr_valid(i_addr_valid),
        .mem_addr_ready(i_addr_ready),

        .pc(pc),
        .inc_pc(inc_pc)
    );

    wire decode_valid;
    wire decode_ready;
    wire [3:0] decode_alu_a_src, decode_alu_b_src, decode_m_src, decode_p_src;
    wire [3:0] decode_dest;
    wire [31:0] decode_alu_a, decode_alu_b, decode_m, decode_p;
    wire decode_pred_inv, decode_is_cmp, decode_is_jump, decode_is_mem, decode_mem_write;
    wire [3:0] decode_aluop;

    wire [3:0] write_dest;
    wire [31:0] write_val;

    stage_decode decode(
        .rst(rst),
        .clk(clk),

        .write_addr(write_dest),
        .write_val(write_val),

        .step_valid(step_valid),

        .pc(pc),
        .inc_pc(inc_pc),
        .instr(i_data),
        .instr_valid(i_data_valid),
        .instr_ready(i_data_ready),
        .does_jump(jump),

        .alu_a_src(decode_alu_a_src),
        .alu_b_src(decode_alu_b_src),
        .mem_val_src(decode_m_src),
        .pred_val_src(decode_p_src),

        .alu_a(decode_alu_a),
        .alu_b(decode_alu_b),
        .mem_val(decode_m),
        .pred_val(decode_p),

        .aluop(decode_aluop),
        .is_cmp(decode_is_cmp),
        .is_jump(decode_is_jump),
        .is_mem(decode_is_mem),
        .mem_write(decode_mem_write),
        .pred_invert(decode_pred_inv),

        .dest(decode_dest),

        .decode_valid(decode_valid),
        .decode_ready(decode_ready)
    );

    wire execute_valid;
    wire execute_ready;
    wire [3:0] execute_dest;
    wire [31:0] execute_result, execute_mem_val;
    wire execute_is_mem, execute_mem_write;
    stage_execute execute(
        .rst(rst),
        .clk(clk),

        .decode_valid(decode_valid),
        .decode_ready(decode_ready),

        .alu_a_src(decode_alu_a_src),
        .alu_b_src(decode_alu_b_src),
        .mem_val_src(decode_m_src),
        .pred_val_src(decode_p_src),

        .alu_a(decode_alu_a),
        .alu_b(decode_alu_b),
        .mem_val_in(decode_m),
        .pred_val(decode_p),

        .dest_in(decode_dest),

        .op(decode_aluop),
        .is_cmp(decode_is_cmp),
        .is_jump(decode_is_jump),
        .is_mem_in(decode_is_mem),
        .mem_write_in(decode_mem_write),
        .pred_inv(decode_pred_inv),

        .writeback_data(write_val),
        .writeback_addr(write_dest),

        .jump_addr(jump_addr),
        .jump_valid(jump),
        .jump_ready(jump_ready),

        .dest(execute_dest),
        .result(execute_result),
        .mem_val(execute_mem_val),

        .is_mem(execute_is_mem),
        .mem_write(execute_mem_write),

        .execute_valid(execute_valid),
        .execute_ready(execute_ready)
    );

    stage_memory memory(
        .rst(rst),
        .clk(clk),

        .execute_valid(execute_valid),
        .execute_ready(execute_ready),

        .result_in(execute_result),
        .mdata_in(execute_mem_val),
        .is_mem(execute_is_mem),
        .mem_write(execute_mem_write),
        .dest_in(execute_dest),

        .m_addr(d_addr),
        .m_dout(d_dout),
        .m_wr(d_wr),
        .m_addr_valid(d_addr_valid),
        .m_addr_ready(d_addr_ready),

        .m_din(d_din),
        .m_data_valid(d_data_valid),
        .m_data_ready(d_data_ready),

        .dest(write_dest),
        .result(write_val)
    );

endmodule