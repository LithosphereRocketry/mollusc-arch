module stage_fetch(
        input clk,
        input rst,
        input is_jump,
        input [31:0] jump_addr,

        output [31:0] fetchpc,
        output reg [31:0] presentpc,
        input stall_in
    );

    wire fetch_virtual = 1'b0;

    initial presentpc = 32'h00000000 - 32'h4;

    assign fetchpc = stall_in ? presentpc
                              : is_jump ? jump_addr : presentpc + 32'h4;
    always @(posedge clk) if(rst) presentpc <=  32'h00000000 - 32'h4;
            else if(~stall_in) presentpc <= fetchpc;

endmodule