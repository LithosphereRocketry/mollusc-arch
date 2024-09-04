`timescale 1ps/1ps

module cachetest (
        input clk,
        
        input valid_a,
        input [15:0] addr_a,
        output [31:0] dataout_a,
        output ready_a,
        
        input valid_b,
        input [15:0] addr_b,
        input [31:0] datain_b,
        input wr_b,
        output wr_ready_b,
        output [31:0] dataout_b,
        output ready_b
    );

    wire [15:0] wb_adr;
    wire [127:0] wb_dat_w;
    wire [127:0] wb_dat_r;
    wire wb_we;
    wire [15:0] wb_sel;
    wire wb_stb;
    wire wb_ack;
    wire wb_cyc;

    `ifndef ROMPATH
        `define ROMPATH ""
    `endif

    memcontrol #(128, 4, 16, 32) cache(
        .clk(clk),

        .valid_a(valid_a),
        .addr_a(addr_a),
        .dataout_a(dataout_a),
        .ready_a(ready_a),
        
        .valid_b(valid_b),
        .addr_b(addr_b),
        .datain_b(datain_b),
        .wr_b(wr_b),
        .wr_ready_b(wr_ready_b),
        .dataout_b(dataout_b),
        .ready_b(ready_b),

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