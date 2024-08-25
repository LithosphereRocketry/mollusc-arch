module stage_execute(
        input clk,
        input [31:0] pc,

        input [3:0] dest,
        input [3:0] aluop,

        input [31:0] reg_a,
        input [31:0] reg_b,
        input [31:0] reg_m,

        output [3:0] fwd_addr,
        output [31:0] fwd_val,

        input is_mem_in,
        input mem_write_in,

        input is_jump,

        output jump,
        output [31:0] jump_addr,

        output reg [3:0] out_addr,
        output reg [31:0] out_val,

        output reg is_mem,
        output [31:0] mem_addr,
        output [31:0] mem_val,
        output mem_write
    );

    // Memory operations share an adder with relative jumps rather than
    // arithmetic in this design, which is a little unusual but shouldn't change
    // much in the bigger picture
    wire [31:0] memop_addr = reg_a + reg_b;

    wire [31:0] alu_a = is_jump ? pc : reg_a;
    wire [31:0] alu_b = is_jump ? 32'd8 : reg_b;
     // Because of branch delay, we are always returning to 8 bytes after
    wire [3:0] op = is_jump ? 4'h0 : aluop; // return address = addition

    wire [31:0] alumux [15:0];
    assign alumux[4'h0] = alu_a + alu_b;
    assign alumux[4'h1] = alu_a - alu_b;
    assign alumux[4'h2] = alu_a & alu_b;
    assign alumux[4'h3] = alu_a | alu_b;
    assign alumux[4'h4] = alu_a ^ alu_b;
    assign alumux[4'h5] = alu_a << alu_b;
    assign alumux[4'h6] = alu_a >> alu_b;
    assign alumux[4'h7] = alu_a >>> alu_b;

    assign fwd_addr = is_mem_in ? 4'h0 : dest;
    assign fwd_val = alumux[op];

    assign mem_val = reg_m;
    assign mem_addr = memop_addr;
    assign mem_write = mem_write_in;

    assign jump = is_jump;
    assign jump_addr = memop_addr;

    always @(posedge clk) begin
        out_addr <= dest;
        out_val <= fwd_val;
        is_mem <= is_mem_in;
    end

endmodule