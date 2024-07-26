/*
PS/2 keyboard physical interface

Spits out PS/2 scancodes on an 8-bit parallel pipeline bus. Currently does not
support host-to-device communcation.

Not tested due to electrical issues

*/

module ps2phy(
        input clkin,

        output [7:0] sym_data,
        output sym_valid,
        input sym_ready,

        input device_clk,
        input device_dat
    );

    reg [7:0] data;

    reg [1:0] edet = 2'b00;

    initial sym_valid = 1'b0;
    reg [3:0] bitcount = 0;
    
    always @(posedge clkin) begin
        if(sym_valid && sym_ready) sym_valid = 1'b0;
        if(edet == 2'b01) begin // posedge device_clk, but more efficient maybe
            case (bitcount)
                4'd0: if(device_dat == 1'b0) bitcount <= 4'd1; // low start bit
                4'd9: if(device_dat ^ (^par)) bitcount <= 4'd10; // check parity
                      else bitcount <= 4'd0;
                4'd10: begin // high stop bit
                    if(device_dat == 1'b1) begin
                        sym_data = data;
                        sym_valid = 1'b1;
                    end // if we don't get a valid stop bit, just give up
                    bitcount <= 4'd0;
                end
                default: begin // Data bits, start from the top and shift down
                    data <= {device_dat, data[7:1]};
                    bitcount <= bitcount + 4'd1;
                end
            endcase
        end
        edet <= {edet[0], device_clk};
    end

endmodule