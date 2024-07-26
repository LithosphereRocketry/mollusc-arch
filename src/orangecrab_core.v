`timescale 1ns/1ps

module orangecrab_core(
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

        input usr_btn,
        input hbb_sw
    );

    orangecrab_reset reset_instance(
		.clk(clk48),
		.do_reset(~usr_btn),
		.nreset_out(rst_n)
	);

    // Generate reset signal
    reg [5:0] reset_cnt = 0;
    wire usb_rst = ~reset_cnt[5];
    always @(posedge clk48)
        reset_cnt <= reset_cnt + usb_rst;

    wire [7:0] uart_d;
    wire uart_ready;
    wire uart_valid;

    wire usb_p_in;
    wire usb_n_in;

    wire usb_p_tx;
    wire usb_n_tx;
    wire usb_p_rx;
    wire usb_n_rx;
    wire usb_tx_en;

    // usb uart - this instanciates the entire USB device.
    usb_uart_core uart (
        .clk_48mhz  (clk48),
        .reset      (usb_rst),

        // pins
        .usb_p_tx(usb_p_tx),
        .usb_n_tx(usb_n_tx),
        .usb_p_rx(usb_p_rx),
        .usb_n_rx(usb_n_rx),
        .usb_tx_en(usb_tx_en),

        // me -> tty
        // .uart_in_data( uart_d ),
        // .uart_in_valid( uart_valid ),
        // .uart_in_ready( uart_ready ),

        // tty -> me
        .uart_out_data( uart_d ),
        .uart_out_valid( uart_valid ),
        .uart_out_ready( uart_ready  )
    );
    assign uart_ready = 1'b1;

    // USB Host Detect Pull Up
    assign usb_pullup = 1'b1;

    assign usb_p_rx = usb_tx_en ? 1'b1 : usb_p_in;
    assign usb_n_rx = usb_tx_en ? 1'b0 : usb_n_in;

    BB io_p( .I( usb_p_tx ), .T( !usb_tx_en ), .O( usb_p_in ), .B( usb_d_p ) );
    BB io_n( .I( usb_n_tx ), .T( !usb_tx_en ), .O( usb_n_in ), .B( usb_d_n ) );

    wire pxclk;
    pll_108 pll(
        .clkin(clk48),
        .clkout0(pxclk),
        .locked(locked)
    );

    wire [10:0] xscan;
    wire [9:0] yscan;
    wire inframe;

    vgasync #(8) vga(
        .pxclk(pxclk),
        .inframe(inframe),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .scanx(xscan),
        .scany(yscan)
    );

    // reg [7:0] textbuf [256 - 1 : 0];
    reg [7:0] textbuf [64*256 - 1 : 0];
    // initial $readmemh("build/myst.hex", textbuf);
    initial textbuf[64*256 - 1 : 0] = " ";

    reg [7:0] textcol;
    reg [5:0] textrow;
    initial textcol = 8'd0;
    initial textrow = 6'd0;
    always @(posedge clk48) begin
        if(uart_valid) begin
            textbuf[{textrow, textcol}] <= uart_d;
            textcol <= textcol >= 159 ? 0 : textcol + 8'd1;
            textrow <= textcol >= 159 ? textrow + 8'd1 : textrow;
        end
    end

    // always @(posedge clk48) 

    reg [7:0] charout;
    wire [7:0] nextline;
    // wire pxout;
    charrom #(8) rom(
        .ascii(charout),
        .row(yscan[3:0]),
        .pxval(nextline)
    );

    reg [7:0] lineout;
    always @(negedge xscan[2]) begin
        lineout <= nextline;
        charout <= textbuf[{yscan[9:4], xscan[10:3]}];
    end
    reg pxout;
    always @(negedge pxclk) pxout <= lineout[xscan[2:0]];
    assign {vga_red, vga_green, vga_blue} = {8{inframe & pxout}};
endmodule