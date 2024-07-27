module vgadisplay(
        // Bus interface
        input clk48,
        input busclk,
        input [14:0] waddr,
        input [7:0] wdata,
        input wr_en,

        // Hardware outputs
        output vsync,
        output hsync,
        output [2:0] red,
        output [2:0] green,
        output [1:0] blue
    );

    // We don't really care how fast this comes up
    wire pxclk;
    pll_108 pll(
        .clkin(clk48),
        .clkout0(pxclk)
    );

    wire [10:0] xscan;
    wire [9:0] yscan;
    wire inframe;

    vgasync #(8) vga(
        .pxclk(pxclk),
        .inframe(inframe),
        .hsync(hsync),
        .vsync(vsync),
        .scanx(xscan),
        .scany(yscan)
    );

    reg [7:0] textbuf [64*256 - 1 : 0];
    initial textbuf[64*256 - 1 : 0] = " ";
    always @(posedge busclk) if(wr_en) textbuf[waddr] <= wdata;

    reg [7:0] charout;
    wire [7:0] nextline;
    charrom #(8) rom(
        .ascii(charout),
        .row(yscan[3:0]),
        .pxval(nextline)
    );

    reg [7:0] lineout;
    always @(negedge xscan[2]) begin
        lineout <= nextline;
        charout <= textbuf[{yscan[9:4], xscan[10:3]}];
    end
    reg pxout;
    always @(negedge pxclk) pxout <= lineout[xscan[2:0]];
    assign {red, green, blue} = {8{inframe & pxout}};
endmodule