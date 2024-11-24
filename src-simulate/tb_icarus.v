module tb_icarus();

    reg clk = 0, rst = 1;
    cputest dut(.clk(clk), .rst(rst));

    initial begin
        $dumpfile("waveforms/icarus.vcd");
        $dumpvars;
        clk = 1;
        #1;
        clk = 0;
        #1;
        rst = 0;
        repeat(256) begin
            clk = 1;
            #1;
            clk = 0;
            #1;
        end
        $finish;
    end
endmodule