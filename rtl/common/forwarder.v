module forwarder #(
        parameter DATA_WIDTH = 32,
        parameter ADDR_WIDTH = 4    
    ) (
        input [DATA_WIDTH-1:0] value,
        input [ADDR_WIDTH-1:0] src,

        input [DATA_WIDTH-1:0] fwd_first_val,
        input [ADDR_WIDTH-1:0] fwd_first_src,
        output fwd_first_used,

        input [DATA_WIDTH-1:0] fwd_second_val,
        input [ADDR_WIDTH-1:0] fwd_second_src,
        output fwd_second_used,

        output [DATA_WIDTH-1:0] forwarded_value
    );

    wire can_forward = src != 0;

    assign fwd_first_used = can_forward & fwd_first_src == src;
    assign fwd_second_used = can_forward & fwd_second_src == src;
    
    assign forwarded_value = fwd_first_used ? fwd_first_val
                           : fwd_second_used ? fwd_second_val
                           : value;
endmodule