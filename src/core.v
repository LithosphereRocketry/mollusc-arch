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

        output [13:0] vga_waddr,
        output [7:0] vga_wdata,
        output vga_wr_en
    );

    assign uart_tx_data = uart_rx_data;
    assign uart_tx_valid = uart_rx_valid;
    assign uart_rx_ready = uart_tx_ready;

    reg [7:0] textcol;
    reg [5:0] textrow;
    initial textcol = 8'd0;
    initial textrow = 6'd0;
    always @(posedge clk48) begin
        if(vga_wr_en) begin
            textcol <= textcol >= 159 ? 0 : textcol + 8'd1;
            textrow <= textcol >= 159 ? textrow + 8'd1 : textrow;
        end
    end
    assign vga_wr_en = uart_tx_ready && uart_tx_valid;
    assign vga_waddr = {textrow, textcol};
    assign vga_wdata = uart_rx_data;
endmodule