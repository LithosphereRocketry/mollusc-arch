module stage_execute(
        input rst,
        input clk,

        input decode_valid,
        output decode_ready,

        input [3:0] alu_a_src,
        input [3:0] alu_b_src,
        input [3:0] mem_val_src,
        input [3:0] pred_val_src,

        input [31:0] alu_a,
        input [31:0] alu_b,
        input [31:0] mem_val_in,
        input [31:0] pred_val,

        input [3:0] dest_in,

        input [3:0] op,
        input is_cmp,
        input is_jump,
        input is_mem_in,
        input mem_write_in,
        input pred_inv,

        input [31:0] writeback_data,
        input [3:0] writeback_addr,

        output [31:0] jump_addr,
        output jump_valid,
        input jump_ready,

        output reg [3:0] dest,
        output reg [31:0] result,
        output reg [31:0] mem_val,

        output reg is_mem,
        output reg mem_write,

        output execute_valid,
        input execute_ready
    );

    wire [31:0] alu_a_fwd, alu_b_fwd, mem_val_fwd, pred_val_fwd;

    wire [3:0] fwd_used, fwd_second_used;
    forwarder #(32, 4) fwd [3:0] (
        .value({alu_a, alu_b, mem_val_in, pred_val}),
        .src({alu_a_src, alu_b_src, mem_val_src, pred_val_src}),

        .fwd_first_src(dest),
        .fwd_first_val(result),
        .fwd_first_used(fwd_used),

        .fwd_second_src(writeback_addr),
        .fwd_second_val(writeback_data),
        .fwd_second_used(fwd_second_used),

        .forwarded_value({alu_a_fwd, alu_b_fwd, mem_val_fwd, pred_val_fwd})
    );
    
    wire [31:0] alu_res;
    alu _alu(
        .op(op),
        .cmp(is_cmp),

        .alu_a(alu_a_fwd),
        .alu_b(alu_b_fwd),
        
        .result(alu_res)
    );

    reg was_mem;

    wire pred_taken = (pred_val_fwd == 0) ^ pred_inv;
    assign jump_addr = alu_res;
    assign jump_valid = decode_valid & decode_ready & is_jump & pred_taken;
    assign decode_ready = ~decode_valid | (execute_ready
            & (~is_jump | jump_ready) // jump isn't stalling
            & (~is_mem | ~|fwd_used)
            // & (~|fwd_second_used)
            ); // we aren't waiting on memory

    reg was_taken, has_instr;
    task reset; begin
        has_instr <= 0;
        was_taken <= 'x;
        dest <= 4'h0;
        result <= 'x;
        is_mem <= 'x;
        mem_write <= 'x;
        mem_val <= 'x;
    end endtask
    initial reset();


    assign execute_valid = has_instr & was_taken;

    always @(posedge clk) if(rst) reset; else begin
        if(decode_valid & decode_ready) begin
            has_instr <= 1;
            was_taken <= pred_taken;
            dest <= dest_in;
            result <= is_jump ? mem_val_in : alu_res;
            is_mem <= is_mem_in;
            mem_write <= mem_write_in;
            mem_val <= mem_val_fwd;
        end else if(has_instr & execute_ready) begin
            has_instr <= 0;
            was_taken <= 'x;
            dest <= 4'h0; // has to be 0 to not bait forwarding
            result <= 'x;
            is_mem <= 'x;
            mem_write <= 'x;
            mem_val <= 'x;
        end

    end

endmodule