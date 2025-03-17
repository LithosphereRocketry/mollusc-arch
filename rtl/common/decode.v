module decode(
        input [31:0] instr,

        output [3:0] ra_pred,
        output [3:0] ra_a,
        output [3:0] ra_b,
        output [3:0] ra_m,

        output [31:0] imm,

        output [3:0] ra_d,

        output pred_inv,
        output use_imm,
        output pc_relative,
        output [3:0] aluop,
        output is_cmp,
        output is_jump,
        output is_mem,
        output mem_write
    );

    wire [20:0] upper_imm = instr[20:0];
    wire [10:0] lower_imm = instr[10:0];

    wire [1:0] basecode = instr[22:21];
    wire [1:0] subcode = {instr[20], instr[11]};

    wire mtype = subcode == 2'b11;
    wire [3:0] funccode = mtype ? instr[27:24] : instr[19:16];

    wire upper_shiftmode = basecode[1];
    assign pc_relative = basecode[0];
    wire use_upper_imm = basecode != 2'b00;
    assign use_imm = use_upper_imm | funccode[3];
    assign is_jump = (basecode == 2'b01) // long relative jump
                   | (basecode == 2'b00 & subcode == 2'b10 & funccode[2:0] == 3'b111); // register jump
    assign is_cmp = basecode == 2'b00 & subcode == 2'b10 & funccode[2] == 1'b0;
    assign is_mem = !use_upper_imm & subcode[1] & funccode[2] & (funccode[1:0] != 2'b11);
    assign mem_write = mtype; // todo slightly more complicated with tlb
    assign aluop = is_mem ? 4'h0 : {subcode[1], funccode[2:0]};

    // Sign-extended immediates
    wire [31:0] upper_ext = upper_shiftmode ? {upper_imm, 11'b0}
                                            : {{9{upper_imm[20]}}, upper_imm, 2'b0};
    wire [31:0] lower_ext = {{21{lower_imm[10]}}, lower_imm};

    assign imm = use_upper_imm ? upper_ext : lower_ext;

    wire m_format = ~use_upper_imm && subcode == 2'b11;

    assign ra_pred = instr[31:28];
    assign pred_inv = instr[23];
    assign ra_m = is_mem ? instr[19:16] : 4'h0;
    assign ra_a = use_upper_imm ? 4'h0 : instr[15:12];
    assign ra_b = use_imm ? 4'h0 : instr[3:0];

    assign ra_d = m_format ? 4'b0 : instr[27:24];

endmodule