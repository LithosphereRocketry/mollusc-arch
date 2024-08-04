module stage_decode(
        input [31:0] pc,
        input [31:0] instr
    );

    wire [3:0] ra_pred;
    wire [3:0] ra_a;
    wire [3:0] ra_b;
    wire [3:0] ra_mem;
    wire [3:0] ra_dest;
    wire [31:0] rv_pred;
    wire [31:0] rv_a;
    wire [31:0] rv_b;
    wire [31:0] rv_mem;
    wire [31:0] rv_dest;
    register_file regfile(

        .p_addr(ra_pred),
        .p_data(rv_pred),

        .a_addr(ra_a),
        .a_data(rv_a),

        .b_addr(ra_b),
        .b_data(rv_b),
        
        .m_addr(ra_mem),
        .m_data(rv_dest)
    );

    wire [27:0] instr_pred;
    wire pred_priv;
    predicate pred(
        .instr(instr),
        .reg_addr(ra_pred),
        .reg_value(rv_pred),
        .instr_out(instr_pred)
    );

    wire [20:0] upper_imm;
    wire [10:0] lower_imm;
    wire priv, upper_shiftmode, aui_mode, use_upper_imm, use_imm, is_mem;
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
        .is_mem(is_mem)
    );

    // Sign-extended immediates
    wire [31:0] upper_ext = upper_shiftmode ? {upper_imm, 11'b0}
                                            : {{9{upper_imm[20]}}, upper_imm, 2'b0};
    wire [31:0] lower_ext = {{21{lower_imm[10]}}, lower_imm};
    
    wire [31:0] imm = use_upper_imm ? upper_ext : lower_ext;
    wire [31:0] operand_b = use_imm ? imm : rv_b;

    // Memory operations share an adder with relative jumps rather than
    // arithmetic in this design, which is a little unusual but shouldn't change
    // much in the bigger picture
    wire [31:0] memop_addr = rv_a + operand_b;
    
endmodule