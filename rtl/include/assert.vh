`define assert(signal, value) \
    if (signal !== value) begin \
        $display("%s : %d: ASSERTION FAILED in %m: signal is %h, expected %h", `__FILE__, `__LINE__, signal, value); \
        $fatal; \
    end

`define timeout(clk,count) integer __ct = 0; \
    always @(posedge clk) begin \
        if(__ct > count) begin \
            $display("Simulation %s timed out at %d cycles", `__FILE__, count); \
            $fatal; \
        end \
        __ct <= __ct + 1; \
    end