module pwm #(
        parameter WIDTH = 8
    ) (
        input clk,
        input [WIDTH-1:0] value,
        output signal
    );
    localparam MAX_COUNT = {WIDTH{1'b1}};

    reg [WIDTH-1:0] counter = {WIDTH{1'b0}};
    assign signal = (value > counter);

    always @(posedge clk) counter <= (counter == MAX_COUNT-1) ? 0 : counter+1;
endmodule