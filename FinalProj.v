

module FinalProj(output [17:0] LEDR, input [17:0] SW, input CLOCK50, input [3:0] KEY);
	
	single_lane sl(SW, CLOCK50, LEDR, KEY);


endmodule

// this is a single lane test


module single_lane (
		input [13:0] SW,
		input clk,
		output [9:0] LEDR,
		input [3:0] KEY
	);
	
	/********************************************************************************* variables */
	// a lane represents a lane of notes
	// mem is not changed
	reg [99:0] lane_mem = 100'b0010100001000010000000000000000010000000010000000101000000000000000001001000001000000000000000000000;
	// this changes as it is shifted right
	reg [99:0] lane;

	// program is running or paused
	wire running = 1'b0;

	// for storing the score
	reg [3:0] score = 4'd0;

	/**************************************************************************** IO assignments */
	// assign lane1 input to key 3
	assign l1 = KEY[3];
	// assign running state to switch 0, 1 for running, 0 for paused
	assign running = SW[0];
	// assign leds to display the last 10 bits of the lane only
	assign LEDR [9:0] = lane[9:0];


	// display the score
	hex_display score_hex(score, HEX1);

	// count to 50 million for 1Hz ( for moving notes along lane )
	reg [25:0] rate_max = 26'b10111110101111000010000000;
	reg [25:0] curr_count = 26'b0;
	reg clk_out = 1'b0; // the 1hz signal
	always @(posedge clk) begin
		curr_count <= curr_count + 1;
		if(curr_count == rate_max)
			begin
				curr_count <= 0;
				clk_out <= !clk_out;
			end	
	end

	// initialize the game
	initial 
		begin
			// copy lane from memory to current game
			lane = lane_mem;
		end

	// on key-press, check correctness if running, reset if paused
	always@(posedge l1)
		begin
			if (running)
				begin
					if (lane[0] == 1'b1)
						// hit key on time ( correct )
						begin
							// correct input, increment score by 1
							score = score + 1;
						end
					else
						// missed the key ( incorrect )
						begin
							// incorrect, subtract 2 from score, maintain positive
							if (score == 4'd0 | score == 4'd1)
								// cannot subtract 2, simply set to 0
								score = 4'd0;
							else
								// can subtract 2, do it
								score = score - 2;
							
						end
				end
			else	
				// not running, so paused
				begin
					// reset the lane, forget the score
					lane = lane_mem;
					score = 4'b0;
				end
		end


	// on the 1 second clock, shift the register right ( move notes along lane )
	always@(posedge clk_out)
		begin	
			// if the game us running
			if (running)
				begin
					// shift the bits
					lane = 1 >> lane;
				end
			
		end
	
endmodule

	
module hex_display(IN, OUT);
    input [3:0] IN;
	 output reg [7:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;
			
			default: OUT = 7'b0111111;
		endcase

	end
endmodule