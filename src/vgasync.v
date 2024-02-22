`timescale 1ns/1ps
/*
VGA front/backporch counter

Default timing specs based on VESA 1280 x 1024 timings: 
tinyvga.com/vga-timing/1280x1024@60Hz
*/
module vgasync #(
        parameter W = 1280,
        parameter HFP = 48,
        parameter HSP = 112,
        parameter HBP = 248,

        parameter H = 1024,
        parameter VFP = 1,
        parameter VSP = 3,
        parameter VBP = 38,

        localparam TW = W + HFP + HSP + HBP,
        localparam TH = H + VFP + VSP + VBP,
        localparam X_WIDTH = $clog2(W),
        localparam Y_WIDTH = $clog2(H),
        localparam X_WIDTH_INT = $clog2(TW),
        localparam Y_WIDTH_INT = $clog2(TH)
    ) (
        input pxclk,
        output inframe,
        output [X_WIDTH-1:0] scanx,
        output [Y_WIDTH-1:0] scany,
        output hsync,
        output vsync
    );

    reg [X_WIDTH_INT-1:0] xcount;
    initial xcount = 0;
    reg [Y_WIDTH_INT-1:0] ycount;
    initial ycount = 0;

    assign hsync = xcount >= W + HFP && xcount < W + HFP + HSP;
    assign vsync = ycount >= H + VFP && ycount < H + VFP + VSP;
    assign inframe = xcount < W && ycount < H;
    assign scanx = inframe ? xcount[X_WIDTH-1:0] : {X_WIDTH{1'bx}};
    assign scany = inframe ? xcount[X_WIDTH-1:0] : {Y_WIDTH{1'bx}};

    always @(posedge pxclk) begin
        if(xcount < TW-1) xcount <= xcount + 1;
        else begin
            xcount <= 0;
            if(ycount < TH-1) ycount <= ycount + 1;
            else ycount <= 0;
        end
    end


endmodule