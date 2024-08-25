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
        output use_upper_imm,
        output use_imm,
        output is_mem,
        output mem_write,
        output is_jump,

        output [3:0] aluop
    );

    assign upper_imm = instr[20:0];
    assign lower_imm = instr[10:0];

    wire [1:0] basecode = instr[22:21];
    wire [1:0] subcode = {instr[20], instr[11]};

    assign upper_shiftmode = basecode[1];
    assign aui_mode = basecode[0];
    assign use_upper_imm = upper_shiftmode | aui_mode;

    wire m_format = ~use_upper_imm && subcode == 2'b11;

    wire [3:0] funccode = m_format ? instr[26:23] : instr[19:16];

    assign use_imm = use_upper_imm | funccode[3];
    assign is_mem = !use_upper_imm & subcode[1] & funccode[2] & funccode[1:0] != 2'b11;
    assign mem_write = is_mem & m_format;
    assign is_jump = (basecode == 2'b01) // long relative jump
                   | (basecode == 2'b00 & subcode == 2'b10 & funccode[2:0] == 3'b111); // register jump
    assign aluop = use_upper_imm ? 4'h0 : {subcode[1], funccode[2:0]};

    assign ra_d = m_format ? 4'b0 : instr[26:23];
    assign ra_m = m_format ? instr[19:16] : 4'b0;
    assign ra_a = use_upper_imm ? 4'b0 : instr[15:12];
    assign ra_b = use_imm ? 4'b0 : instr[3:0];

    wire rp_d, rp_m, rp_a, rp_b;
    privileged prv [3:0] (
        .reg_addr({ra_d, ra_m, ra_a, ra_b}),
        .priv({rp_d, rp_m, rp_a, rp_b})
    );
    assign priv = rp_a & rp_b & rp_d & rp_m;

endmodule