/*
PS/2 keyboard physical interface

Spits out PS/2 scancodes on an 8-bit parallel pipeline bus. Currently does not
support host-to-device communcation.

*/

module ps2phy(
        input clkin,

        output reg [7:0] sym_data,
        output sym_valid,
        input sym_ready,

        input device_clk,
        input device_dat
    );

    reg [7:0] data;
    reg valid = 1'b0;
    assign sym_valid = valid;

    reg [1:0] edet = 2'b00;
    reg [3:0] bitcount = 4'b0;

    always @(posedge clkin) begin
        if(valid & sym_ready) valid <= 1'b0;
        else begin
            if(edet == 2'b10) begin // posedge device_clk, but more efficient maybe
                case (bitcount)
                    4'd0: if(device_dat == 1'b0) bitcount <= 4'd1; // low start bit
                    4'd9: if(device_dat ^ (^data)) bitcount <= 4'd10; // check parity
                        else bitcount <= 4'd0;
                    4'd10: begin // high stop bit
                        if(device_dat == 1'b1) begin
                            sym_data <= data;
                            valid <= 1'b1;
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
    end 
endmodule