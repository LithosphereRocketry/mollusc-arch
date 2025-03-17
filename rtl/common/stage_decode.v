module stage_decode(
        input rst,
        input clk,

        input [31:0] write_val,
        input [3:0] write_addr,

        output step_valid,

        input [31:0] pc,
        input [31:0] inc_pc,
        input [31:0] instr,
        input instr_valid,
        output instr_ready,

        input does_jump,

        output reg [3:0] alu_a_src,
        output reg [3:0] alu_b_src,
        output reg [3:0] mem_val_src,
        output reg [3:0] pred_val_src,

        output reg [31:0] alu_a,
        output reg [31:0] alu_b,
        output reg [31:0] mem_val,
        output reg [31:0] pred_val,

        output reg [3:0] dest,

        output reg [3:0] aluop,
        output reg is_cmp,
        output reg is_jump,
        output reg is_mem,
        output reg mem_write,
        output reg pred_invert,

        output reg decode_valid,
        input decode_ready
    );

    reg [31:0] regfile [0:15];
    initial regfile[0] <= 32'h00000000;

`ifdef SIM
    genvar g;
    for(g = 0; g < 16; g = g+1) wire[31:0] val = regfile[g];
`endif

    wire [3:0] ra_pred, ra_a, ra_b, ra_m, ra_d;
    wire [31:0] imm;
    wire [3:0] dec_aluop;
    wire pred_inv, use_imm, pc_relative, dec_cmp, dec_jump, dec_mem, dec_memwr;
    decode dec(
        .instr(instr),
        
        .ra_pred(ra_pred),
        .ra_a(ra_a),
        .ra_b(ra_b),
        .ra_m(ra_m),

        .imm(imm),

        .ra_d(ra_d),

        .pred_inv(pred_inv),
        .use_imm(use_imm),
        .pc_relative(pc_relative),
        .is_cmp(dec_cmp),
        .is_jump(dec_jump),
        .is_mem(dec_mem),
        .mem_write(dec_memwr),
        .aluop(dec_aluop)
    );

    wire [31:0] rv_pred = regfile[ra_pred];
    wire [31:0] rv_a = regfile[ra_a];
    wire [31:0] rv_b = regfile[ra_b];
    wire [31:0] rv_m = regfile[ra_m];

    wire [31:0] rv_a_fwd, rv_b_fwd, rv_m_fwd, rv_pred_fwd;

    forwarder #(32, 4) fwd [3:0] (
        .value({rv_a, rv_b, rv_m, rv_pred}),
        .src({ra_a, ra_b, ra_m, ra_pred}),

        .fwd_first_src(4'h0),
        .fwd_first_val(32'hxxxxxxxx),
        .fwd_first_used(),

        .fwd_second_src(write_addr),
        .fwd_second_val(write_val),
        .fwd_second_used(),

        .forwarded_value({rv_a_fwd, rv_b_fwd, rv_m_fwd, rv_pred_fwd})
    );

    reg first_cycle;
    task reset; begin
        decode_valid <= 0;
        first_cycle <= 1;
    end endtask

    // We are able to accept a new instruction if either we don't have one
    // or our current one is leaving
    assign instr_ready = ~decode_valid | decode_ready | does_jump;

    assign step_valid = instr_ready & instr_valid & ~does_jump & ~first_cycle;

    always @(posedge clk) if(rst) reset(); else begin
        first_cycle <= 0;
        if(write_addr != 4'h0) regfile[write_addr] <= write_val;

        if(step_valid) begin // if we just performed a jump, discard
            decode_valid <= 1; 

            alu_a_src <= pc_relative ? 4'h0 : ra_a;
            alu_a <= pc_relative ? pc : rv_a_fwd;

            alu_b_src <= use_imm ? 4'h0 : ra_b;
            alu_b <= use_imm ? imm : rv_b_fwd;

            mem_val_src <= dec_jump ? 4'h0 : ra_m;
            mem_val <= dec_jump ? inc_pc : rv_m_fwd;

            pred_val_src <= ra_pred;
            pred_val <= rv_pred_fwd;
            pred_invert <= pred_inv;

            aluop <= dec_aluop;
            is_cmp <= dec_cmp;
            is_jump <= dec_jump;
            is_mem <= dec_mem;
            mem_write <= dec_memwr;

            dest <= ra_d;

        end else if(decode_valid & decode_ready) begin
            decode_valid <= 1'b0;
            alu_a_src <= 'x;
            alu_a <= 'x;

            alu_b_src <= 'x;
            alu_b <= 'x;

            mem_val_src <= 'x;
            mem_val <= 'x;

            pred_val_src <= 'x;
            pred_val <= 'x;
            pred_invert <= 'x;

            aluop <= 'x;
            is_cmp <= 'x;
            is_jump <= 'x;
            is_mem <= 'x;
            mem_write <= 'x;

            dest <= 'x;
        end else begin
            if(alu_a_src != 4'h0 && alu_a_src == write_addr) alu_a <= write_val; 
            if(alu_b_src != 4'h0 && alu_b_src == write_addr) alu_b <= write_val;
            if(mem_val_src != 4'h0 && mem_val_src == write_addr) mem_val <= write_val;
            if(pred_val_src != 4'h0 && pred_val_src == write_addr) pred_val <= write_val;
        end
    end
endmodule