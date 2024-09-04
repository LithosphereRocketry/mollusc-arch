`timescale 1ns/1ps

module core(
        input  clk48,

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
        output vga_wr_en

    );

    // // Main wishbone bus that is fed by the CPU
    // // 128-bit width, byte addressable
    // wire [28:0] wb_host_adr_o;
    // wire [127:0] wb_host_dat_i;
    // wire [127:0] wb_host_dat_o;
    // wire wb_host_we_o;
    // wire [15:0] wb_host_sel_o;
    // wire wb_host_stb_o;
    // wire wb_host_ack_i;
    // wire wb_host_err_i;
    // wire wb_host_rty_i;
    // wire wb_host_cyc_o;

    // wire [13:0] wb_vga_adr_i;
    // wire [127:0] wb_vga_dat_i;
    // wire wb_vga_we_i;
    // wire [15:0] wb_vga_sel_i;
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

    // wb_mux_2 #(128, 32, 16) mainbus(

    // );
    
endmodule