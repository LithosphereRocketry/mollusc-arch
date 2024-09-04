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

        input valid_a,
        input [ADDR_WIDTH-1:0] addr_a,
        output [WORD_WIDTH-1:0] dataout_a,
        output ready_a,
        
        input valid_b,
        input [ADDR_WIDTH-1:0] addr_b,
        input [WORD_WIDTH-1:0] datain_b,
        input wr_b,
        output wr_ready_b,
        output [WORD_WIDTH-1:0] dataout_b,
        output ready_b,

        // Bus interface to external memory
        output reg [ADDR_WIDTH-1:0] wb_adr_o,
        output reg [CACHE_WIDTH-1:0] wb_dat_o,
        input [CACHE_WIDTH-1:0] wb_dat_i,
        output reg wb_we_o,
        output reg [CACHE_WIDTH/ADDR_GRANULARITY - 1:0] wb_sel_o,
        output reg wb_stb_o,
        input wb_ack_i,
        input wb_err_i, // ignored
        input wb_rty_i, // ignored
        output wb_cyc_o
    );

    assign wb_cyc_o = wb_stb_o;

    reg [CACHE_TAG_WIDTH-1:0] tag_a;
    reg [CACHE_WIDTH-1:0] rdata_a;
    reg [CACHE_TAG_WIDTH-1:0] tag_b;
    reg [CACHE_WIDTH-1:0] rdata_b;

    reg [(1 << CACHE_DEPTH)-1:0] cache_valid = {(1 << CACHE_DEPTH){1'b0}};
    reg [CACHE_TAG_WIDTH + CACHE_WIDTH - 1:0] cache [(1 << CACHE_DEPTH)-1:0];

    reg cready_a = 0;
    reg cready_b = 0;

    // Cache inputs
    wire [CACHE_DEPTH-1:0] caddr_a = addr_a[CACHE_LINE_DEPTH +: CACHE_DEPTH];
    wire [CACHE_DEPTH-1:0] caddr_b = addr_b[CACHE_LINE_DEPTH +: CACHE_DEPTH];

    reg sync_is_read_a = 0;
    reg sync_is_read_b = 0;
    reg [ADDR_WIDTH-1:0] sync_addr_a;
    reg [ADDR_WIDTH-1:0] sync_addr_b;
    wire [CACHE_DEPTH-1:0] sync_caddr_a = sync_addr_a[CACHE_LINE_DEPTH +: CACHE_DEPTH];
    wire [CACHE_DEPTH-1:0] sync_caddr_b = sync_addr_b[CACHE_LINE_DEPTH +: CACHE_DEPTH];
    wire [CACHE_TAG_WIDTH-1:0] req_tag_a = sync_addr_a[ADDR_WIDTH-1:ADDR_WIDTH - CACHE_TAG_WIDTH];
    wire [CACHE_TAG_WIDTH-1:0] req_tag_b = sync_addr_b[ADDR_WIDTH-1:ADDR_WIDTH - CACHE_TAG_WIDTH];

    reg sync_write_b = 0;
    reg [WORD_WIDTH-1:0] sync_datain_b;

    wire [WORD_WIDTH-1:0] cached_word_a = rdata_a[
            sync_addr_a[CACHE_LINE_DEPTH-1:$clog2(WORD_WIDTH/ADDR_GRANULARITY)]
            * WORD_WIDTH +: WORD_WIDTH];
    wire [WORD_WIDTH-1:0] cached_word_b = rdata_b[
            sync_addr_b[CACHE_LINE_DEPTH-1:$clog2(WORD_WIDTH/ADDR_GRANULARITY)]
            * WORD_WIDTH +: WORD_WIDTH];

    wire read_sat_a = cready_a & req_tag_a == tag_a;
    wire read_sat_b = cready_b & req_tag_b == tag_b;

    wire a_needs_read = sync_is_read_a & ~read_sat_a;
    wire b_needs_read = sync_is_read_b & ~read_sat_b;

    reg [ADDR_WIDTH-1:0] inflight_addr;
    reg inflight_is_b;

    reg incoming_word_rdy = 0;
    reg [WORD_WIDTH-1:0] incoming_word;
    reg incoming_is_b;

    wire a_from_bus = incoming_word_rdy & ~incoming_is_b;
    wire b_from_bus = incoming_word_rdy & incoming_is_b;

    assign dataout_a = a_from_bus ? incoming_word : cached_word_a;
    assign dataout_b = b_from_bus ? incoming_word : cached_word_b;

    assign ready_a = ~wb_stb_o & ~a_needs_read & ~b_needs_read;
    assign ready_b = wr_b ? ~wb_stb_o | wb_ack_i : ready_a;

    always @(posedge clk) begin
        sync_is_read_a <= valid_a;
        sync_addr_a <= addr_a;
        sync_is_read_b <= valid_b & ~wr_b;
        sync_addr_b <= addr_b;
        cready_a <= cache_valid[caddr_a];
        cready_b <= cache_valid[caddr_b];
        sync_datain_b <= datain_b;

        // Default to no new data
        incoming_word_rdy <= 0;
        incoming_word <= {WORD_WIDTH{1'bx}};

        if(~wb_stb_o) begin // No transaction in progress
            if(valid_b & wr_b) begin
                wb_stb_o <= 1;
                wb_we_o <= 1;
                wb_adr_o <= {addr_b[ADDR_WIDTH-1:CACHE_LINE_DEPTH], {CACHE_LINE_DEPTH{1'b0}}};

                wb_sel_o <= {(CACHE_WIDTH/ADDR_GRANULARITY){1'b0}};
                wb_sel_o[WORD_WIDTH/ADDR_GRANULARITY * addr_b[CACHE_LINE_DEPTH-1:WORD_DEPTH]
                        +: WORD_WIDTH/ADDR_GRANULARITY] <= {(WORD_WIDTH/ADDR_GRANULARITY){1'b1}};

                wb_dat_o <= {CACHE_WIDTH{1'b0}};
                wb_dat_o[WORD_WIDTH * addr_b[CACHE_LINE_DEPTH-1:WORD_DEPTH]
                        +: WORD_WIDTH] <= datain_b;

                inflight_addr <= sync_addr_b;                
            end else if(b_needs_read) begin
                wb_stb_o <= 1;
                wb_we_o <= 0;
                wb_adr_o <= {req_tag_b, sync_caddr_b, {CACHE_LINE_DEPTH{1'b0}}};
                wb_sel_o <= {(CACHE_WIDTH/ADDR_GRANULARITY){1'b1}};
                wb_dat_o <= {CACHE_WIDTH{1'bx}};
                inflight_is_b <= 1;
                inflight_addr <= sync_addr_b;
            end else if(a_needs_read) begin
                wb_stb_o <= 1;
                wb_we_o <= 0;
                wb_adr_o <= {req_tag_a, sync_caddr_a, {CACHE_LINE_DEPTH{1'b0}}};
                wb_sel_o <= {(CACHE_WIDTH/ADDR_GRANULARITY){1'b1}};
                wb_dat_o <= {CACHE_WIDTH{1'bx}};
                inflight_is_b <= 0;
                inflight_addr <= sync_addr_a;
            end
        end else begin // Transaction in progress
            if(wb_ack_i) begin // we have incoming data, finish transaction
                wb_stb_o <= 0;
                wb_we_o <= 1'bx;
                wb_adr_o <= {ADDR_WIDTH{1'bx}};
                wb_sel_o <= {(CACHE_WIDTH/ADDR_GRANULARITY){1'bx}};
                wb_dat_o <= {CACHE_WIDTH{1'bx}};

                if(~wb_we_o) begin
                    incoming_word_rdy <= 1'b1;
                    incoming_word <= wb_dat_i[
                            inflight_addr[CACHE_LINE_DEPTH-1:$clog2(WORD_WIDTH/ADDR_GRANULARITY)]
                            * WORD_WIDTH +: WORD_WIDTH];
                    incoming_is_b <= inflight_is_b;
                end
            end
        end

        // Block RAM actions
        // Be careful that we don't ever ask for more than two different addrs
        // at a time, that way the whole thing is synthesizable as a dual port
        // primitive
        if(wb_stb_o & wb_ack_i & ~wb_we_o) begin
            cache[inflight_addr[CACHE_LINE_DEPTH +: CACHE_DEPTH]]
                    <= {inflight_addr[ADDR_WIDTH-1:CACHE_DEPTH+CACHE_LINE_DEPTH], wb_dat_i};
            cache_valid[inflight_addr[CACHE_LINE_DEPTH +: CACHE_DEPTH]] <= 1'b1;
        end else begin
            {tag_a, rdata_a} <= cache[caddr_a];
        end

        if(wb_we_o & read_sat_b) begin
            cache[sync_caddr_b][WORD_WIDTH * sync_addr_b[CACHE_LINE_DEPTH-1:WORD_DEPTH]
                    +: WORD_WIDTH] <= sync_datain_b;
        end else begin
            {tag_b, rdata_b} <= cache[caddr_b];
        end
    end
endmodule