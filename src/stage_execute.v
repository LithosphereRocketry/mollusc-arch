module stage_execute(
        input [4:0] corenum,
        input clk,
        input rst,
        input [31:0] pc,

        input stall_in,
        output stall,

        input [3:0] dest,
        input [3:0] aluop,
        input is_cmp,

        input [31:0] reg_a,
        input [31:0] reg_b,
        input [31:0] reg_m,

        output fwd_valid,
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

    assign stall = stall_in;

    // Memory operations share an adder with relative jumps rather than
    // arithmetic in this design, which is a little unusual but shouldn't change
    // much in the bigger picture
    wire [31:0] memop_addr = reg_a + reg_b;

    wire [31:0] alu_a = is_jump ? pc : reg_a;
    wire [31:0] alu_b = is_jump ? 32'd4 : reg_b;
    // Return address is always 4 bytes after PC
    wire [3:0] op = is_jump ? 4'h0 : aluop; // return address = addition

    wire [31:0] alumux = ~op[3] ? (
        ~op[2] ? (
            ~op[1] ? (~op[0] ? alu_a + alu_b : alu_a - alu_b)
                   : (~op[0] ? alu_a & alu_b : alu_a | alu_b)
        ) : (
            ~op[1] ? (~op[0] ? alu_a ^ alu_b : alu_a << alu_b)
                   : (~op[0] ? alu_a >> alu_b : alu_a >>> alu_b)
        )
    ) : (
        32'hxxxxxxxx
    );

    wire [31:0] cmpmux  = {27'h0000000, ~op[1] ?
        ({4'h0, ~op[0] ? alu_a < alu_b : (alu_a ^ 32'h80000000) < (alu_b ^ 32'h80000000)})
      : (~op[0] ? {4'h0, alu_a == alu_b} : corenum)};

    assign fwd_valid = ~is_mem_in;
    assign fwd_addr = dest;
    assign fwd_val = is_cmp ? cmpmux : alumux;

    assign mem_val = reg_m;
    assign mem_addr = memop_addr;
    assign mem_write = mem_write_in;

    assign jump = is_jump;
    assign jump_addr = memop_addr;

    task reset();
        begin
            /* verilator lint_off INITIALDLY */
            out_addr <= 4'h0;
            out_val <= 32'hxxxxxxxx;
            is_mem <= 1'b0;
            /* lint_on */
        end
    endtask
    initial reset();

    always @(posedge clk) begin
        if(rst) reset();
        else begin
            if(~stall) begin
                out_addr <= dest;
                out_val <= fwd_val;
                is_mem <= is_mem_in;
            end else if(~stall_in) begin
                // If we created the stall, emit a bubble
                out_addr <= 4'h0;
                out_val <= 32'hxxxxxxxx;
                is_mem <= 1'b0;
            end
        end
    end

endmodule