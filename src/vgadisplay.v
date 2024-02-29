module vgadisplay(
        input clk48,
        output gpio_9,  // b
        output gpio_10, // g
        output gpio_11, // r
        output gpio_12, // vsync
        output gpio_13, // hsync
        output rgb_led0_r,
        output rgb_led0_g,
        output rgb_led0_b,
        output rst_n,
        input usr_btn
    );
    wire pxclk;
    wire locked;

    wire [11:0] xscan;
    wire [10:0] yscan;
    
    pll_108 pll(
        .clkin(clk48),
        .clkout0(pxclk),
        .locked(locked)
    );
    assign rgb_led0_b = locked;
    assign rgb_led0_r = 1'b1;
    wire inframe;

    vgasync vga(
        .pxclk(pxclk),
        .inframe(inframe),
        .hsync(gpio_13),
        .vsync(gpio_12),
        .scanx(xscan),
        .scany(yscan)
    );

    wire glyphout;
    charrom cr(
        .ascii(xscan[9:3]),
        .row(yscan[3:0]),
        .col(xscan[2:0]),
        .pxval(glyphout)
    );
    wire pxout;
    assign pxout = (xscan < 1024 & yscan < 16) & glyphout;

    assign red = pxout;
    assign green = pxout;
    assign blue = pxout;

    assign gpio_11 = red & inframe;
    assign gpio_10 = green & inframe;
    assign gpio_9 = blue & inframe;

    orangecrab_reset reset_instance(
		.clk(clk48),
		.do_reset(~usr_btn),
		.nreset_out(rst_n)
	);
endmodule