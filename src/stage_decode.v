module stage_decode(
        input clk,
        input [31:0] pc_in,
        input [31:0] instr,
        input instr_valid,
        output stall,

        input [3:0] write_addr,
        input [31:0] write_data,
        input forward_valid,
        input [3:0] forward_addr,
        input [31:0] forward_data,

        input stall_in,
        output reg [31:0] pc,

        output reg [31:0] reg_a,
        output reg [31:0] reg_b,
        output reg [31:0] reg_m,

        output reg [3:0] dest,
        output reg [3:0] aluop,
        output reg mem,
        output reg mem_write,

        output reg jump
    );

    wire [3:0] ra_pred;
    wire [31:0] rv_pred;
    wire [3:0] ra_a;
    wire [31:0] rv_a;
    wire [3:0] ra_b;
    wire [31:0] rv_b;
    wire [3:0] ra_mem;
    wire [31:0] rv_mem;
    wire fwd_used;
    register_file regfile(
        .clk(clk),

        .write_addr(write_addr),
        .write_data(write_data),

        .fwd_addr(forward_addr),
        .fwd_data(forward_data),

        .p_addr(ra_pred),
        .p_data(rv_pred),

        .a_addr(ra_a),
        .a_data(rv_a),

        .b_addr(ra_b),
        .b_data(rv_b),
        
        .m_addr(ra_mem),
        .m_data(rv_mem),

        .fwd_used(fwd_used)
    );

    assign stall = stall_in | ~instr_valid | (fwd_used & ~forward_valid);

    wire [26:0] instr_pred;
    wire pred_priv;
    predicate pred(
        .instr(instr),
        .reg_addr(ra_pred),
        .reg_value(rv_pred),
        .instr_out(instr_pred),
        .privileged(pred_priv)
    );

    wire [3:0] ra_dest;
    wire [20:0] upper_imm;
    wire [10:0] lower_imm;
    wire priv, upper_shiftmode, aui_mode, use_upper_imm, use_imm, is_jump;
    wire is_mem, is_mem_write;
    wire [3:0] dec_aluop;
    decode dec(
        .instr(instr_pred),
        .priv_in(pred_priv),

        .ra_a(ra_a),
        .ra_b(ra_b),
        .ra_m(ra_mem),
        .ra_d(ra_dest),

        .upper_imm(upper_imm),
        .lower_imm(lower_imm),
        .priv(priv),

        .upper_shiftmode(upper_shiftmode),
        .aui_mode(aui_mode),
        .use_upper_imm(use_upper_imm),
        .use_imm(use_imm),
        .is_mem(is_mem),
        .is_jump(is_jump),
        .mem_write(is_mem_write),
        .aluop(dec_aluop)
    );

    wire [31:0] longimm_base = aui_mode ? pc_in : 32'd0;
    wire [31:0] operand_a = use_upper_imm ? longimm_base : rv_a;

    // Sign-extended immediates
    wire [31:0] upper_ext = upper_shiftmode ? {upper_imm, 11'b0}
                                            : {{9{upper_imm[20]}}, upper_imm, 2'b0};
    wire [31:0] lower_ext = {{21{lower_imm[10]}}, lower_imm};
    
    wire [31:0] imm = use_upper_imm ? upper_ext : lower_ext;
    wire [31:0] operand_b = use_imm ? imm : rv_b;

    always @(posedge clk) begin
        if(~stall) begin
            pc <= pc_in;
            reg_a <= operand_a;
            reg_b <= operand_b;
            reg_m <= rv_mem;
            dest <= ra_dest;
            aluop <= dec_aluop;
            mem <= is_mem;
            mem_write <= is_mem_write;
            jump <= is_jump;
        end else begin
            // If stalled, emit a noop/bubble
            pc <= 32'hxxxxxxxx;
            reg_a <= 32'hxxxxxxxx;
            reg_b <= 32'hxxxxxxxx;
            reg_m <= 32'hxxxxxxxx;
            dest <= 4'h0;
            aluop <= 4'hx;
            mem <= 1'b0;
            mem_write <= 1'b0;
            jump <= 1'b0;
        end
    end
    
endmodule