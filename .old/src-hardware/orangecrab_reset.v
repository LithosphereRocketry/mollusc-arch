
/*
 * A module that will reset OrangeCrab on input.
 */

module orangecrab_reset #(
	parameter N_CYCLES = 0 // Number of cycles before 
) (
	input clk,
	input do_reset,
	output nreset_out
);
	// by default, we want the reset signal held high.
	reg reset_sr = 1'b1;
	reg [$clog2(N_CYCLES)-1:0] counter = N_CYCLES;
	
	always @(posedge clk) begin
		// if the do_reset signal ever goes high,
		// allow nreset_out to drop, resetting the board.
		if (do_reset)
			if(counter == 0) reset_sr <= 1'b0; else counter <= counter - 1;
		else counter <= N_CYCLES;
			
	end
	
	assign nreset_out = {reset_sr};

endmodule