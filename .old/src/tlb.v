module tlb #(
        parameter TLB_DEPTH = 10, // 2^10 = 1024 entries
        parameter PAGE_DEPTH = 12, // page size 2^12 = 4KB
        parameter ADDR_WIDTH = 32,

        localparam TAG_WIDTH = (ADDR_WIDTH - PAGE_DEPTH),
        localparam ENTRY_WIDTH = 2*TAG_WIDTH + 4
    ) (
        input clk,
        input rst
    );

    // dp_ram #(
    //     .D_WIDTH(ENTRY_WIDTH),
    //     .A_WIDTH(TLB_DEPTH)
    // ) tlb_ram(
    //     .clk(clk),

    //     // input [A_WIDTH-1:0] addr_a,
    //     .wdata_a({ENTRY_WIDTH{1'bx}}),
    //     .wr_a(1'b0),
    //     // output reg [D_WIDTH-1:0] rdata_a,

    //     // input [A_WIDTH-1:0] addr_b,
    //     // input [D_WIDTH-1:0] wdata_b,
    //     // input wr_b,
    //     // output reg [D_WIDTH-1:0] rdata_b

    // );

endmodule