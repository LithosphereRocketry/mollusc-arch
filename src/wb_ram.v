// Loosely based on the module of the same name from FuseSOC

module wb_ram #(
        parameter D_WIDTH = 32,
        parameter A_WIDTH = 8,
        parameter GRANULARITY = 8,

        localparam G_WIDTH = D_WIDTH / GRANULARITY
    ) (
        input clk_i,
        input [D_WIDTH-1:0] dat_i,
        output reg [D_WIDTH-1:0] dat_o,
        input rst_i,
        // no tags supported
        output reg ack_o,
        input [A_WIDTH-1:0] adr_i,
        // input cyc_i, cycle doesn't do anything
        // no stalls
        // no errors
        // no locking
        // no retry
        input [G_WIDTH-1:0] sel_i,
        input stb_i,
        // still no tags
        input we_i
    );

    reg [D_WIDTH-1:0] mem [(1 << A_WIDTH - 1):0];

    integer i;
    always @(posedge clk_i) begin
        if(stb_i & we_i) begin
            for(i = 0; i < G_WIDTH; i = i + 1) begin
                if(sel_i[i]) mem[adr_i][i*G_WIDTH +: G_WIDTH]
                        <= dat_i[i*G_WIDTH +: G_WIDTH];
            end
            dat_o <= {D_WIDTH{1'bx}};
        end else dat_o <= mem[adr_i];
        ack_o <= stb_i;
    end

    

endmodule