/*
Read-only cache

Takes advantage of ECP5 pseudo-dual-port mode
*/

module cache #(
        parameter CACHE_WIDTH = 128,
        parameter ADDR_WIDTH = 32,
        parameter CACHE_DEPTH = 9,
        parameter WORD_WIDTH = 32,
        parameter ADDR_GRANULARITY = 8,

        localparam CACHE_LINE_DEPTH = $clog2(CACHE_WIDTH/ADDR_GRANULARITY),
        localparam WORD_DEPTH = $clog2(WORD_WIDTH/ADDR_GRANULARITY),
        localparam CACHE_TAG_WIDTH = ADDR_WIDTH - CACHE_DEPTH - CACHE_LINE_DEPTH,
        localparam CACHE_LINES = (1 << CACHE_DEPTH),
        localparam IN_LINE_ADDR_WIDTH = $clog2(CACHE_WIDTH/WORD_WIDTH)        
    ) (
        input clk,
        input rst,

        input [ADDR_WIDTH-1:0] addr,
        input addr_volatile,
        input wr,
        input [WORD_WIDTH-1:0] din,
        input addr_valid,
        output addr_ready,

        output [WORD_WIDTH-1:0] dout,
        output dout_valid,
        input dout_ready,

        // Bus interface to external memory
        output [ADDR_WIDTH-1:0] wb_adr_o,
        output [CACHE_WIDTH-1:0] wb_dat_o,
        input [CACHE_WIDTH-1:0] wb_dat_i,
        output wb_we_o,
        output [CACHE_WIDTH/ADDR_GRANULARITY - 1:0] wb_sel_o,
        output reg wb_stb_o,
        input wb_ack_i,
        input wb_err_i, // ignored
        input wb_rty_i, // ignored
        output wb_cyc_o
    );

    reg [CACHE_DEPTH-1:0] scrub_addr;
    reg scrub_ready;
    reg [CACHE_TAG_WIDTH:0] cache_tags [0:CACHE_LINES-1];
    reg [CACHE_WIDTH-1:0] cache_data [0:CACHE_LINES-1];

    wire [CACHE_DEPTH-1:0] caddr = addr[CACHE_LINE_DEPTH +: CACHE_DEPTH];
    reg [ADDR_WIDTH-1:0] sync_addr;
    reg sync_volatile;
    reg sync_wr;
    reg [WORD_WIDTH-1:0] sync_din;
    wire [CACHE_DEPTH-1:0] sync_caddr;
    wire [CACHE_TAG_WIDTH-1:0] req_tag;
    wire [IN_LINE_ADDR_WIDTH-1:0] in_line_addr;
    assign {req_tag, sync_caddr, in_line_addr} = sync_addr[ADDR_WIDTH-1:WORD_DEPTH];

    replace #(CACHE_WIDTH, WORD_WIDTH) repl_wdata(
        .din({CACHE_WIDTH{1'bx}}),
        .addr(in_line_addr),
        .insert(sync_din),
        .dout(wb_dat_o)
    );

    wire [CACHE_WIDTH/ADDR_GRANULARITY - 1:0] word_sel;
    replace #(CACHE_WIDTH/ADDR_GRANULARITY, WORD_WIDTH/ADDR_GRANULARITY) repl_wsel(
        .din({CACHE_WIDTH/ADDR_GRANULARITY{1'b0}}),
        .addr(in_line_addr),
        .insert({WORD_WIDTH/ADDR_GRANULARITY{1'b1}}),
        .dout(word_sel)
    );

    assign wb_sel_o = (wb_we_o | sync_volatile) ? word_sel : {CACHE_WIDTH/ADDR_GRANULARITY{1'b1}};

    reg line_full;
    reg cvalid;
    reg [CACHE_TAG_WIDTH-1:0] tag;
    reg [CACHE_WIDTH-1:0] cache_line;

    wire cache_correct = cvalid & tag == req_tag & ~sync_volatile;

    wire [WORD_WIDTH-1:0] cache_word = cache_line[in_line_addr*WORD_WIDTH +: WORD_WIDTH];
    reg [WORD_WIDTH-1:0] fetch_word;
    reg fetch_word_fresh;

    assign dout = line_full ? cache_word : fetch_word;
    assign dout_valid = scrub_ready & ~sync_wr & (line_full ? cache_correct : fetch_word_fresh);

    wire [CACHE_WIDTH-1:0] cache_update;
    replace #(CACHE_WIDTH, WORD_WIDTH) repl_update(
        .din(cache_line),
        .addr(in_line_addr), // assuming the tag is smaller than the address
        .insert(sync_din),
        .dout(cache_update)
    );

    assign wb_cyc_o = wb_stb_o;
    assign wb_we_o = sync_wr;
    assign wb_adr_o = {req_tag, sync_caddr, {CACHE_LINE_DEPTH{1'b0}}};

    task reset; begin
        scrub_addr <= 0;
        scrub_ready <= 0;
        wb_stb_o <= 0;
        line_full <= 0;
        sync_wr <= 0;
        fetch_word_fresh <= 0;
    end endtask
    initial reset();

    assign addr_ready = scrub_ready & (~line_full | (cache_correct & ~sync_wr));

    always @(posedge clk) if(rst) reset(); else begin
        if(dout_ready & dout_valid & ~line_full) fetch_word_fresh <= 0; 

        if(~scrub_ready) begin
            scrub_ready <= (scrub_addr == {CACHE_DEPTH{1'b1}});
            scrub_addr <= scrub_addr + 1;
            cache_tags[scrub_addr] <= {1'b0, {CACHE_TAG_WIDTH{1'bx}}};
        end else begin
            if(addr_valid & addr_ready) begin
                cache_line <= cache_data[caddr];
                {cvalid, tag} <= cache_tags[caddr];
                sync_addr <= addr;
                sync_volatile <= addr_volatile;
                sync_wr <= wr;
                sync_din <= din;
                line_full <= 1;
            end else begin
                // Time to start a write
                if(line_full & sync_wr & ~wb_stb_o) begin
                    wb_stb_o <= 1;
                end

                // Time to start a read
                if(line_full & ~sync_wr & ~wb_stb_o & ~cache_correct) begin
                    wb_stb_o <= 1;
                end

                // Time to finish a transaction
                if(wb_stb_o & wb_ack_i) begin
                    wb_stb_o <= 0;
                    line_full <= 0;
                    if(~wb_we_o) begin
                        if(~sync_volatile) begin
                            cache_data[sync_caddr] <= wb_dat_i;
                            cache_tags[sync_caddr] <= {1'b1, req_tag};
                        end 
                        fetch_word <= wb_dat_i[in_line_addr*WORD_WIDTH +: WORD_WIDTH];
                        fetch_word_fresh <= 1;
                    end else if(cache_correct) begin
                        cache_data[sync_caddr] <= cache_update;
                    end
                end
            end
        end
    end
endmodule