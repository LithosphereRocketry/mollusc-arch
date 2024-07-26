`timescale 1ns/1ps

module charrom #(parameter WIDTH = 1, parameter ROMPATH = "build/charset.hex") (
        input [6:0] ascii,
        input [3:0] row,
        input [(3-WIDTH):0] col,
        output [(WIDTH-1):0] pxval
    );

    reg [127:0] romcontents [127:0];

    initial $readmemh(ROMPATH, romcontents);

    wire [2:0] extcol = col << (WIDTH-1);
    assign pxval = romcontents[ascii][row*8 + extcol +: WIDTH];
endmodule