module cpu #(
        parameter CACHE_WIDTH = 128,
        parameter CACHE_DEPTH = 10,
        parameter BUS_GRANULARITY = 32,

        localparam SEL_WIDTH = CACHE_WIDTH/BUS_GRANULARITY
    ) (
        input clk,
        input rst,

        output [31:0] wb_adr_o,
        output [CACHE_WIDTH-1:0] wb_dat_o,
        input [CACHE_WIDTH-1:0] wb_dat_i,
        output wb_we_o,
        output [SEL_WIDTH-1:0] wb_sel_o,
        output wb_stb_o,
        input wb_ack_i,
        input wb_err_i,
        input wb_rty_i,
        output wb_cyc_o,
        output dbg
    );


    // Forward declarations for jumps
    wire flow_is_jump;
    wire [31:0] flow_jump_addr;

    // Forward declarations for writeback/passback
    wire forward_valid;
    wire [3:0] forward_dest;
    wire [31:0] forward_value;
    wire [3:0] writeback_dest;
    wire [31:0] writeback_value;

    wire fetch_stall;
    wire [31:0] fetch_fetchpc;
    wire [31:0] fetch_presentpc;
    stage_fetch fetch(
        .clk(clk),
        .stall_in(fetch_stall),
        .is_jump(flow_is_jump),
        .jump_addr(flow_jump_addr),

        .fetchpc(fetch_fetchpc),
        .presentpc(fetch_presentpc)
    );

    // Forward declarations for fetch port
    wire [31:0] fetch_instr;
    wire fetch_ready;
    wire fetch_discard;
    
    wire decode_stall;
    wire [31:0] decode_pc;
    wire [31:0] decode_a;
    wire [31:0] decode_b;
    wire [31:0] decode_m;
    wire [3:0] decode_dest;
    wire [3:0] decode_aluop;
    wire decode_is_mem;
    wire decode_mem_write;
    wire decode_is_jump;
    stage_decode decode(
        .clk(clk),
        .pc_in(fetch_presentpc),
        .instr(fetch_instr),
        .instr_valid(fetch_ready),

        .stall_in(decode_stall),
        .stall(fetch_stall),
        .discard(fetch_discard),

        .write_addr(writeback_dest),
        .write_data(writeback_value),
        .forward_valid(forward_valid),
        .forward_addr(forward_dest),
        .forward_data(forward_value),
        
        .pc(decode_pc),
        .reg_a(decode_a),
        .reg_b(decode_b),
        .reg_m(decode_m),
        .dest(decode_dest),
        .aluop(decode_aluop),
        .mem(decode_is_mem),
        .mem_write(decode_mem_write),

        .jump(decode_is_jump)
    );
    
    wire execute_stall;
    wire [3:0] execute_dest;
    wire [31:0] execute_value;
    wire [31:0] mem_write_value;
    wire [31:0] mem_addr;
    wire mem_write;
    wire execute_is_mem;
    stage_execute execute(
        .clk(clk),
        .pc(decode_pc),

        .stall(decode_stall),
        .stall_in(execute_stall),

        .dest(decode_dest),
        .aluop(decode_aluop),
    
        .reg_a(decode_a),
        .reg_b(decode_b),
        .reg_m(decode_m),

        .fwd_valid(forward_valid),
        .fwd_addr(forward_dest),
        .fwd_val(forward_value),

        .is_mem_in(decode_is_mem),
        .mem_write_in(decode_mem_write),

        .is_jump(decode_is_jump),
        
        .jump(flow_is_jump),
        .jump_addr(flow_jump_addr),

        .out_addr(execute_dest),
        .out_val(execute_value),

        .is_mem(execute_is_mem),
        .mem_addr(mem_addr),
        .mem_val(mem_write_value),
        .mem_write(mem_write)
    );

    wire [31:0] mem_read_value;
    wire mem_valid;

    stage_memory memory(
        .dest_in(execute_dest),
        .value_in(execute_value),

        .mem_valid(mem_valid),
        .mem_in(mem_read_value),
        .is_mem(execute_is_mem),

        .stall(execute_stall),

        .writeback_addr(writeback_dest),
        .writeback_value(writeback_value)
    );

    memcontrol #(
        .CACHE_WIDTH(CACHE_WIDTH),
        .CACHE_DEPTH(CACHE_DEPTH),
        .ADDR_WIDTH(32),
        .ADDR_GRANULARITY(BUS_GRANULARITY)
    ) memctrl(
        .clk(clk),
        .rst(rst),

        .valid_a(~fetch_discard),
        .addr_a(fetch_fetchpc),
        .dataout_a(fetch_instr),
        .ready_a(fetch_ready),

        .valid_b(decode_is_mem),
        .addr_b(mem_addr),
        .datain_b(mem_write_value),
        .wr_b(mem_write),
        .dataout_b(mem_read_value),
        .ready_b(mem_valid),

        .wb_adr_o(wb_adr_o),
        .wb_dat_o(wb_dat_o),
        .wb_dat_i(wb_dat_i),
        .wb_we_o(wb_we_o),
        .wb_sel_o(wb_sel_o),
        .wb_stb_o(wb_stb_o),
        .wb_ack_i(wb_ack_i),
        .wb_err_i(wb_err_i),
        .wb_rty_i(wb_rty_i),
        .wb_cyc_o(wb_cyc_o)
    );

    assign dbg = flow_is_jump;
endmodule

