module vgadisplay(
        input clk48,
        output gpio_6,
        output gpio_9,
        output gpio_10,
        output rgb_led0_r,
        output rgb_led0_g,
        output rgb_led0_b,
        output rst_n,
        input usr_btn
    );
    wire pxclk;
    wire locked;
    
    pll_108 pll(
        .clkin(clk48),
        .clkout0(pxclk),
        .locked(locked)
    );
    assign rgb_led0_b = locked;
    assign rgb_led0_r = 1'b1;

    vgasync vga(
        .pxclk(pxclk),
        .inframe(gpio_6),
        .hsync(gpio_9),
        .vsync(gpio_10)
    );

    orangecrab_reset reset_instance(
		.clk(clk48),
		.do_reset(~usr_btn),
		.nreset_out(rst_n)
	);
endmodule