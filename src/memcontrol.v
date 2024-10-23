module memcontrol #(
        parameter CACHE_WIDTH = 128,
        parameter CACHE_DEPTH = 9,
        parameter ADDR_WIDTH = 32,
        parameter WORD_WIDTH = ADDR_WIDTH,
        parameter ADDR_GRANULARITY = 8,

        localparam CACHE_LINE_DEPTH = $clog2(CACHE_WIDTH/ADDR_GRANULARITY),
        localparam WORD_DEPTH = $clog2(WORD_WIDTH/ADDR_GRANULARITY),
        localparam CACHE_TAG_WIDTH = ADDR_WIDTH - CACHE_DEPTH - CACHE_LINE_DEPTH
    ) (
        input clk,
        input rst,

        input valid_a,
        input [ADDR_WIDTH-1:0] addr_a,
        output [WORD_WIDTH-1:0] dataout_a,
        output ready_a,
        
        input valid_b,
        input [ADDR_WIDTH-1:0] addr_b,
        input [WORD_WIDTH-1:0] datain_b,
        input wr_b,
        output [WORD_WIDTH-1:0] dataout_b,
        output ready_b,

        // Bus interface to external memory
        output [ADDR_WIDTH-1:0] wb_adr_o,
        output [CACHE_WIDTH-1:0] wb_dat_o,
        input [CACHE_WIDTH-1:0] wb_dat_i,
        output wb_we_o,
        output [CACHE_WIDTH/ADDR_GRANULARITY - 1:0] wb_sel_o,
        output wb_stb_o,
        input wb_ack_i,
        input wb_err_i, // ignored
        input wb_rty_i, // ignored
        output wb_cyc_o
    );

    wire wb_arb_cyc;
    assign wb_cyc_o = wb_arb_cyc;
    // TODO: In the future this will be used for bus exclusivity

    // // Cache valid is a separate register so other accesses can force us to 
    // // re-fetch
    // reg [(1 << CACHE_DEPTH)-1:0] cache_valid;

    // Cache lines corresponding to incoming address request
    wire [CACHE_DEPTH-1:0] caddr_a = addr_a[CACHE_LINE_DEPTH +: CACHE_DEPTH];
    wire [CACHE_DEPTH-1:0] caddr_b = addr_b[CACHE_LINE_DEPTH +: CACHE_DEPTH];

    // Fetched tags from cache
    reg [CACHE_TAG_WIDTH-1:0] tag_a;
    reg [CACHE_TAG_WIDTH-1:0] tag_b;
    // Fetched data lines from cache
    reg [CACHE_WIDTH-1:0] rdata_a;
    reg [CACHE_WIDTH-1:0] rdata_b;
    // Fetched valid bits from cache
    wire cvalid_a;
    wire cvalid_b;
    wire [WORD_WIDTH-1:0] cached_word_a = rdata_a[
            sync_addr_a[CACHE_LINE_DEPTH-1:WORD_DEPTH] * WORD_WIDTH +: WORD_WIDTH];
    wire [1:0] line_index_b = sync_addr_b[CACHE_LINE_DEPTH-1:WORD_DEPTH];
    wire [WORD_WIDTH-1:0] cached_word_b = rdata_b[line_index_b * WORD_WIDTH +: WORD_WIDTH];
    

    // Address that the fetched line came from
    reg [ADDR_WIDTH-1:0] sync_addr_a;
    reg [ADDR_WIDTH-1:0] sync_addr_b;
    // Cache line addresses that were fetched
    wire [CACHE_DEPTH-1:0] sync_caddr_a = sync_addr_a[CACHE_LINE_DEPTH +: CACHE_DEPTH];
    wire [CACHE_DEPTH-1:0] sync_caddr_b = sync_addr_b[CACHE_LINE_DEPTH +: CACHE_DEPTH];
    // What tag we wanted to see from this fetch
    wire [CACHE_TAG_WIDTH-1:0] req_tag_a = sync_addr_a[ADDR_WIDTH-1:ADDR_WIDTH - CACHE_TAG_WIDTH];
    wire [CACHE_TAG_WIDTH-1:0] req_tag_b = sync_addr_b[ADDR_WIDTH-1:ADDR_WIDTH - CACHE_TAG_WIDTH];
    // Whether the line we just fetched was the correct one
    wire rdata_correct_a = cvalid_a & tag_a == req_tag_a;
    wire rdata_correct_b = cvalid_b & tag_b == req_tag_b;
    // What the data we just fetched actually wants to do
    reg a_is_read, b_is_read, b_is_write;
    reg [WORD_WIDTH-1:0] sync_wdata_b;

    reg fetched_valid_a;
    reg [WORD_WIDTH-1:0] fetched_a;
    assign dataout_a = fetched_valid_a ? fetched_a : cached_word_a; 

    reg fetched_valid_b;
    reg [WORD_WIDTH-1:0] fetched_b;
    assign dataout_b = fetched_valid_b ? fetched_b : cached_word_b;

    reg [ADDR_WIDTH-1:0] wba_adr, wbb_adr;
    reg [CACHE_WIDTH-1:0] wbb_dat_w;
    wire [CACHE_WIDTH-1:0] wba_dat_r, wbb_dat_r;
    reg wbb_we;
    reg [CACHE_WIDTH/ADDR_GRANULARITY-1:0] wba_sel, wbb_sel;
    reg wba_stb, wbb_stb;
    wire wba_ack, wbb_ack;
    wire wba_err, wbb_err, wba_rty, wbb_rty; // TODO: handle err/rty

    reg [WORD_DEPTH-1:0] wba_word_pos, wbb_word_pos;

    wb_arbiter_2 #(CACHE_WIDTH, ADDR_WIDTH, CACHE_WIDTH/ADDR_GRANULARITY) arb(
        .clk(clk),
        .rst(rst),

        .wbm0_adr_i(wbb_adr),
        .wbm0_dat_i(wbb_dat_w),
        .wbm0_dat_o(wbb_dat_r),
        .wbm0_we_i(wbb_we),
        .wbm0_sel_i(wbb_sel),
        .wbm0_stb_i(wbb_stb),
        .wbm0_ack_o(wbb_ack),
        .wbm0_err_o(wbb_err),
        .wbm0_rty_o(wbb_rty),
        .wbm0_cyc_i(wbb_stb),

        .wbm1_adr_i(wba_adr),
        .wbm1_dat_i({CACHE_WIDTH{1'bx}}),
        .wbm1_dat_o(wba_dat_r),
        .wbm1_we_i(0),
        .wbm1_sel_i(wba_sel),
        .wbm1_stb_i(wba_stb),
        .wbm1_ack_o(wba_ack),
        .wbm1_err_o(wba_err),
        .wbm1_rty_o(wba_rty),
        .wbm1_cyc_i(wba_stb),

        .wbs_adr_o(wb_adr_o),
        .wbs_dat_i(wb_dat_i),
        .wbs_dat_o(wb_dat_o),
        .wbs_we_o(wb_we_o),
        .wbs_sel_o(wb_sel_o),
        .wbs_stb_o(wb_stb_o),
        .wbs_ack_i(wb_ack_i),
        .wbs_err_i(wb_err_i),
        .wbs_rty_i(wb_rty_i),
        .wbs_cyc_o(wb_arb_cyc)
    );

    wire busfetch_done_a = wba_stb & wba_ack;
    wire busfetch_done_b = wbb_stb & wbb_ack & ~wbb_we;
    wire buswrite_done_b = wbb_stb & wbb_ack & wbb_we;

    wire a_wants_busfetch = a_is_read & ~rdata_correct_a;
    wire b_wants_busfetch = b_is_read & ~rdata_correct_b;


    // Initial cache scrubbing
    // Since valid bits live in BRAM, we have to manually clear one row at a
    // time
    reg [CACHE_DEPTH-1:0] scrub_addr;
    reg scrub_ready;

    // Writeback logic
    // Originally this was inside the always block, but yosys isn't quite smart
    // enough to infer the needed muxes to implement it there, so I'm doing it
    // explicitly instead

    // A handles instruction fetch and scrubbing
    wire [CACHE_TAG_WIDTH+CACHE_WIDTH:0] a_scrub_data = {1'b0, {CACHE_TAG_WIDTH+CACHE_WIDTH{1'bx}}};
    wire [CACHE_TAG_WIDTH+CACHE_WIDTH:0] a_fetch_data =
            {1'b1, wba_adr[ADDR_WIDTH-1:CACHE_DEPTH+CACHE_LINE_DEPTH], wba_dat_r};
    wire [CACHE_TAG_WIDTH+CACHE_WIDTH:0] a_write_data =
            ~scrub_ready ? a_scrub_data : a_fetch_data;

    wire [CACHE_DEPTH-1:0] a_write_addr = wba_adr[CACHE_LINE_DEPTH +: CACHE_DEPTH];
    wire [CACHE_DEPTH-1:0] a_cache_addr = ~scrub_ready ? scrub_addr
            : busfetch_done_a ? a_write_addr : caddr_a;
    wire a_writes_cache = busfetch_done_a | ~scrub_ready;

    // B handles data read and write
    wire b_uses_writethrough = b_is_write & rdata_correct_b;
    wire [CACHE_WIDTH-1:0] b_writethrough_line = (
        // Mask out the word we want to change
        rdata_b & 
        ~({{CACHE_WIDTH-WORD_WIDTH{1'b0}}, {WORD_WIDTH{1'b1}}} << WORD_WIDTH*line_index_b)
    ) | (
        // Insert the word
        {{CACHE_WIDTH-WORD_WIDTH{1'b0}}, sync_wdata_b} << WORD_WIDTH*line_index_b
    );
    wire [CACHE_TAG_WIDTH+CACHE_WIDTH:0] b_writethrough_data =
            { cvalid_b, tag_b, b_writethrough_line };
    wire [CACHE_TAG_WIDTH+CACHE_WIDTH:0] b_fetch_data = 
            { 1'b1, wbb_adr[ADDR_WIDTH-1:CACHE_DEPTH+CACHE_LINE_DEPTH], wbb_dat_r };
    wire [CACHE_TAG_WIDTH+CACHE_WIDTH:0] b_write_data = 
            b_uses_writethrough ? b_writethrough_data : b_fetch_data;

    wire [CACHE_DEPTH-1:0] b_write_addr = b_uses_writethrough ? sync_caddr_b
                                     : wbb_adr[CACHE_LINE_DEPTH +: CACHE_DEPTH];
    wire [CACHE_DEPTH-1:0] b_cache_addr = b_writes_cache ? b_write_addr : caddr_b;
    wire b_writes_cache = b_uses_writethrough | busfetch_done_b;

    assign ready_a = scrub_ready & ~wba_stb & ~a_wants_busfetch;
    assign ready_b = scrub_ready & (wr_b ? ~wbb_stb | buswrite_done_b
                                         : ~wbb_stb & ~b_wants_busfetch);

    dp_ram #(
        .D_WIDTH(CACHE_TAG_WIDTH+CACHE_WIDTH+1),
        .A_WIDTH(CACHE_DEPTH)
    ) cache(
        .clk(clk),
        
        .addr_a(a_cache_addr),
        .wdata_a(a_write_data),
        .wr_a(a_writes_cache),
        .rdata_a({cvalid_a, tag_a, rdata_a}),

        .addr_b(b_cache_addr),
        .wdata_b(b_write_data),
        .wr_b(b_writes_cache),
        .rdata_b({cvalid_b, tag_b, rdata_b})
    );

    task reset;
        begin
            /* verilator lint_off INITIALDLY */
            a_is_read <= 0;
            b_is_read <= 0;
            b_is_write <= 0;
            fetched_valid_a <= 0;
            fetched_valid_b <= 0;
            scrub_addr <= 0;
            scrub_ready <= 0;
            /* lint_on */
        end
    endtask

    initial reset();

    always @(posedge clk) begin
        if(rst) reset();
        else if(~scrub_ready) begin
            scrub_ready <= (scrub_addr == {CACHE_DEPTH{1'b1}});
            scrub_addr <= scrub_addr + 1;
        end else begin

            if(a_wants_busfetch) begin
                wba_stb <= 1'b1;
                wba_adr <= {sync_addr_a[ADDR_WIDTH-1:CACHE_LINE_DEPTH], {CACHE_LINE_DEPTH{1'b0}}};
                wba_sel <= {(CACHE_WIDTH/ADDR_GRANULARITY){1'b1}};
                wba_word_pos <= sync_addr_a[CACHE_LINE_DEPTH-1:WORD_DEPTH];
            end

            if(b_wants_busfetch) begin
                wbb_stb <= 1'b1;
                wbb_we <= 1'b0;
                wbb_adr <= {sync_addr_b[ADDR_WIDTH-1:CACHE_LINE_DEPTH], {CACHE_LINE_DEPTH{1'b0}}};
                wbb_dat_w <= {CACHE_WIDTH{1'bx}};
                wbb_sel <= {(CACHE_WIDTH/ADDR_GRANULARITY){1'b1}};
                wbb_word_pos <= sync_addr_b[CACHE_LINE_DEPTH-1:WORD_DEPTH];
            end

            fetched_valid_a <= 0;
            fetched_valid_b <= 0;

            if(busfetch_done_a) begin
                wba_stb <= 1'b0;
                wba_adr <= {ADDR_WIDTH{1'bx}};

                fetched_a <= wba_dat_r[wba_word_pos*WORD_WIDTH +: WORD_WIDTH];
                fetched_valid_a <= 1;
            end

            if(busfetch_done_b) begin
                wbb_stb <= 1'b0;
                wbb_we <= 1'bx;
                wbb_adr <= {ADDR_WIDTH{1'bx}};

                fetched_b <= wbb_dat_r[wbb_word_pos*WORD_WIDTH +: WORD_WIDTH];
                fetched_valid_b <= 1;
            end

            if(buswrite_done_b) begin
                wbb_stb <= 1'b0;
                wbb_we <= 1'bx;
                wbb_adr <= {ADDR_WIDTH{1'bx}};
            end
                
            if(~busfetch_done_a) begin
                sync_addr_a <= addr_a;
                a_is_read <= ready_a & valid_a;
            end

            if(b_uses_writethrough) b_is_write <= 0;
            if(~b_writes_cache) begin
                sync_addr_b <= addr_b;
                b_is_read <= ready_b & valid_b & ~wr_b;
                b_is_write <= ready_b & valid_b & wr_b;
                sync_wdata_b <= datain_b;
            end

            if(ready_b & valid_b & wr_b) begin
                wbb_stb <= 1'b1;
                wbb_we <= 1'b1;
                wbb_adr <= {addr_b[ADDR_WIDTH-1:CACHE_LINE_DEPTH], {CACHE_LINE_DEPTH{1'b0}}};

                wbb_sel <= {(CACHE_WIDTH/ADDR_GRANULARITY){1'b0}};
                wbb_sel[WORD_WIDTH/ADDR_GRANULARITY * addr_b[CACHE_LINE_DEPTH-1:WORD_DEPTH]
                        +: WORD_WIDTH/ADDR_GRANULARITY] <= {(WORD_WIDTH/ADDR_GRANULARITY){1'b1}};

                wbb_dat_w <= {CACHE_WIDTH{1'bx}};
                wbb_dat_w[WORD_WIDTH * addr_b[CACHE_LINE_DEPTH-1:WORD_DEPTH]
                        +: WORD_WIDTH] <= datain_b;
                
            end
        end
    end
endmodule