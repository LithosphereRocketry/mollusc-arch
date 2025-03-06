module cpu_wb #(
        // TODO: can we change granularity?
        parameter CACHE_WIDTH = 128,
        parameter ICACHE_DEPTH = 9,
        parameter DCACHE_DEPTH = 9,

        localparam SEL_WIDTH = CACHE_WIDTH/8
    ) (
        input clk,
        input rst,

        output [31:0] wb_adr_o,
        output [CACHE_WIDTH-1:0] wb_dat_o,
        input [CACHE_WIDTH-1:0] wb_dat_i,
        output wb_we_o,
        output [SEL_WIDTH-1:0] wb_sel_o,
        output wb_stb_o,
        input wb_ack_i,
        input wb_err_i,
        input wb_rty_i,
        output wb_cyc_o
    );

    wire [31:0] i_addr, i_data, d_addr, d_dout, d_din;
    wire i_addr_valid, i_addr_ready, i_data_valid, i_data_ready;
    wire d_addr_valid, d_addr_ready, d_data_valid, d_data_ready, d_wr;
    cpu_core core(
        .clk(clk),
        .rst(rst),

        .i_addr(i_addr),
        .i_addr_valid(i_addr_valid),
        .i_addr_ready(i_addr_ready),

        .i_data(i_data),
        .i_data_valid(i_data_valid),
        .i_data_ready(i_data_ready),

        .d_addr(d_addr),
        .d_dout(d_dout),
        .d_wr(d_wr),
        .d_addr_valid(d_addr_valid),
        .d_addr_ready(d_addr_ready),

        .d_din(d_din),
        .d_data_valid(d_data_valid),
        .d_data_ready(d_data_ready)
    );

    wire [31:0] wb_i_adr;
    wire [127:0] wb_i_dat_r, wb_i_dat_w;
    wire wb_i_we;
    wire [15:0] wb_i_sel;
    wire wb_i_stb, wb_i_ack, wb_i_err, wb_i_rty, wb_i_cyc;

    cache #( 
        .CACHE_WIDTH(CACHE_WIDTH),
        .ADDR_WIDTH(32),
        .CACHE_DEPTH(ICACHE_DEPTH),
        .WORD_WIDTH(32),
        .ADDR_GRANULARITY(8)
    ) icache(
        .clk(clk),
        .rst(rst),

        .addr(i_addr),
        .addr_volatile(1'b0),
        .wr(1'b0),
        .din(32'hxxxxxxxx),
        .addr_valid(i_addr_valid),
        .addr_ready(i_addr_ready),

        .dout(i_data),
        .dout_valid(i_data_valid),
        .dout_ready(i_data_ready),

        .wb_adr_o(wb_i_adr),
        .wb_dat_o(wb_i_dat_w),
        .wb_dat_i(wb_i_dat_r),
        .wb_we_o(wb_i_we),
        .wb_sel_o(wb_i_sel),
        .wb_stb_o(wb_i_stb),
        .wb_ack_i(wb_i_ack),
        .wb_err_i(wb_i_err),
        .wb_rty_i(wb_i_rty),
        .wb_cyc_o(wb_i_cyc)
    );

    wire [31:0] wb_d_adr;
    wire [127:0] wb_d_dat_r, wb_d_dat_w;
    wire wb_d_we;
    wire [15:0] wb_d_sel;
    wire wb_d_stb, wb_d_ack, wb_d_err, wb_d_rty, wb_d_cyc;

    wire volatile = ~(d_addr < 32'h10000 | d_addr >= 32'h02000000);

    cache #( 
        .CACHE_WIDTH(CACHE_WIDTH),
        .ADDR_WIDTH(32),
        .CACHE_DEPTH(DCACHE_DEPTH),
        .WORD_WIDTH(32),
        .ADDR_GRANULARITY(8)
    ) dcache(
        .clk(clk),
        .rst(rst),

        .addr(d_addr),
        .addr_volatile(volatile),
        .wr(d_wr),
        .din(d_dout),
        .addr_valid(d_addr_valid),
        .addr_ready(d_addr_ready),

        .dout(d_din),
        .dout_valid(d_data_valid),
        .dout_ready(d_data_ready),

        .wb_adr_o(wb_d_adr),
        .wb_dat_o(wb_d_dat_w),
        .wb_dat_i(wb_d_dat_r),
        .wb_we_o(wb_d_we),
        .wb_sel_o(wb_d_sel),
        .wb_stb_o(wb_d_stb),
        .wb_ack_i(wb_d_ack),
        .wb_err_i(wb_d_err),
        .wb_rty_i(wb_d_rty),
        .wb_cyc_o(wb_d_cyc)
    );

    wb_arbiter_2 #(CACHE_WIDTH, 32, CACHE_WIDTH/8) arb(
        .clk(clk),
        .rst(rst),

        .wbm0_adr_i(wb_d_adr),
        .wbm0_dat_i(wb_d_dat_w),
        .wbm0_dat_o(wb_d_dat_r),
        .wbm0_we_i(wb_d_we),
        .wbm0_sel_i(wb_d_sel),
        .wbm0_stb_i(wb_d_stb),
        .wbm0_ack_o(wb_d_ack),
        .wbm0_err_o(wb_d_err),
        .wbm0_rty_o(wb_d_rty),
        .wbm0_cyc_i(wb_d_cyc),

        .wbm1_adr_i(wb_i_adr),
        .wbm1_dat_i(wb_i_dat_w),
        .wbm1_dat_o(wb_i_dat_r),
        .wbm1_we_i(wb_i_we),
        .wbm1_sel_i(wb_i_sel),
        .wbm1_stb_i(wb_i_stb),
        .wbm1_ack_o(wb_i_ack),
        .wbm1_err_o(wb_i_err),
        .wbm1_rty_o(wb_i_rty),
        .wbm1_cyc_i(wb_i_cyc),

        .wbs_adr_o(wb_adr_o),
        .wbs_dat_i(wb_dat_i),
        .wbs_dat_o(wb_dat_o),
        .wbs_we_o(wb_we_o),
        .wbs_sel_o(wb_sel_o),
        .wbs_stb_o(wb_stb_o),
        .wbs_ack_i(wb_ack_i),
        .wbs_err_i(wb_err_i),
        .wbs_rty_i(wb_rty_i),
        .wbs_cyc_o(wb_cyc_o)
    );

endmodule