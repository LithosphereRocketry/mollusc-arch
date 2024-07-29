module decode(
        input [28:0] instr,
        input priv_in,

        output [3:0] ra_a,
        output [3:0] ra_b,
        output [3:0] ra_m,
        output [3:0] ra_d,

        output [21:0] upper_imm,
        output [9:0] lower_imm,

        output priv,

        // 0: shift by 2, 1: shift by 10
        output upper_shiftmode,
        // 0: add to 0, 1: add to PC
        output aui_mode
    );

    assign ra_d = instr[27:24];
    assign ra_m = instr[17:14];
    assign ra_a = instr[13:10];
    assign ra_b = instr[9:6];

    wire rp_d, rp_m, rp_a, rp_b;
    privileged prv [3:0] (
        .reg_addr({rp_d, rp_m, rp_a, rp_b}),
        .priv({rp_d, rp_m, rp_a, rp_b})
    );

    assign upper_imm = instr[21:0];
    assign lower_imm = instr[9:0];

    assign upper_shiftmode = instr[23];
    assign aui_mode = instr[22];

endmodule