module cputest(
        input clk,
        input rst
    );

    wire [31:0] wb_adr;
    wire [127:0] wb_dat_r, wb_dat_w;
    wire wb_we;
    wire [15:0] wb_sel;
    wire wb_stb, wb_ack, wb_cyc;

    wire [7:0] dbg;

    cpu #(
        .CACHE_WIDTH(128),
        .CACHE_DEPTH(4),
        .BUS_GRANULARITY(8)
    ) cpucore(
        .clk(clk),
        .rst(rst),
        
        .wb_adr_o(wb_adr),
        .wb_dat_o(wb_dat_w),
        .wb_dat_i(wb_dat_r),
        .wb_we_o(wb_we),
        .wb_sel_o(wb_sel),
        .wb_stb_o(wb_stb),
        .wb_ack_i(wb_ack),
        .wb_err_i(1'b0),
        .wb_rty_i(1'b0),
        .wb_cyc_o(wb_cyc),
        .dbg(dbg)
    );

    wb_ram #(
        .DATA_WIDTH(128),
        .ADDR_WIDTH(16),
        .INIT_PATH(`ROMPATH)
    ) ram(
        .clk(clk),
        .adr_i(wb_adr[15:0]),
        .dat_i(wb_dat_w),
        .dat_o(wb_dat_r),
        .we_i(wb_we),
        .sel_i(wb_sel),
        .stb_i(wb_stb),
        .ack_o(wb_ack),
        .cyc_i(wb_cyc)
    );
endmodule