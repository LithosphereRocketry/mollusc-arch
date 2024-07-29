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

    
    wire [7:0] uart_tx_data;
    wire uart_tx_valid;
    wire uart_tx_ready;
    
    wire [7:0] uart_rx_data;
    wire uart_rx_valid;
    wire uart_rx_ready;
    
    wire [7:0] kb_data;
    wire kb_valid;
    wire kb_ready;

    wire kbdebug;

    reg [23:0] counter = 23'd0;
    wire [23:0] nextcounter = kbdebug ? (1 << 24) - 1 :
                              counter > 0 ? counter - 1 : 23'd0;
    always @(posedge clk48) begin
        counter <= nextcounter;

        // if(kbdebug) counter <= (1 << 24) - 1;
        // else if(counter > 0) counter <= counter - 1;
    end
    assign rgb_led0_b = (counter == 0);

    wire [13:0] vga_waddr;
    wire [7:0] vga_wdata;
    wire vga_wr_en;

    core root(
        .clk48(clk48),
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
        .vga_wr_en(vga_wr_en)
    );

    orangecrab_reset reset_instance(
		.clk(clk48),
		.do_reset(~usr_btn),
		.nreset_out(rst_n)
	);

    usbcdc usb(
        .clk48(clk48),
        .tx_data(uart_tx_data),
        .tx_valid(uart_tx_valid),
        .tx_ready(uart_tx_ready),
        .rx_data(uart_rx_data),
        .rx_valid(uart_tx_valid),
        .rx_ready(uart_rx_ready),

        .usb_d_n(usb_d_n),
        .usb_d_p(usb_d_p),
        .usb_pullup(usb_pullup)
    );

    ps2phy kb(
        .clkin(clk48),
        .sym_data(kb_data),
        .sym_valid(kb_valid),
        .sym_ready(kb_ready),
        .debug(kbdebug),

        .device_clk(ps2_kbclk),
        .device_dat(ps2_kbdat)
    );

    vgadisplay vga(
        .clk48(clk48),
        .busclk(clk48),
        .waddr(vga_waddr),
        .wdata(vga_wdata),
        .wr_en(vga_wr_en),

        .vsync(vga_vsync),
        .hsync(vga_hsync),
        .red(vga_red),
        .green(vga_green),
        .blue(vga_blue)
    );
endmodule