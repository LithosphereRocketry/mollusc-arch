module usbcdc(
        input clk48,
        input rst,

        // core -> tty
        input [7:0] tx_data,
        input tx_valid,
        output tx_ready,
        // tty -> core
        output [7:0] rx_data,
        output rx_valid,
        input rx_ready,

        inout usb_d_n,
        inout usb_d_p,
        output usb_pullup
    );

    // // Generate reset signal
    // reg [5:0] reset_cnt = 0;
    // wire usb_rst = ~reset_cnt[5];
    // always @(posedge clk48)
    //     reset_cnt <= reset_cnt + usb_rst;

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
        .reset      (rst),

        // pins
        .usb_p_tx(usb_p_tx),
        .usb_n_tx(usb_n_tx),
        .usb_p_rx(usb_p_rx),
        .usb_n_rx(usb_n_rx),
        .usb_tx_en(usb_tx_en),

        // me -> tty
        .uart_in_data( tx_data ),
        .uart_in_valid( tx_valid ),
        .uart_in_ready( tx_ready ),

        // tty -> me
        .uart_out_data( rx_data ),
        .uart_out_valid( rx_valid ),
        .uart_out_ready( rx_ready )
    );
    
    // USB Host Detect Pull Up
    assign usb_pullup = 1'b1;

    assign usb_p_rx = usb_tx_en ? 1'b1 : usb_p_in;
    assign usb_n_rx = usb_tx_en ? 1'b0 : usb_n_in;

    BB io_p( .I( usb_p_tx ), .T( !usb_tx_en ), .O( usb_p_in ), .B( usb_d_p ) );
    BB io_n( .I( usb_n_tx ), .T( !usb_tx_en ), .O( usb_n_in ), .B( usb_d_n ) );
endmodule