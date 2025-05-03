`timescale 1ns/1ps

module toplevel_test();
    localparam OUT_SIZE = 1<<16;
    localparam MAX_CYCLES = 100_000;

    reg clk = 0;
    reg rst = 1;

    wire [7:0] dport;
    wire dport_valid;
    wire [31:0] haltcode;
    wire halt_valid;

    platform dut(
        .clk(clk),
        .rst(rst),

        .dport(dport),
        .dport_valid(dport_valid),
        .dport_ready(1'b1),

        .haltcode(haltcode),
        .halt_valid(halt_valid),
        .halt_ready(1'b1)
    );

    integer dptr = 0;
    reg [7:0] data [0:OUT_SIZE-1];

    reg [7:0] expected [0:OUT_SIZE-1];

    task step; begin
        #1;
        clk = 1;
        #1;
        clk = 0;
    end endtask

    integer cycles = 0;
    integer i;
    initial begin
        $readmemh(`VERIFYPATH, expected);
        $dumpfile(`WAVEPATH);
        $dumpvars;
        
        step();
        rst = 0;
        repeat(MAX_CYCLES) begin
            cycles <= cycles + 1;
            step();
            if(dport_valid) begin
                data[dptr] <= dport;
                dptr <= dptr + 1;
            end
            if(dptr > OUT_SIZE) begin
                $display("ERROR: Program %s on platform %s overran input", `ROMPATH, `PLATFORM);
                $fatal;
            end
            if(halt_valid) begin
                if(haltcode == 32'd0) begin
                    for(i = 0; i < OUT_SIZE; i++) if(data[i] !== expected[i]) begin
                        $display("Program %s on platform %s gave unexpected output", `ROMPATH, `PLATFORM);
                        $display("Expected %h at position %d, got %h", expected[i], i, data[i]);
                        $fatal;
                    end
                    $display("Program %s on platform %s finished in %d cycles", `ROMPATH, `PLATFORM, cycles);
                    $finish;
                end else begin
                    $display("Program %s on platform %s exited with code %d", `ROMPATH, `PLATFORM, haltcode);
                    $fatal;
                end
            end
        end
        $display("ERROR: Program %s on platform %s timed out", `ROMPATH, `PLATFORM);
        $fatal;
    end
endmodule