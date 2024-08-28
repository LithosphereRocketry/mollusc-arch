module dp_ram #(
        parameter D_WIDTH = 32,
        parameter A_WIDTH = 12,
        parameter FPATH = ""
    ) (
        input clk,

        input [A_WIDTH-1:0] addr_a,
        input [D_WIDTH-1:0] wdata_a,
        input wr_a,
        output reg [D_WIDTH-1:0] rdata_a,

        input [A_WIDTH-1:0] addr_b,
        input [D_WIDTH-1:0] wdata_b,
        input wr_b,
        output reg [D_WIDTH-1:0] rdata_b

    );

    reg [D_WIDTH-1:0] memory [((1 << A_WIDTH)-1):0];

    initial if(FPATH != "") $readmemh(FPATH, memory);

    always @(posedge clk) begin
        if(wr_a) begin
            memory[addr_a] <= wdata_a;
            rdata_a <= {D_WIDTH{1'bx}};
        end else begin
            rdata_a <= memory[addr_a];
        end

        if(wr_b) begin
            memory[addr_b] <= wdata_b;
            rdata_b <= {D_WIDTH{1'bx}};
        end else begin
            rdata_b <= memory[addr_b];
        end
    end

endmodule