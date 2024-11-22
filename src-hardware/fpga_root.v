module fpga_root(
        input  clk48,
        output rst_n,

        inout  usb_d_p,
        inout  usb_d_n,
        output usb_pullup,

        output rgb_led0_r,
        output rgb_led0_g,
        output rgb_led0_b,

        output vga_hsync,
        output vga_vsync,
        output [2:0] vga_red,
        output [2:0] vga_green,
        output [1:0] vga_blue,

        input ps2_kbdat,
        input ps2_kbclk,

        input usr_btn,
        input hbb_sw
    );

    
    // wire [7:0] uart_tx_data;
    // wire uart_tx_valid;
    // wire uart_tx_ready;
    
    // wire [7:0] uart_rx_data;
    // wire uart_rx_valid;
    // wire uart_rx_ready;
    
    // wire [7:0] kb_data;
    // wire kb_valid;
    // wire kb_ready;

    // wire [13:0] vga_waddr;
    // wire [7:0] vga_wdata;
    // wire vga_wr_en;

    wire cpuclk;
    wire pll_lock;
    pll_cpu pll(
        .clkin(clk48),
        .clkout0(cpuclk),
        .locked(pll_lock)
    );

    wire [7:0] debug;
    wire led_r, led_g, led_b;
    core root(
        .clk(cpuclk),
        .rst(~hbb_sw | ~pll_lock),
        .led_r(led_r),
        .led_g(led_g),
        .led_b(led_b),
        .uart_tx_data(uart_tx_data),
        .uart_tx_valid(uart_tx_valid),
        .uart_tx_ready(uart_tx_ready),
        .uart_rx_data(uart_rx_data),
        .uart_rx_valid(uart_rx_valid),
        .uart_rx_ready(uart_rx_ready),
        .kb_data(kb_data),
        .kb_valid(kb_valid),
        .kb_ready(kb_ready),
        .vga_waddr(vga_waddr),
        .vga_wdata(vga_wdata),
        .vga_wr_en(vga_wr_en),
        .debug(debug)
    );
    assign rgb_led0_r = ~led_r;
    assign rgb_led0_g = ~led_g & hbb_sw;
    assign rgb_led0_b = ~led_b;

    orangecrab_reset reset_instance(
		.clk(clk48),
		.do_reset(~usr_btn),
		.nreset_out(rst_n)
	);

    assign vga_red = debug[2:0];
    assign vga_blue = debug[4:3];
    assign vga_hsync = debug[5];
    assign vga_green[1:0] = debug[7:6];

    // usbcdc usb(
    //     .clk48(clk48),
    //     .tx_data(uart_tx_data),
    //     .tx_valid(uart_tx_valid),
    //     .tx_ready(uart_tx_ready),
    //     .rx_data(uart_rx_data),
    //     .rx_valid(uart_rx_valid),
    //     .rx_ready(uart_rx_ready),

    //     .usb_d_n(usb_d_n),
    //     .usb_d_p(usb_d_p),
    //     .usb_pullup(usb_pullup)
    // );

    // ps2phy kb(
    //     .clkin(clk48),
    //     .sym_data(kb_data),
    //     .sym_valid(kb_valid),
    //     .sym_ready(kb_ready),

    //     .device_clk(ps2_kbclk),
    //     .device_dat(ps2_kbdat)
    // );

    // vgadisplay vga(
    //     .clk48(clk48),
    //     .busclk(clk48),
    //     .waddr(vga_waddr),
    //     .wdata(vga_wdata),
    //     .wr_en(vga_wr_en),

    //     .vsync(vga_vsync),
    //     .hsync(vga_hsync),
    //     .red(vga_red),
    //     .green(vga_green),
    //     .blue(vga_blue)
    // );
endmodule