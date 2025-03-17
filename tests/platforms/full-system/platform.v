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

    assign haltcode = 32'h0;

    system_core #(
        .CACHE_WIDTH(128),
        .ICACHE_DEPTH(7),
        .DCACHE_DEPTH(7),
        .ROM_SIZE(32768)
    ) core (
        .clk(clk),
        .ioclk(clk),
        .rst(rst),

        .led_r(halt_valid),
        .led_g(),
        .led_b(),

        // UART, core -> tty
        .uart_tx_data(dport),
        .uart_tx_valid(dport_valid),
        .uart_tx_ready(1'b1),
        // UART, tty -> core
        .uart_rx_data(8'hxx),
        .uart_rx_valid(1'b0),
        .uart_rx_ready()
    );
endmodule