module memcontrol (
        input clk,
        // Addressed by 32-bit word, not by byte
        // Misaligned reads must be handled in software
        input [29:0] addr_a,
        input [31:0] datain_a,
        input wr_a,
        output reg [31:0] dataout_a,
        
        input [29:0] addr_b,
        input [31:0] datain_b,
        input wr_b,
        output reg [31:0] dataout_b
    );

    // 2K x 32 (8KB) RAM
    // Later this will be turned into a cache hierarchy of some flavor using the
    // external DRAM, but the interface should be mostly the same
    reg [31:0] memory [2047:0];

    wire [31:0] test = memory[32'h00000015];

    `ifdef ROMPATH
        initial $readmemh(`ROMPATH, memory);
    `endif

    always @(posedge clk) begin
        if(wr_a) begin
            memory[addr_a[10:0]] <= datain_a;
            dataout_a <= 32'hxxxxxxxx;
        end else begin
            dataout_a <= memory[addr_a[10:0]];
        end

        if(wr_b) begin
            memory[addr_b[10:0]] <= datain_b;
            dataout_b <= 32'hxxxxxxxx;
        end else begin
            dataout_b <= memory[addr_b[10:0]];
        end
    end

endmodule