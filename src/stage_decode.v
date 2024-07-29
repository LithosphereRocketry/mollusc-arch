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
    register_file regfile(

        .p_addr(ra_pred),
        .p_data(rv_pred)
    );

    wire [27:0] instr_pred;
    wire pred_priv;
    predicate pred(
        .instr(instr),
        .reg_addr(ra_pred),
        .reg_value(rv_pred),
        .instr_out(instr_pred)
    );

    wire [21:0] upper_imm;
    wire [9:0] lower_imm;
    wire priv;
    decode dec(
        .instr(instr_pred),
        .priv_in(pred_priv),

        .ra_a(ra_a),
        .ra_b(ra_b),
        .ra_m(ra_mem),
        .ra_d(ra_dest),

        .upper_imm(upper_imm),
        .lower_imm(lower_imm),
        .priv(priv)
    );

    
    
endmodule