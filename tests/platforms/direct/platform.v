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
    wire d_wr; 

    wire i_addr_ready, i_addr_valid, d_addr_ready, d_addr_valid;
    reg i_data_valid = 0, d_data_valid = 0;
    wire i_data_ready, d_data_ready;

    wire dport_sel = d_addr == 32'h01000000;
    wire halt_sel = d_addr == 32'h01001000;

    // for now, we know the TB never stalls, so ignore it
    // wire bus_ready = dport_sel ? dport_ready :
    //                 halt_sel ? halt_ready : 1;

    assign dport_valid = dport_sel & d_addr_ready & d_addr_valid;
    assign halt_valid = halt_sel & d_addr_ready & d_addr_valid;

    assign dport = d_dout[7:0];
    assign haltcode = d_dout;

    reg [31:0] i_din, d_din;

    assign i_addr_ready = ~i_data_valid | i_data_ready;
    assign d_addr_ready = ~d_data_valid | d_data_ready;

    cpu_core _cpu_core(
        .clk(clk),
        .rst(rst),

        .i_addr(i_addr),
        .i_addr_valid(i_addr_valid),
        .i_addr_ready(i_addr_ready),

        .i_data(i_din),
        .i_data_valid(i_data_valid),
        .i_data_ready(i_data_ready),

        
        .d_addr(d_addr),
        .d_dout(d_dout),
        .d_wr(d_wr),
        .d_addr_valid(d_addr_valid),
        .d_addr_ready(d_addr_ready),

        .d_din(d_din),
        .d_data_valid(d_data_valid),
        .d_data_ready(d_data_ready)
    );

    reg [31:0] rom [0:(1<<13)-1];
    initial $readmemh(`ROMPATH, rom);
    reg [31:0] ram [0:(1<<13)-1];

    always @(posedge clk) begin
        if(i_addr_valid & i_addr_ready) begin
            i_data_valid <= 1'b1;
            if(i_addr < 32'h8000) begin
                i_din <= ram[i_addr[14:2]];
            end else if(i_addr < 32'h10000) begin
                i_din <= rom[i_addr[14:2]];
            end else i_din <= 32'hxxxxxxxx;
        end else if(i_data_ready) begin
            i_data_valid <= 1'b0;
            i_din <= 32'hxxxxxxxx;
        end

        if(d_addr_valid & d_addr_ready) begin
            d_data_valid <= 1'b1;
            if(d_addr < 32'h8000) begin
                if(d_wr) ram[d_addr[14:2]] <= d_dout;
                else d_din <= ram[d_addr[14:2]];
            end else if(d_addr < 32'h10000) begin
                if(~d_wr) d_din <= rom[d_addr[14:2]];
                else d_din <= 32'hxxxxxxxx;
            end else d_din <= 32'hxxxxxxxx;
        end else if(d_data_ready) begin
            d_data_valid <= 1'b0;
            d_din <= 32'hxxxxxxxx;
        end
    end
endmodule