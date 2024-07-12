module vgadisplay(
        input clk48,
        output [2:0] vga_red,
        output [2:0] vga_green,
        output [1:0] vga_blue,
        output vga_hsync,
        output vga_vsync,
        output rgb_led0_r,
        output rgb_led0_g,
        output rgb_led0_b,
        inout usb_d_p,
        inout usb_d_n,
        output usb_pullup,

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
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .scanx(xscan),
        .scany(yscan)
    );

    wire [2:0] red;
    wire [2:0] green;
    wire [1:0] blue;
    assign red = xscan[9:7];
    assign green = yscan[9:7];
    assign blue = {xscan[6], yscan[6]};

    assign vga_red = red & {3{inframe}};
    assign vga_green = green & {3{inframe}};
    assign vga_blue = blue & {3{inframe}};

    orangecrab_reset reset_instance(
		.clk(clk48),
		.do_reset(~usr_btn),
		.nreset_out(rst_n)
	);


    // Generate reset signal
    reg [5:0] reset_cnt = 0;
    wire usb_rst = ~reset_cnt[5];
    always @(posedge clk_48mhz)
        if ( locked )
            reset_cnt <= reset_cnt + usb_rst;

    wire [7:0] uart_d;
    wire uart_ready;
    wire uart_valid;

    usb_uart uart(
        .clk_48mhz(clk48),
        .reset(usb_rst),

        .pin_usb_n(usb_d_n),
        .pin_usb_p(usb_d_p),

        // uart pipeline in
        .uart_in_data( uart_d ),
        .uart_in_valid( uart_valid ),
        .uart_in_ready( uart_ready ),

        .uart_out_data( uart_d ),
        .uart_out_valid( uart_valid ),
        .uart_out_ready( uart_ready  )
    );
    assign usb_pullup = 1'b1;
endmodule