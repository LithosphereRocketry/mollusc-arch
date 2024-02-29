`timescale 1ns/1ps

module charrom #(parameter ROMPATH = "build/charset.hex") (
        input [6:0] ascii,
        input [3:0] row,
        input [2:0] col,
        output pxval
    );

    reg [127:0] romcontents [127:0];

    initial $readmemh(ROMPATH, romcontents);

    assign pxval = romcontents[ascii][row*8 + col];
endmodule