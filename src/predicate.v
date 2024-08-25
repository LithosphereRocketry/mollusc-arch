/*
Predicate step of decode stage. Reads the value in the predicate register and
passes forward a NOP instead of the correct instruction if nonzero.

*/

`include "asm.vh"

module predicate(
        input [31:0] instr,
        output [3:0] reg_addr,

        input [31:0] reg_value,
        output [26:0] instr_out,
        output privileged
    );

    assign reg_addr = instr[31:28];

    wire pred = (reg_value == 32'h00000000) ^ instr[23];
    wire [31:0] nop = `NOP;
    wire [31:0] computed_instr = pred ? instr : nop;
    assign instr_out = {computed_instr[27:24], computed_instr[22:0]};

    privileged priv(
        .reg_addr(reg_addr),
        .priv(privileged)
    );
endmodule