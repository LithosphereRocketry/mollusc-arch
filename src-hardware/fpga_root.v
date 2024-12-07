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

        output [15:0] ddram_a,
        output [2:0] ddram_ba,
        output ddram_ras_n,
        output ddram_cas_n,
        output ddram_cke,
        output ddram_we_n,
        output ddram_cs_n,
        output [1:0] ddram_dm,
        input [15:0] ddram_dq,
        input [1:0] ddram_dqs_p,
        output ddram_clk_p,
        // Only the positive differential pin is instantiated
        // input [1:0] ddram_dqs_n,
        // input ddram_clk_n,
        output [5:0] ddram_vccio,
        output [1:0] ddram_gnd,
        output ddram_odt,
        output ddram_reset_n,

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
    
    // wire [7:0] kb_data;
    // wire kb_valid;
    // wire kb_ready;

    // wire [13:0] vga_waddr;
    // wire [7:0] vga_wdata;
    // wire vga_wr_en;

    wire cpuclk;
    // wire pll_lock;
    // pll_cpu pll(
    //     .clkin(clk48),
    //     .clkout0(cpuclk),
    //     .locked(pll_lock)
    // );

    wire reset_in = ~usr_btn/* | ~pll_lock*/;
    wire reset;
    wire [7:0] debug;
    wire led_r, led_g, led_b;

    // DRAM bus
    wire [31:0] wb_mem_adr_o;
    wire [127:0] wb_mem_dat_i;
    wire [127:0] wb_mem_dat_o;
    wire wb_mem_we_o;
    wire [15:0] wb_mem_sel_o;
    wire wb_mem_stb_o;
    wire wb_mem_ack_i;
    wire wb_mem_err_i;
    wire wb_mem_cyc_o;

    // DRAM control interface
    wire [31:0] wb_ddrctrl_adr_o;
    wire [31:0] wb_ddrctrl_dat_i;
    wire [31:0] wb_ddrctrl_dat_o;
    wire wb_ddrctrl_we_o;
    wire [3:0] wb_ddrctrl_sel_o;
    wire wb_ddrctrl_stb_o;
    wire wb_ddrctrl_ack_i;
    wire wb_ddrctrl_err_i;
    wire wb_ddrctrl_cyc_o;

    core root(
        .clk(cpuclk),
        .ioclk(clk48),
        .rst(reset),
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

        .wb_mem_adr_o(wb_mem_adr_o),
        .wb_mem_dat_o(wb_mem_dat_o),
        .wb_mem_dat_i(wb_mem_dat_i),
        .wb_mem_we_o(wb_mem_we_o),
        .wb_mem_sel_o(wb_mem_sel_o),
        .wb_mem_stb_o(wb_mem_stb_o),
        .wb_mem_ack_i(wb_mem_ack_i),
        .wb_mem_err_i(wb_mem_err_i),
        .wb_mem_cyc_o(wb_mem_cyc_o),

        .wb_ddrctrl_adr_o(wb_ddrctrl_adr_o),
        .wb_ddrctrl_dat_o(wb_ddrctrl_dat_o),
        .wb_ddrctrl_dat_i(wb_ddrctrl_dat_i),
        .wb_ddrctrl_we_o(wb_ddrctrl_we_o),
        .wb_ddrctrl_sel_o(wb_ddrctrl_sel_o),
        .wb_ddrctrl_stb_o(wb_ddrctrl_stb_o),
        .wb_ddrctrl_ack_i(wb_ddrctrl_ack_i),
        .wb_ddrctrl_err_i(wb_ddrctrl_err_i),
        .wb_ddrctrl_cyc_o(wb_ddrctrl_cyc_o),

        .debug(debug)
    );
    assign rgb_led0_r = ~led_r;
    assign rgb_led0_g = ~led_g;
    assign rgb_led0_b = ~led_b;

    orangecrab_reset #(48000000) reset_instance(
		.clk(clk48),
		.do_reset(~usr_btn),
		.nreset_out(rst_n)
	);

    assign vga_red = debug[2:0];
    assign vga_blue = debug[4:3];
    assign vga_hsync = debug[5];
    assign vga_green[1:0] = debug[7:6];

    usbcdc usb(
        .clk48(clk48),
        .rst(reset),
        .tx_data(uart_tx_data),
        .tx_valid(uart_tx_valid),
        .tx_ready(uart_tx_ready),
        .rx_data(uart_rx_data),
        .rx_valid(uart_rx_valid),
        .rx_ready(uart_rx_ready),

        .usb_d_n(usb_d_n),
        .usb_d_p(usb_d_p),
        .usb_pullup(usb_pullup)
    );

    assign ddram_vccio = 6'b111111;
    assign ddram_gnd = 2'b00;
    lite_ddr3l ddr3 (
        .clk(clk48),
        .ddram_a(ddram_a[12:0]),
        .ddram_ba(ddram_ba),
        .ddram_cas_n(ddram_cas_n),
        .ddram_cke(ddram_cke),
        .ddram_clk_n(ddram_clk_n),
        .ddram_clk_p(ddram_clk_p),
        .ddram_cs_n(ddram_cs_n),
        .ddram_dm(ddram_dm),
        .ddram_dq(ddram_dq),
        .ddram_dqs_n(ddram_dqs_n),
        .ddram_dqs_p(ddram_dqs_p),
        .ddram_odt(ddram_odt),
        .ddram_ras_n(ddram_ras_n),
        .ddram_reset_n(ddram_reset_n),
        .ddram_we_n(ddram_we_n),

        // output wire          init_done,
        // output wire          init_error,
        // .pll_locked(pll_lock),
        .rst(reset_in),
        .user_clk(cpuclk),
        .user_rst(reset),

        .user_port_wishbone_0_ack(wb_mem_ack_i),
        .user_port_wishbone_0_adr(wb_mem_adr_o[26:4]),
        .user_port_wishbone_0_cyc(wb_mem_cyc_o),
        .user_port_wishbone_0_dat_r(wb_mem_dat_i),
        .user_port_wishbone_0_dat_w(wb_mem_dat_o),
        .user_port_wishbone_0_err(wb_mem_err_i),
        .user_port_wishbone_0_sel(wb_mem_sel_o),
        .user_port_wishbone_0_stb(wb_mem_stb_o),
        .user_port_wishbone_0_we(wb_mem_we_o),

        .wb_ctrl_ack(wb_ddrctrl_ack_i),
        .wb_ctrl_adr(wb_ddrctrl_adr_o[31:2]),
        .wb_ctrl_bte(2'b00),
        .wb_ctrl_cti(3'b000),
        .wb_ctrl_cyc(wb_ddrctrl_cyc_o),
        .wb_ctrl_dat_r(wb_ddrctrl_dat_i),
        .wb_ctrl_dat_w(wb_ddrctrl_dat_o),
        .wb_ctrl_err(wb_ddrctrl_err_i),
        .wb_ctrl_sel(wb_ddrctrl_sel_o),
        .wb_ctrl_stb(wb_ddrctrl_stb_o),
        .wb_ctrl_we(wb_ddrctrl_we_o)
    );

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