module decode(
        input [26:0] instr,
        input priv_in,

        output [3:0] ra_a,
        output [3:0] ra_b,
        output [3:0] ra_m,
        output [3:0] ra_d,

        output [20:0] upper_imm,
        output [10:0] lower_imm,

        output priv,

        // 0: shift by 2, 1: shift by 10
        output upper_shiftmode,
        // 0: add to 0, 1: add to PC
        output aui_mode,

        output use_imm,
        output is_mem
    );

    assign upper_imm = instr[20:0];
    assign lower_imm = instr[10:0];

    assign upper_shiftmode = instr[23];
    assign aui_mode = instr[22];

    wire jump_longimm = instr[22];
    wire absolute_pc = instr[21];
    wire l_format = jump_longimm | absolute_pc;

    wire n_arith = instr[20];
    wire m_format = instr[20] & instr[19];

    wire [3:0] funccode = m_format ? instr[26:23] : instr[18:15];

    assign use_imm = l_format | funccode[3];
    assign is_mem = !l_format & instr[20] & funccode[2];

    assign ra_d = m_format ? 4'b0 : instr[26:23];
    assign ra_m = m_format ? instr[18:15] : 4'b0;
    assign ra_a = l_format ? 4'b0 : instr[14:11];
    assign ra_b = use_imm ? 4'b0 : instr[10:7];

    wire rp_d, rp_m, rp_a, rp_b;
    privileged prv [3:0] (
        .reg_addr({rp_d, rp_m, rp_a, rp_b}),
        .priv({rp_d, rp_m, rp_a, rp_b})
    );
    assign priv = rp_a & rp_b & rp_d & rp_m;

endmodule