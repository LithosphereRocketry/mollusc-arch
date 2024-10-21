module clkdiv #(
        parameter DIVISOR = 256,
        parameter HIGHCOUNT = 1,
        localparam COUNT_WIDTH = $clog2(DIVISOR)
    ) (
        input clkin,
        output clkout
    );

    reg [COUNT_WIDTH-1:0] counter;
    assign clkout = (counter < HIGHCOUNT);

    always @(negedge clkin) counter <= (counter == DIVISOR-1) ? 0 : counter+1;

endmodule