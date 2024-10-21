`timescale 1ns/1ps

module core #(
        parameter CACHE_WIDTH = 128,
        parameter CACHE_DEPTH = 10,
        parameter BUS_GRANULARITY = 8,

        localparam SEL_WIDTH = CACHE_WIDTH/BUS_GRANULARITY,
        localparam NARROW_SEL_WIDTH = 32/BUS_GRANULARITY
    ) (
        input  clk48,

        output led_r,
        output led_g,
        output led_b,

        // UART, core -> tty
        output [7:0] uart_tx_data,
        output uart_tx_valid,
        input uart_tx_ready,
        // UART, tty -> core
        input [7:0] uart_rx_data,
        input uart_rx_valid,
        output uart_rx_ready,

        // PS/2 keyboard scan
        input [7:0] kb_data,
        input kb_valid,
        output kb_ready,

        output [13:0] vga_waddr,
        output [7:0] vga_wdata,
        output vga_wr_en,

        output [31:0] dbg

    );

    wire clk = clk48;
    // clkdiv #(48, 24) corediv(
    //     .clkin(clk48),
    //     .clkout(clk)
    // );

    // Main wishbone bus that is fed by the CPU
    // 128-bit width, byte addressable
    wire [31:0] wb_host_adr_o;
    wire [CACHE_WIDTH-1:0] wb_host_dat_i;
    wire [CACHE_WIDTH-1:0] wb_host_dat_o;
    wire wb_host_we_o;
    wire [SEL_WIDTH-1:0] wb_host_sel_o;
    wire wb_host_stb_o;
    wire wb_host_ack_i;
    wire wb_host_err_i;
    wire wb_host_rty_i;
    wire wb_host_cyc_o;

    assign dbg = {wb_host_dat_i[31:4], wb_host_we_o, |`ROMPATH, wb_host_ack_i, clk};

    cpu #(
        .CACHE_WIDTH(CACHE_WIDTH),
        .CACHE_DEPTH(CACHE_DEPTH),
        .BUS_GRANULARITY(BUS_GRANULARITY)
    ) cpucore(
        .clk(clk),
        .rst(1'b0),
        
        .wb_adr_o(wb_host_adr_o),
        .wb_dat_o(wb_host_dat_o),
        .wb_dat_i(wb_host_dat_i),
        .wb_we_o(wb_host_we_o),
        .wb_sel_o(wb_host_sel_o),
        .wb_stb_o(wb_host_stb_o),
        .wb_ack_i(wb_host_ack_i),
        .wb_err_i(wb_host_err_i),
        .wb_rty_i(wb_host_rty_i),
        .wb_cyc_o(wb_host_cyc_o)
    );

    // Connection to common memory
    // 128-bit width, byte addressable
    wire [31:0] wb_mem_adr_o;
    wire [CACHE_WIDTH-1:0] wb_mem_dat_i;
    wire [CACHE_WIDTH-1:0] wb_mem_dat_o;
    wire wb_mem_we_o;
    wire [SEL_WIDTH-1:0] wb_mem_sel_o;
    wire wb_mem_stb_o;
    wire wb_mem_ack_i;
    // wire wb_mem_err_i;
    // wire wb_mem_rty_i;
    wire wb_mem_cyc_o;

    // Connection to narrowing adapter for I/O registers
    // 128-bit width, byte addressable
    wire [31:0] wb_narrow_adr_o;
    wire [CACHE_WIDTH-1:0] wb_narrow_dat_i;
    wire [CACHE_WIDTH-1:0] wb_narrow_dat_o;
    wire wb_narrow_we_o;
    wire [SEL_WIDTH-1:0] wb_narrow_sel_o;
    wire wb_narrow_stb_o;
    wire wb_narrow_ack_i;
    wire wb_narrow_err_i;
    wire wb_narrow_rty_i;
    wire wb_narrow_cyc_o;

    wb_mux_2 #(CACHE_WIDTH, 32, SEL_WIDTH) mainbus(
        .clk(clk),
        .rst(1'b0),

        .wbm_adr_i(wb_host_adr_o),
        .wbm_dat_i(wb_host_dat_o),
        .wbm_dat_o(wb_host_dat_i),
        .wbm_we_i(wb_host_we_o),
        .wbm_sel_i(wb_host_sel_o),
        .wbm_stb_i(wb_host_stb_o),
        .wbm_ack_o(wb_host_ack_i),
        .wbm_err_o(wb_host_err_i),
        .wbm_rty_o(wb_host_rty_i),
        .wbm_cyc_i(wb_host_cyc_o),

        .wbs0_adr_o(wb_mem_adr_o),
        .wbs0_dat_o(wb_mem_dat_o),
        .wbs0_dat_i(wb_mem_dat_i),
        .wbs0_we_o(wb_mem_we_o),
        .wbs0_sel_o(wb_mem_sel_o),
        .wbs0_stb_o(wb_mem_stb_o),
        .wbs0_ack_i(wb_mem_ack_i),
        .wbs0_err_i(1'b0),
        .wbs0_rty_i(1'b0),
        .wbs0_cyc_o(wb_mem_cyc_o),

        .wbs0_addr(32'h00000000),
        .wbs0_addr_msk(~32'h3FFF), // 512B main memory

        .wbs1_adr_o(wb_narrow_adr_o),
        .wbs1_dat_o(wb_narrow_dat_o),
        .wbs1_dat_i(wb_narrow_dat_i),
        .wbs1_we_o(wb_narrow_we_o),
        .wbs1_sel_o(wb_narrow_sel_o),
        .wbs1_stb_o(wb_narrow_stb_o),
        .wbs1_ack_i(wb_narrow_ack_i),
        .wbs1_err_i(wb_narrow_err_i),
        .wbs1_rty_i(wb_narrow_rty_i),
        .wbs1_cyc_o(wb_narrow_cyc_o),

        .wbs1_addr(32'h00004000),
        .wbs1_addr_msk(~32'h3FFF) // 512B I/O space (not all used)
    );

    wb_ram #(
        .ADDR_WIDTH(14),
        .DATA_WIDTH(CACHE_WIDTH),
        .SELECT_WIDTH(SEL_WIDTH),
        .INIT_PATH(`ROMPATH)
    ) ram(
        .clk(clk),
        .adr_i(wb_mem_adr_o[13:0]),
        .dat_i(wb_mem_dat_o),
        .dat_o(wb_mem_dat_i),
        .we_i(wb_mem_we_o),
        .sel_i(wb_mem_sel_o),
        .stb_i(wb_mem_stb_o),
        .ack_o(wb_mem_ack_i),
        .cyc_i(wb_mem_stb_o)
    );

    wire [31:0] wb_nb_adr_o;
    wire [31:0] wb_nb_dat_i;
    wire [31:0] wb_nb_dat_o;
    wire wb_nb_we_o;
    wire [NARROW_SEL_WIDTH-1:0] wb_nb_sel_o;
    wire wb_nb_stb_o;
    wire wb_nb_ack_i;
    wire wb_nb_err_i;
    wire wb_nb_rty_i;
    wire wb_nb_cyc_o;


    wb_adapter #(
        .ADDR_WIDTH(32),
        .WBM_DATA_WIDTH(CACHE_WIDTH),
        .WBM_SELECT_WIDTH(SEL_WIDTH),
        .WBS_DATA_WIDTH(32),
        .WBS_SELECT_WIDTH(NARROW_SEL_WIDTH)
    ) adapter(
        .clk(clk),
        .rst(1'b0),
        
        .wbm_adr_i(wb_narrow_adr_o),
        .wbm_dat_i(wb_narrow_dat_o),
        .wbm_dat_o(wb_narrow_dat_i),
        .wbm_we_i(wb_narrow_we_o),
        .wbm_sel_i(wb_narrow_sel_o),
        .wbm_stb_i(wb_narrow_stb_o),
        .wbm_ack_o(wb_narrow_ack_i),
        .wbm_err_o(wb_narrow_err_i),
        .wbm_rty_o(wb_narrow_rty_i),
        .wbm_cyc_i(wb_narrow_cyc_o),

        .wbs_adr_o(wb_nb_adr_o),
        .wbs_dat_o(wb_nb_dat_o),
        .wbs_dat_i(wb_nb_dat_i),
        .wbs_we_o(wb_nb_we_o),
        .wbs_sel_o(wb_nb_sel_o),
        .wbs_stb_o(wb_nb_stb_o),
        .wbs_ack_i(wb_nb_ack_i),
        .wbs_err_i(wb_nb_err_i),
        .wbs_rty_i(wb_nb_rty_i),
        .wbs_cyc_o(wb_nb_cyc_o)
    );

    assign wb_nb_err_i = 0;
    assign wb_nb_rty_i = 0;

    wire [31:0] led_value;
    wb_port #(32, NARROW_SEL_WIDTH) led_port (
        .clk(clk),

        .dat_o(wb_nb_dat_i),
        .dat_i(wb_nb_dat_o),
        .we_i(wb_nb_we_o),
        .sel_i(wb_nb_sel_o),
        .stb_i(wb_nb_stb_o),
        .ack_o(wb_nb_ack_i),
        .cyc_i(wb_nb_cyc_o),

        .out(led_value)
    );

    wire pwmclk;
    clkdiv #(1200) pwm_div(
        .clkin(clk),
        .clkout(pwmclk)
    );

    pwm #(8) ledpwm (
        .clk(pwmclk),
        .value(led_value[7:0]),
        .signal({led_r})
    );

    assign led_g = wb_host_stb_o & ~wb_host_adr_o[15];
    assign led_b = wb_host_stb_o & wb_host_adr_o[15];

    // wire [1SEL_WIDTH-1:0] wb_vga_adr_i;
    // wire [CACHE_WIDTH-1:0] wb_vga_dat_i;
    // wire wb_vga_we_i;
    // wire [SEL_WIDTH-1:0] wb_vga_sel_i;
    // wire wb_vga_stb_i;
    // wire wb_vga_ack_o;
    // wire wb_vga_cyc_i;

    // wire vga_adapt_wb_stb;
    // wire vga_adapt_wb_we;
    // wb_adapter #(14, 128, 16, 8, 1) vga_widen(
    //     .wbm_adr_i(wb_vga_adr_i),
    //     .wbm_dat_i(wb_vga_dat_i),
    //     .wbm_we_i(wb_vga_we_i),
    //     .wbm_sel_i(wb_vga_sel_i),
    //     .wbm_stb_i(wb_vga_stb_i),
    //     .wbm_ack_o(wb_vga_ack_o),
    //     .wbm_cyc_i(wb_vga_cyc_i),

    //     .wbs_adr_o(vga_waddr),
    //     .wbs_dat_i(8'hxx), // Never read back data
    //     .wbs_dat_o(vga_wdata),
    //     .wbs_we_o(vga_adapt_wb_we),
    //     .wbs_stb_o(vga_adapt_wb_stb),
    //     .wbs_ack_i(vga_adapt_wb_stb), // Always acknowledge right away
    //     .wbs_err_i(1'b0), // Never error
    //     .wbs_rty_i(1'b0) // Never retry
    // );
    // assign vga_wr_en = vga_adapt_wb_stb & vga_adapt_wb_we;


endmodule