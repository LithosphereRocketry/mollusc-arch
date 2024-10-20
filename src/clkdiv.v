module clkdiv #(
        parameter DIVISOR = 256,
        localparam COUNT_WIDTH = $clog2(DIVISOR-1)
    ) (
        input clkin,
        output clkout
    );

    reg [COUNT_WIDTH-1:0] counter;
    assign clkout = clkin & (counter == {COUNT_WIDTH{1'b0}});

    always @(negedge clkin) counter <= (counter == DIVISOR-1) ? 0 : counter+1;

endmodule