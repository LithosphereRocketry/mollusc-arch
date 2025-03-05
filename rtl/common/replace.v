module replace #(
        parameter WIDTH = 32,
        parameter GRANULARITY = 8,

        localparam ADDR_WIDTH = $clog2(WIDTH) - $clog2(GRANULARITY)
    ) (
        input [WIDTH-1:0] din,
        input [ADDR_WIDTH-1:0] addr,
        input [GRANULARITY-1:0] insert,
        output [WIDTH-1:0] dout
    );

    reg [WIDTH-1:0] tmp; // combinational
    always @* begin
        tmp = din;
        tmp[addr*GRANULARITY +: GRANULARITY] = insert;
    end

    assign dout = tmp;

endmodule