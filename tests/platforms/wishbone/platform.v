module platform(
        input rst,
        input clk,

        output [7:0] dport,
        output dport_valid,
        input dport_ready,

        output [31:0] haltcode,
        output halt_valid,
        input halt_ready
    );

    wire [31:0] wb_adr;
    wire [127:0] wb_dat_r, wb_dat_w;
    wire wb_we;
    wire [15:0] wb_sel;
    wire wb_stb, wb_ack, wb_cyc;

    cpu_wb #(
        .CACHE_WIDTH(128),
        .ICACHE_DEPTH(9),
        .DCACHE_DEPTH(9)
    ) cpu(
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
        .wb_cyc_o(wb_cyc)
    );

    wire [31:0] wb_narrow_adr;
    wire [31:0] wb_narrow_dat_r, wb_narrow_dat_w;
    wire wb_narrow_we;
    wire [3:0] wb_narrow_sel;
    wire wb_narrow_stb, wb_narrow_ack, wb_narrow_cyc;

    wb_adapter #(
        .ADDR_WIDTH(32),
        .WBM_DATA_WIDTH(128),
        .WBM_SELECT_WIDTH(16),
        .WBS_DATA_WIDTH(32),
        .WBS_SELECT_WIDTH(4)
    ) adapter(
        .clk(clk),
        .rst(rst),
        
        .wbm_adr_i(wb_adr),
        .wbm_dat_i(wb_dat_w),
        .wbm_dat_o(wb_dat_r),
        .wbm_we_i(wb_we),
        .wbm_sel_i(wb_sel),
        .wbm_stb_i(wb_stb),
        .wbm_ack_o(wb_ack),
        .wbm_err_o(),
        .wbm_rty_o(),
        .wbm_cyc_i(wb_cyc),

        .wbs_adr_o(wb_narrow_adr),
        .wbs_dat_o(wb_narrow_dat_w),
        .wbs_dat_i(wb_narrow_dat_r),
        .wbs_we_o(wb_narrow_we),
        .wbs_sel_o(wb_narrow_sel),
        .wbs_stb_o(wb_narrow_stb),
        .wbs_ack_i(wb_narrow_ack),
        .wbs_err_i(1'b0),
        .wbs_rty_i(1'b0),
        .wbs_cyc_o(wb_narrow_cyc)
    );

    wire [31:0] wb_ram_adr;
    wire [31:0] wb_ram_dat_r, wb_ram_dat_w;
    wire wb_ram_we;
    wire [3:0] wb_ram_sel;
    wire wb_ram_stb, wb_ram_ack, wb_ram_cyc;

    wire [31:0] wb_rom_adr;
    wire [31:0] wb_rom_dat_r, wb_rom_dat_w;
    wire wb_rom_we;
    wire [3:0] wb_rom_sel;
    wire wb_rom_stb, wb_rom_ack, wb_rom_cyc;

    wire [31:0] wb_io_adr;
    wire [31:0] wb_io_dat_r, wb_io_dat_w;
    wire wb_io_we;
    wire [3:0] wb_io_sel;
    wire wb_io_stb, wb_io_ack, wb_io_cyc;

    wire [31:0] wb_halt_adr;
    wire [31:0] wb_halt_dat_r, wb_halt_dat_w;
    wire wb_halt_we;
    wire [3:0] wb_halt_sel;
    wire wb_halt_stb, wb_halt_ack, wb_halt_cyc;

    wb_mux_4 #(32, 32) mux(
        .clk(clk),
        .rst(rst),

        .wbm_adr_i(wb_narrow_adr),
        .wbm_dat_i(wb_narrow_dat_w),
        .wbm_dat_o(wb_narrow_dat_r),
        .wbm_we_i(wb_narrow_we),
        .wbm_sel_i(wb_narrow_sel),
        .wbm_stb_i(wb_narrow_stb),
        .wbm_ack_o(wb_narrow_ack),
        .wbm_err_o(),
        .wbm_rty_o(),
        .wbm_cyc_i(wb_narrow_cyc),

        .wbs0_adr_o(wb_ram_adr),
        .wbs0_dat_o(wb_ram_dat_w),
        .wbs0_dat_i(wb_ram_dat_r),
        .wbs0_we_o(wb_ram_we),
        .wbs0_sel_o(wb_ram_sel),
        .wbs0_stb_o(wb_ram_stb),
        .wbs0_ack_i(wb_ram_ack),
        .wbs0_err_i(1'b0),
        .wbs0_rty_i(1'b0),
        .wbs0_cyc_o(wb_ram_cyc),

        .wbs0_addr(32'h00000000),
        .wbs0_addr_msk(~32'h00007FFF),

        .wbs1_adr_o(wb_rom_adr),
        .wbs1_dat_o(wb_rom_dat_w),
        .wbs1_dat_i(wb_rom_dat_r),
        .wbs1_we_o(wb_rom_we),
        .wbs1_sel_o(wb_rom_sel),
        .wbs1_stb_o(wb_rom_stb),
        .wbs1_ack_i(wb_rom_ack),
        .wbs1_err_i(1'b0),
        .wbs1_rty_i(1'b0),
        .wbs1_cyc_o(wb_rom_cyc),

        .wbs1_addr(32'h00008000),
        .wbs1_addr_msk(~32'h00007FFF),

        .wbs2_adr_o(wb_io_adr),
        .wbs2_dat_o(wb_io_dat_w),
        .wbs2_dat_i(wb_io_dat_r),
        .wbs2_we_o(wb_io_we),
        .wbs2_sel_o(wb_io_sel),
        .wbs2_stb_o(wb_io_stb),
        .wbs2_ack_i(wb_io_ack),
        .wbs2_err_i(1'b0),
        .wbs2_rty_i(1'b0),
        .wbs2_cyc_o(wb_io_cyc),

        .wbs2_addr(32'h01000000),
        .wbs2_addr_msk(~32'h00000007),

        .wbs3_adr_o(wb_halt_adr),
        .wbs3_dat_o(wb_halt_dat_w),
        .wbs3_dat_i(wb_halt_dat_r),
        .wbs3_we_o(wb_halt_we),
        .wbs3_sel_o(wb_halt_sel),
        .wbs3_stb_o(wb_halt_stb),
        .wbs3_ack_i(wb_halt_ack),
        .wbs3_err_i(1'b0),
        .wbs3_rty_i(1'b0),
        .wbs3_cyc_o(wb_halt_cyc),

        .wbs3_addr(32'h01001000),
        .wbs3_addr_msk(~32'h00000007)
    );

    wb_ram #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(15)
    ) ram(
        .clk(clk),
        .adr_i(wb_ram_adr[14:0]),
        .dat_i(wb_ram_dat_w),
        .dat_o(wb_ram_dat_r),
        .we_i(wb_ram_we),
        .sel_i(wb_ram_sel),
        .stb_i(wb_ram_stb),
        .ack_o(wb_ram_ack),
        .cyc_i(wb_ram_cyc)
    );

    wb_ram #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(15),
        .INIT_PATH(`ROMPATH)
    ) rom(
        .clk(clk),
        .adr_i(wb_rom_adr[14:0]),
        .dat_i(wb_rom_dat_w),
        .dat_o(wb_rom_dat_r),
        .we_i(1'b0),
        .sel_i(wb_rom_sel),
        .stb_i(wb_rom_stb),
        .ack_o(wb_rom_ack),
        .cyc_i(wb_rom_cyc)
    );

    wb_flow_port #(8) data_port (
        .clk(clk),
        .rst(rst),
        
        .adr_i(wb_io_adr[2]),
        .dat_o(wb_io_dat_r[7:0]),
        .dat_i(wb_io_dat_w[7:0]),
        .we_i(wb_io_we),
        .stb_i(wb_io_stb),
        .cyc_i(wb_io_cyc),
        .ack_o(wb_io_ack),

        .write_data(dport),
        .write_valid(dport_valid),
        .write_ready(dport_ready),

        .read_data(8'hxx),
        .read_valid(1'b0),
        .read_ready()
    );

    wb_flow_port #(32) halt_port (
        .clk(clk),
        .rst(rst),
        
        .adr_i(wb_halt_adr[2]),
        .dat_o(wb_halt_dat_r),
        .dat_i(wb_halt_dat_w),
        .we_i(wb_halt_we),
        .stb_i(wb_halt_stb),
        .cyc_i(wb_halt_cyc),
        .ack_o(wb_halt_ack),

        .write_data(haltcode),
        .write_valid(halt_valid),
        .write_ready(halt_ready),

        .read_data(32'hxxxxxxxx),
        .read_valid(1'b0),
        .read_ready()
    );
endmodule