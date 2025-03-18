`timescale 1ps/1ps
`include "assert.vh"

module tb_cache ();
    reg clk = 0;
    reg rst = 0;
    `timeout(clk, 1000);
    
    reg [15:0] addr;
    reg addr_volatile;
    reg wr = 0;
    reg [31:0] din;
    reg addr_valid = 0;
    wire addr_ready;

    wire [31:0] dout;
    wire dout_valid;
    reg dout_ready;
    

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
        .wr(wr),
        .din(din),
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

    task step; begin
        #1;
        clk = 1;
        #1;
        clk = 0;
    end endtask

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
    
    initial begin
        $dumpfile(`WAVEPATH);
        $dumpvars;

        rst = 1;
        step();
        rst = 0;
        while(~addr_ready) step();

        dout_ready = 1;
        wr = 1;
        din = 32'h12345678;
        addr_volatile = 0;
        addr = 16'h8760;
        addr_valid = 1;
        step();
        addr_valid = 0;
        while(~addr_ready) step();

        dout_ready = 1;
        wr = 1;
        din = 32'h87654321;
        addr_volatile = 0;
        addr = 16'h8764;
        addr_valid = 1;
        step();
        addr_valid = 0;
        while(~addr_ready) step();

        wr = 0;
        addr = 16'h8760;
        addr_valid = 1;
        step();
        addr_valid = 0;
        dout_ready = 0;
        while(~dout_valid) step();
        step();
        step();
        dout_ready = 1;
        `assert(dout, 32'h12345678);
        addr_valid = 1;
        addr = 16'h8764;
        step();
        `assert(dout, 32'h87654321);
        `assert(dout_valid, 1'b1);

        dout_ready = 1;
        wr = 1;
        din = 32'h77777777;
        addr_volatile = 0;
        addr = 16'h876C;
        addr_valid = 1;
        step();
        addr_valid = 0;
        while(~addr_ready) step();

        addr = 16'h8760;
        addr_valid = 1;
        wr = 0;
        step();
        addr_valid = 0;
        while(~dout_valid) step();
        `assert(dout, 32'h12345678);
        addr = 16'h876C;
        addr_valid = 1;
        step();
        addr_valid = 0;
        `assert(dout_valid, 1'b1);
        `assert(dout, 32'h77777777);

        addr = 16'h8760;
        addr_valid = 1;
        addr_volatile = 1;
        step();
        addr_valid = 0;
        addr_volatile = 0;
        `assert(dout_valid, 1'b0);
        while(~dout_valid) step();
        `assert(dout, 32'h12345678);
        
        repeat(5) step();
    end
endmodule