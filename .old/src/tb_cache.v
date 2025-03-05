`timescale 1ps/1ps

module tb_cache (
        input clk,
        input rst,
        
        input [15:0] addr,
        input addr_volatile,
        input addr_valid,
        output addr_ready,

        output [31:0] dout,
        output dout_valid,
        input dout_ready
    );

    wire [15:0] wb_adr;
    wire [127:0] wb_dat_w;
    wire [127:0] wb_dat_r;
    wire wb_we;
    wire [15:0] wb_sel;
    wire wb_stb;
    wire wb_ack;
    wire wb_cyc;

    cache #(
        .CACHE_WIDTH(128),
        .ADDR_WIDTH(16),
        .CACHE_DEPTH(4),
        .WORD_WIDTH(32),
        .ADDR_GRANULARITY(8)    
    ) cache(
        .clk(clk),
        .rst(rst),

        .addr(addr),
        .addr_volatile(addr_volatile),
        .addr_valid(addr_valid),
        .addr_ready(addr_ready),

        .dout(dout),
        .dout_valid(dout_valid),
        .dout_ready(dout_ready),

        .wb_adr_o(wb_adr),
        .wb_dat_o(wb_dat_w),
        .wb_dat_i(wb_dat_r),
        .wb_we_o(wb_we),
        .wb_sel_o(wb_sel),
        .wb_stb_o(wb_stb),
        .wb_ack_i(wb_ack),
        .wb_err_i(1'b0),
        .wb_rty_i(1'b0),
        .wb_cyc_o(wb_cyc)
    );

    wb_ram #(128, 16, 16) ram(
        .clk(clk),
        .adr_i(wb_adr),
        .dat_i(wb_dat_w),
        .dat_o(wb_dat_r),
        .we_i(wb_we),
        .sel_i(wb_sel),
        .stb_i(wb_stb),
        .ack_o(wb_ack),
        .cyc_i(wb_cyc)
    );
endmodule