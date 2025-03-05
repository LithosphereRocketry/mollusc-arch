module platform(
        input rst,
        input clk,

        output [7:0] dport,
        output dport_valid,
        input dport_ready,

        output [31:0] haltcode,
        output halt_valid,
        input halt_ready
    );

    wire [31:0] i_addr, d_addr, d_dout;
    wire i_valid, i_ready, d_valid, d_ready, d_wr; 

    wire dport_sel = d_addr == 32'h01000000;
    wire halt_sel = d_addr == 32'h01001000;

    assign i_ready = 1;
    assign d_ready = dport_sel ? dport_ready :
                    halt_sel ? halt_ready : 1;

    assign dport = d_dout[7:0];
    assign haltcode = d_dout;

    assign dport_valid = d_valid & d_wr & dport_sel;
    assign halt_valid = d_valid & d_wr & halt_sel;

    reg [31:0] i_din, d_din;

    cpu_core _cpu_core(
        .clk(clk),
        .rst(rst),

        .i_addr(i_addr),
        .i_addr_valid(i_valid),
        .i_addr_ready(i_ready),

        .i_data(i_din),
        .i_data_valid(1'b1),
        .i_data_ready(),

        
        .d_addr(d_addr),
        .d_dout(d_dout),
        .d_wr(d_wr),
        .d_addr_valid(d_valid),
        .d_addr_ready(d_ready),

        .d_din(d_din),
        .d_data_valid(1'b1),
        .d_data_ready()
    );

    always @(posedge clk) begin
        if(d_addr < 32'h8000) begin
            if(d_wr) ram[d_addr[14:2]] <= d_dout;
            else d_din <= ram[d_addr[14:2]];
        end else if(d_addr <= 32'h10000) begin
            if(~d_wr) d_din <= rom[d_addr[14:2]];
        end else d_din <= 32'hxxxxxxxx;
        
        if(i_addr < 32'h8000) begin
            i_din <= ram[i_addr[14:2]];
        end else if(i_addr <= 32'h10000) begin
            i_din <= rom[i_addr[14:2]];
        end else i_din <= 32'hxxxxxxxx;
    end

    reg [31:0] rom [0:(1<<13)-1];
    initial $readmemh(`ROMPATH, rom);
    reg [31:0] ram [0:(1<<13)-1];
endmodule