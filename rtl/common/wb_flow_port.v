/*
 * Wishbone flow-controlled peripheral port
 * Designed for connecting to peripherals such as UARTs, etc.
 * 
 * Address 0: Data port (read/write)
 * Address 1: Status mask (read-only)
 * > bit 0: Read data valid
 * > bit 1: Write data ready
 * 
 * Word select is not currently supported.
 * 
 * Note that this device is entirely stateless - CLK and RST are included only
 * for consistency. All state is handled by the peripheral behind the port,
 * which is assumed to run on the same clock as the Wishbone bus. 
 */

module wb_flow_port #(
        parameter DATA_WIDTH = 8
    ) (
        input clk,
        input rst,

        input adr_i,
        output [DATA_WIDTH-1:0] dat_o,
        input [DATA_WIDTH-1:0] dat_i,
        input we_i,
        input stb_i,
        input cyc_i,
        output ack_o,

        output [DATA_WIDTH-1:0] write_data,
        output write_valid,
        input write_ready,

        input [DATA_WIDTH-1:0] read_data,
        input read_valid,
        output read_ready
    );

    assign write_data = dat_i;
    assign dat_o = adr_i ? {{DATA_WIDTH-2{1'b0}}, write_ready, read_valid} : read_data;

    wire wb_active = stb_i & cyc_i;
    wire port_active = wb_active & ~adr_i;
    wire status_active = wb_active & adr_i;

    assign write_valid = port_active & we_i;
    assign read_ready = port_active & ~we_i;

    assign ack_o = status_active
                 | (write_ready & write_valid)
                 | (read_ready & read_valid);

    initial if(DATA_WIDTH < 2) begin
        $error("Flow port cannot be instantiated with width < 2");
        $finish;
    end
endmodule