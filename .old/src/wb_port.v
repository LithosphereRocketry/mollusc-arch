/*
 * Wishbone output port
 *
 * No addressing; just writes data to the register regardless of address.
 *
 */

module wb_port #(
        parameter DATA_WIDTH = 32,
        parameter SELECT_WIDTH = DATA_WIDTH/8,

        localparam WORD_WIDTH = DATA_WIDTH/SELECT_WIDTH
    ) (
        input clk,
        output [DATA_WIDTH-1:0] dat_o,
        input [DATA_WIDTH-1:0] dat_i,
        input we_i,
        input [SELECT_WIDTH-1:0] sel_i,
        input stb_i,
        output ack_o,
        input cyc_i,

        output reg [DATA_WIDTH-1:0] out
    );

    assign dat_o = out;
    assign ack_o = stb_i & cyc_i;

    integer i;
    always @(posedge clk) if(we_i & stb_i & cyc_i) begin
        for(i = 0; i < SELECT_WIDTH; i++) if(sel_i[i]) begin
            out[i*WORD_WIDTH +: WORD_WIDTH] <= dat_i[i*WORD_WIDTH +: WORD_WIDTH];
        end
    end

endmodule