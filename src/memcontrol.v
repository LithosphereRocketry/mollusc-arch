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

    `ifndef ROMPATH
        `define ROMPATH ""
    `endif

    dp_ram #(32, 11, `ROMPATH) mem(
        .clk(clk),
        
        .addr_a(addr_a[10:0]),
        .wdata_a(datain_a),
        .wr_a(wr_a),
        .rdata_a(dataout_a),

        .addr_b(addr_b[10:0]),
        .wdata_b(datain_b),
        .wr_b(wr_b),
        .rdata_b(dataout_b)
    );
endmodule