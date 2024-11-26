`timescale 1ns/1ps

module core #(
        parameter CACHE_WIDTH = 128,
        parameter CACHE_DEPTH = 10,
        parameter BUS_GRANULARITY = 8,

        localparam SEL_WIDTH = CACHE_WIDTH/BUS_GRANULARITY,
        localparam NARROW_SEL_WIDTH = 32/BUS_GRANULARITY
    ) (
        input clk,
        input ioclk,
        input rst,

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

        output [7:0] debug
    );

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

    wire [3:0] cpudbg;

    cpu #(
        .CACHE_WIDTH(CACHE_WIDTH),
        .CACHE_DEPTH(CACHE_DEPTH),
        .BUS_GRANULARITY(BUS_GRANULARITY)
    ) cpucore(
        .clk(clk),
        .rst(rst),
        
        .wb_adr_o(wb_host_adr_o),
        .wb_dat_o(wb_host_dat_o),
        .wb_dat_i(wb_host_dat_i),
        .wb_we_o(wb_host_we_o),
        .wb_sel_o(wb_host_sel_o),
        .wb_stb_o(wb_host_stb_o),
        .wb_ack_i(wb_host_ack_i),
        .wb_err_i(wb_host_err_i),
        .wb_rty_i(wb_host_rty_i),
        .wb_cyc_o(wb_host_cyc_o),
        .dbg(cpudbg)
    );

    // Connection to common memory
    // 128-bit width, byte addressable
    wire [31:0] wb_mem_adr_o;
    wire [CACHE_WIDTH-1:0] wb_mem_dat_i;
    wire [CACHE_WIDTH-1:0] wb_mem_dat_o;
    wire wb_mem_we_o;
    wire [SEL_WIDTH-1:0] wb_mem_sel_o;
    wire wb_mem_stb_o;
    wire wb_mem_ack_i = 1'b0; // the WB mux doesn't deal well with unconnected ACK
    // wire wb_mem_err_i;
    // wire wb_mem_rty_i;
    wire wb_mem_cyc_o;

    // Connection to narrowing adapter for I/O registers
    // 128-bit width, byte addressable
    wire [31:0] wb_narrowbus_adr_o;
    wire [CACHE_WIDTH-1:0] wb_narrowbus_dat_i;
    wire [CACHE_WIDTH-1:0] wb_narrowbus_dat_o;
    wire wb_narrowbus_we_o;
    wire [SEL_WIDTH-1:0] wb_narrowbus_sel_o;
    wire wb_narrowbus_stb_o;
    wire wb_narrowbus_ack_i;
    wire wb_narrowbus_err_i;
    wire wb_narrowbus_rty_i;
    wire wb_narrowbus_cyc_o;

    // Large bus connecting to CPU. Mostly used for access to DDR3
    wb_mux_host #(CACHE_WIDTH, 32, SEL_WIDTH) hostbus(
        .clk(clk),
        .rst(rst),

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

        .wbs0_adr_o(wb_narrowbus_adr_o),
        .wbs0_dat_o(wb_narrowbus_dat_o),
        .wbs0_dat_i(wb_narrowbus_dat_i),
        .wbs0_we_o(wb_narrowbus_we_o),
        .wbs0_sel_o(wb_narrowbus_sel_o),
        .wbs0_stb_o(wb_narrowbus_stb_o),
        .wbs0_ack_i(wb_narrowbus_ack_i),
        .wbs0_err_i(wb_narrowbus_err_i),
        .wbs0_rty_i(wb_narrowbus_rty_i),
        .wbs0_cyc_o(wb_narrowbus_cyc_o),

        .wbs0_addr(32'h00000000),
        .wbs0_addr_msk(~32'h01FFFFFF), // first 32MB mapped to 32-bit sub-bus

        .wbs1_adr_o(wb_mem_adr_o),
        .wbs1_dat_o(wb_mem_dat_o),
        .wbs1_dat_i(wb_mem_dat_i),
        .wbs1_we_o(wb_mem_we_o),
        .wbs1_sel_o(wb_mem_sel_o),
        .wbs1_stb_o(wb_mem_stb_o),
        .wbs1_ack_i(wb_mem_ack_i),
        .wbs1_err_i(1'b0),
        .wbs1_rty_i(1'b0),
        .wbs1_cyc_o(wb_mem_cyc_o),

        .wbs1_addr(32'h00000000),
        .wbs1_addr_msk(32'h00000000) // Everything else mapped to DRAM
    );

    wire [31:0] wb_narrow_adr_o;
    wire [31:0] wb_narrow_dat_i;
    wire [31:0] wb_narrow_dat_o;
    wire wb_narrow_we_o;
    wire [NARROW_SEL_WIDTH-1:0] wb_narrow_sel_o;
    wire wb_narrow_stb_o;
    wire wb_narrow_ack_i;
    wire wb_narrow_err_i;
    wire wb_narrow_rty_i;
    wire wb_narrow_cyc_o;

    wb_adapter #(
        .ADDR_WIDTH(32),
        .WBM_DATA_WIDTH(CACHE_WIDTH),
        .WBM_SELECT_WIDTH(SEL_WIDTH),
        .WBS_DATA_WIDTH(32),
        .WBS_SELECT_WIDTH(NARROW_SEL_WIDTH)
    ) adapter(
        .clk(clk),
        .rst(rst),
        
        .wbm_adr_i(wb_narrowbus_adr_o),
        .wbm_dat_i(wb_narrowbus_dat_o),
        .wbm_dat_o(wb_narrowbus_dat_i),
        .wbm_we_i(wb_narrowbus_we_o),
        .wbm_sel_i(wb_narrowbus_sel_o),
        .wbm_stb_i(wb_narrowbus_stb_o),
        .wbm_ack_o(wb_narrowbus_ack_i),
        .wbm_err_o(wb_narrowbus_err_i),
        .wbm_rty_o(wb_narrowbus_rty_i),
        .wbm_cyc_i(wb_narrowbus_cyc_o),

        .wbs_adr_o(wb_narrow_adr_o),
        .wbs_dat_o(wb_narrow_dat_o),
        .wbs_dat_i(wb_narrow_dat_i),
        .wbs_we_o(wb_narrow_we_o),
        .wbs_sel_o(wb_narrow_sel_o),
        .wbs_stb_o(wb_narrow_stb_o),
        .wbs_ack_i(wb_narrow_ack_i),
        .wbs_err_i(wb_narrow_err_i),
        .wbs_rty_i(wb_narrow_rty_i),
        .wbs_cyc_o(wb_narrow_cyc_o)
    );

    wire [31:0] wb_sram_adr_o;
    wire [31:0] wb_sram_dat_i;
    wire [31:0] wb_sram_dat_o;
    wire wb_sram_we_o;
    wire [NARROW_SEL_WIDTH-1:0] wb_sram_sel_o;
    wire wb_sram_stb_o;
    wire wb_sram_ack_i;
    wire wb_sram_err_i;
    wire wb_sram_rty_i;
    wire wb_sram_cyc_o;

    wire [31:0] wb_brom_adr_o;
    wire [31:0] wb_brom_dat_i;
    wire [31:0] wb_brom_dat_o;
    wire wb_brom_we_o;
    wire [NARROW_SEL_WIDTH-1:0] wb_brom_sel_o;
    wire wb_brom_stb_o;
    wire wb_brom_ack_i;
    wire wb_brom_err_i;
    wire wb_brom_rty_i;
    wire wb_brom_cyc_o;

    wire [31:0] wb_iobus_adr_o;
    wire [31:0] wb_iobus_dat_i;
    wire [31:0] wb_iobus_dat_o;
    wire wb_iobus_we_o;
    wire [NARROW_SEL_WIDTH-1:0] wb_iobus_sel_o;
    wire wb_iobus_stb_o;
    wire wb_iobus_ack_i;
    wire wb_iobus_err_i;
    wire wb_iobus_rty_i;
    wire wb_iobus_cyc_o;

    wb_mux_narrow #(32, 32, 4) narrowbus (
        .clk(clk),
        .rst(rst),

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

        .wbs0_adr_o(wb_sram_adr_o),
        .wbs0_dat_o(wb_sram_dat_o),
        .wbs0_dat_i(wb_sram_dat_i),
        .wbs0_we_o(wb_sram_we_o),
        .wbs0_sel_o(wb_sram_sel_o),
        .wbs0_stb_o(wb_sram_stb_o),
        .wbs0_ack_i(wb_sram_ack_i),
        .wbs0_err_i(wb_sram_err_i),
        .wbs0_rty_i(wb_sram_rty_i),
        .wbs0_cyc_o(wb_sram_cyc_o),

        .wbs0_addr(32'h00000000),
        .wbs0_addr_msk(~32'h000007FF), // 2KB scratch RAM

        .wbs1_adr_o(wb_brom_adr_o),
        .wbs1_dat_o(wb_brom_dat_o),
        .wbs1_dat_i(wb_brom_dat_i),
        .wbs1_we_o(wb_brom_we_o),
        .wbs1_sel_o(wb_brom_sel_o),
        .wbs1_stb_o(wb_brom_stb_o),
        .wbs1_ack_i(wb_brom_ack_i),
        .wbs1_err_i(wb_brom_err_i),
        .wbs1_rty_i(wb_brom_rty_i),
        .wbs1_cyc_o(wb_brom_cyc_o),

        .wbs1_addr(32'h00008000),
        .wbs1_addr_msk(~32'h000007FF), // 2KB boot ROM

        .wbs2_adr_o(wb_iobus_adr_o),
        .wbs2_dat_o(wb_iobus_dat_o),
        .wbs2_dat_i(wb_iobus_dat_i),
        .wbs2_we_o(wb_iobus_we_o),
        .wbs2_sel_o(wb_iobus_sel_o),
        .wbs2_stb_o(wb_iobus_stb_o),
        .wbs2_ack_i(wb_iobus_ack_i),
        .wbs2_err_i(wb_iobus_err_i),
        .wbs2_rty_i(wb_iobus_rty_i),
        .wbs2_cyc_o(wb_iobus_cyc_o),

        .wbs2_addr(32'h01000000),
        .wbs2_addr_msk(~32'h00FFFFFF) // 16MB mapped into IO clock domain
    );

    wb_ram #(
        .ADDR_WIDTH(11),
        .DATA_WIDTH(32),
        .SELECT_WIDTH(4)
    ) sram(
        .clk(clk),
        .adr_i(wb_sram_adr_o[10:0]),
        .dat_i(wb_sram_dat_o),
        .dat_o(wb_sram_dat_i),
        .we_i(wb_sram_we_o),
        .sel_i(wb_sram_sel_o),
        .stb_i(wb_sram_stb_o),
        .ack_o(wb_sram_ack_i),
        .cyc_i(wb_sram_cyc_o)
    );
    assign wb_sram_err_i = 0;
    assign wb_sram_rty_i = 0;

    wb_ram #(
        .ADDR_WIDTH(11),
        .DATA_WIDTH(32),
        .SELECT_WIDTH(4),
        .INIT_PATH(`ROMPATH)
    ) brom(
        .clk(clk),
        .adr_i(wb_brom_adr_o[10:0]),
        .dat_i(wb_brom_dat_o),
        .dat_o(wb_brom_dat_i),
        .we_i(1'b0), // Never write so that our boot ROM can't be corrupted
        .sel_i(wb_brom_sel_o),
        .stb_i(wb_brom_stb_o),
        .ack_o(wb_brom_ack_i),
        .cyc_i(wb_brom_cyc_o)
    );
    // Throw a bus error if someone tries to write to ROM
    assign wb_brom_err_i = wb_brom_stb_o & wb_brom_we_o;
    assign wb_brom_rty_i = 0;

    wire [31:0] wb_io_adr_o;
    wire [31:0] wb_io_dat_i;
    wire [31:0] wb_io_dat_o;
    wire wb_io_we_o;
    wire [NARROW_SEL_WIDTH-1:0] wb_io_sel_o;
    wire wb_io_stb_o;
    wire wb_io_ack_i;
    wire wb_io_err_i;
    wire wb_io_rty_i;
    wire wb_io_cyc_o;

    wb_async_reg #(32, 32, 4) io_sync (
        .wbm_clk(clk),
        .wbm_rst(rst),
        .wbm_adr_i(wb_iobus_adr_o),
        .wbm_dat_i(wb_iobus_dat_o),
        .wbm_dat_o(wb_iobus_dat_i),
        .wbm_we_i(wb_iobus_we_o),
        .wbm_sel_i(wb_iobus_sel_o),
        .wbm_stb_i(wb_iobus_stb_o),
        .wbm_ack_o(wb_iobus_ack_i),
        .wbm_err_o(wb_iobus_err_i),
        .wbm_rty_o(wb_iobus_rty_i),
        .wbm_cyc_i(wb_iobus_cyc_o),

        .wbs_clk(ioclk),
        .wbs_rst(1'b0),
        .wbs_adr_o(wb_io_adr_o),
        .wbs_dat_o(wb_io_dat_o),
        .wbs_dat_i(wb_io_dat_i),
        .wbs_we_o(wb_io_we_o),
        .wbs_sel_o(wb_io_sel_o),
        .wbs_stb_o(wb_io_stb_o),
        .wbs_ack_i(wb_io_ack_i),
        .wbs_err_i(wb_io_err_i),
        .wbs_rty_i(wb_io_rty_i),
        .wbs_cyc_o(wb_io_cyc_o)
    );

    wire [31:0] wb_led_adr_o;
    wire [31:0] wb_led_dat_i;
    wire [31:0] wb_led_dat_o;
    wire wb_led_we_o;
    wire [NARROW_SEL_WIDTH-1:0] wb_led_sel_o;
    wire wb_led_stb_o;
    wire wb_led_ack_i;
    wire wb_led_err_i;
    wire wb_led_rty_i;
    wire wb_led_cyc_o;

    wire [31:0] wb_tty_adr_o;
    wire [31:0] wb_tty_dat_i;
    wire [31:0] wb_tty_dat_o;
    wire wb_tty_we_o;
    wire [NARROW_SEL_WIDTH-1:0] wb_tty_sel_o;
    wire wb_tty_stb_o;
    wire wb_tty_ack_i;
    wire wb_tty_err_i;
    wire wb_tty_rty_i;
    wire wb_tty_cyc_o;

    wb_mux_io #(32, 32, 4) iobus (
        .clk(clk),
        .rst(1'b0),

        .wbm_adr_i(wb_io_adr_o),
        .wbm_dat_i(wb_io_dat_o),
        .wbm_dat_o(wb_io_dat_i),
        .wbm_we_i(wb_io_we_o),
        .wbm_sel_i(wb_io_sel_o),
        .wbm_stb_i(wb_io_stb_o),
        .wbm_ack_o(wb_io_ack_i),
        .wbm_err_o(wb_io_err_i),
        .wbm_rty_o(wb_io_rty_i),
        .wbm_cyc_i(wb_io_cyc_o),

        .wbs0_adr_o(wb_led_adr_o),
        .wbs0_dat_o(wb_led_dat_o),
        .wbs0_dat_i(wb_led_dat_i),
        .wbs0_we_o(wb_led_we_o),
        .wbs0_sel_o(wb_led_sel_o),
        .wbs0_stb_o(wb_led_stb_o),
        .wbs0_ack_i(wb_led_ack_i),
        .wbs0_err_i(wb_led_err_i),
        .wbs0_rty_i(wb_led_rty_i),
        .wbs0_cyc_o(wb_led_cyc_o),

        .wbs0_addr(32'h01000000),
        .wbs0_addr_msk(~32'h00000003), // LED controller (one 32-bit word)

        .wbs1_adr_o(wb_tty_adr_o),
        .wbs1_dat_o(wb_tty_dat_o),
        .wbs1_dat_i(wb_tty_dat_i),
        .wbs1_we_o(wb_tty_we_o),
        .wbs1_sel_o(wb_tty_sel_o),
        .wbs1_stb_o(wb_tty_stb_o),
        .wbs1_ack_i(wb_tty_ack_i),
        .wbs1_err_i(wb_tty_err_i),
        .wbs1_rty_i(wb_tty_rty_i),
        .wbs1_cyc_o(wb_tty_cyc_o),

        .wbs1_addr(32'h01000008),
        .wbs1_addr_msk(~32'h00000007) // USB serial controller (2 words)

    );

    wire [31:0] led_value;
    wb_port #(32, NARROW_SEL_WIDTH) led_port (
        .clk(ioclk),

        .dat_i(wb_led_dat_o),
        .dat_o(wb_led_dat_i),
        .we_i(wb_led_we_o),
        .sel_i(wb_led_sel_o),
        .stb_i(wb_led_stb_o),
        .ack_o(wb_led_ack_i),
        .cyc_i(wb_led_cyc_o),

        .out(led_value)
    );
    assign wb_led_err_i = 1'b0;
    assign wb_led_rty_i = 1'b0;

    wire pwmclk;
    // 48MHz / 100Hz / 255 steps ~= 1882
    clkdiv #(1882) pwm_div(
        .clkin(ioclk),
        .clkout(pwmclk)
    );

    pwm #(8) ledpwm [2:0] (
        .clk(pwmclk),
        .value(led_value[23:0]),
        .signal({led_b, led_g, led_r})
    );

    wb_flow_port #(8) tty_port (
        .clk(ioclk),
        .rst(rst),
        
        .adr_i(wb_tty_adr_o[2]),
        .dat_o(wb_tty_dat_i[7:0]),
        .dat_i(wb_tty_dat_o[7:0]),
        .we_i(wb_tty_we_o),
        .stb_i(wb_tty_stb_o),
        .cyc_i(wb_tty_cyc_o),
        .ack_o(wb_tty_ack_i),

        .write_data(uart_tx_data),
        .write_valid(uart_tx_valid),
        .write_ready(uart_tx_ready),

        .read_data(uart_rx_data),
        .read_valid(uart_rx_valid),
        .read_ready(uart_rx_ready)
    );

    assign wb_tty_dat_i[31:8] = 24'h000000;
    assign wb_tty_err_i = 1'b0;
    assign wb_tty_rty_i = 1'b0;

    assign debug[7] = wb_host_ack_i;
    assign debug[6] = wb_host_stb_o;
    assign debug[5] = clk;
    assign debug[4] = rst;
    // assign debug[3] = wb_host_stb_o & wb_host_we_o & (wb_host_adr_o == 32'h01000000);
    assign debug[3] = wb_host_err_i;
    // assign debug[3:0] = cpudbg;
    // assign debug[3:0] = wb_host_adr_o[8:5];



endmodule