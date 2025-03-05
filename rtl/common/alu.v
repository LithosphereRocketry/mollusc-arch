module alu(
        input [3:0] op,
        input cmp,

        input [31:0] alu_a,
        input [31:0] alu_b,

        output [31:0] result
    );

    wire [31:0] alumux = ~op[3] ? (
        ~op[2] ? (
            ~op[1] ? (~op[0] ? alu_a + alu_b : alu_a - alu_b)
                   : (~op[0] ? alu_a & alu_b : alu_a | alu_b)
        ) : (
            ~op[1] ? (~op[0] ? alu_a ^ alu_b : alu_a << alu_b)
                   : (~op[0] ? alu_a >> alu_b : alu_a >>> alu_b)
        )
    ) : (
        32'hxxxxxxxx // mult operations
    );

    wire [31:0] cmpmux  = {27'h0000000, ~op[1] ?
        ({4'h0, ~op[0] ? alu_a < alu_b : (alu_a ^ 32'h80000000) < (alu_b ^ 32'h80000000)})
      : (~op[0] ? {4'h0, alu_a == alu_b} : 5'hxx)};
    
    assign result = cmp ? cmpmux : alumux;
endmodule