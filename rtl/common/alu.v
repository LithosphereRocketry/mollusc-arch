module alu(
        input [3:0] op,
        input cmp,

        input [31:0] alu_a,
        input [31:0] alu_b,

        output [31:0] result
    );

    reg [31:0] alu_res; // combinational

    always @* begin
        if(~cmp) case(op) 
            4'h0: alu_res = alu_a + alu_b;
            4'h1: alu_res = alu_a - alu_b;
            4'h2: alu_res = alu_a & alu_b;
            4'h3: alu_res = alu_a | alu_b;
            4'h4: alu_res = alu_a ^ alu_b;
            4'h5: alu_res = alu_a << alu_b;
            4'h6: alu_res = alu_a >> alu_b;
            4'h7: alu_res = alu_a >>> alu_b;
            4'h8: alu_res = {31'h0, (alu_a ^ 32'h80000000) < (alu_b ^ 32'h80000000)};
            4'h9: alu_res = {31'h0, alu_a < alu_b};
            4'ha: alu_res = {31'h0, alu_a == alu_b};
            default: alu_res = 'x;
        endcase else case(op[1:0])
            default: alu_res = 'x;
        endcase
    end
    
    assign result = alu_res;
endmodule