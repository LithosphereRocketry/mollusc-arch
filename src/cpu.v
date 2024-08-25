module cpu(
        input clk
    );


    // Forward declarations for jumps
    wire flow_is_jump;
    wire [31:0] flow_jump_addr;

    // Forward declarations for writeback/passback
    wire [3:0] forward_dest;
    wire [31:0] forward_value;
    wire [3:0] writeback_dest;
    wire [31:0] writeback_value;


    wire [31:0] fetch_fetchpc;
    wire [31:0] fetch_presentpc;
    stage_fetch fetch(
        .clk(clk),
        .is_jump(flow_is_jump),
        .jump_addr(flow_jump_addr),

        .fetchpc(fetch_fetchpc),
        .presentpc(fetch_presentpc)
    );

    wire [31:0] fetch_instr;
    
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

        .write_addr(writeback_dest),
        .write_data(writeback_value),
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
    
    wire [3:0] execute_dest;
    wire [31:0] execute_value;
    wire [31:0] mem_write_value;
    wire [31:0] mem_addr;
    wire mem_write;
    wire execute_is_mem;
    stage_execute execute(
        .clk(clk),
        .pc(decode_pc),

        .dest(decode_dest),
        .aluop(decode_aluop),
    
        .reg_a(decode_a),
        .reg_b(decode_b),
        .reg_m(decode_m),

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

    stage_memory memory(
        .dest_in(execute_dest),
        .value_in(execute_value),
        .mem_in(mem_read_value),
        .is_mem(execute_is_mem),

        .writeback_addr(writeback_dest),
        .writeback_value(writeback_value)
    );

    memcontrol memctrl(
        .clk(clk),

        .addr_a(fetch_fetchpc[31:2]),
        .datain_a(32'hxxxxxxxx),
        .wr_a(1'b0),
        .dataout_a(fetch_instr),

        .addr_b(mem_addr[31:2]),
        .datain_b(mem_write_value),
        .wr_b(mem_write),
        .dataout_b(mem_read_value)
    );
endmodule

