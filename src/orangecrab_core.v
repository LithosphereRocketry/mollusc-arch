module orangecrab_core(
        input clk48,
        
        inout usb_d_p,
        inout usb_d_n,
        output usb_pullup,

        output rst_n,
        input usr_btn,

        output rgb_led0_r,
        output rgb_led0_g,
        output rgb_led0_b
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

    usb_uart uart(
        .clk_48mhz(clk48),
        .reset(usb_rst),

        .pin_usb_n(usb_d_n),
        .pin_usb_p(usb_d_p),

        // uart pipeline in
        .uart_in_data( uart_d ),
        .uart_in_valid( uart_valid ),
        .uart_in_ready( uart_ready ),

        .uart_out_data( uart_d ),
        .uart_out_valid( uart_valid ),
        .uart_out_ready( uart_ready )
    );
    assign usb_pullup = 1'b1;
    assign rgb_led0_r = 1'b1;
    assign rgb_led0_g = ~uart_valid;
    assign rgb_led0_b = 1'b1;

endmodule