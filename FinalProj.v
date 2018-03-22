

module UTT(output [17:0] LEDR, input [17:0] SW, input CLOCK_50, input [3:0] KEY, output [7:0] HEX1, output [7:0] HEX0);
	
	single_lane sl(SW, CLOCK_50, LEDR, KEY, HEX1, HEX0);


endmodule

// this is a single lane test


module single_lane (
		input [13:0] SW,
		input clk,
		output [17:0] LEDR,
		input [3:0] KEY,
		output [7:0] HEX1,
		output [7:0] HEX0
	);
	
	/********************************************************************************* variables */
	// a lane represents a lane of notes
	reg[499:0] lane_mem = 500'b01100010100100001001000001001000010000000100000001000000010000101000010010000000100010000000011000000110001010010000100100000100100001000000010000000100000001000010100001001000000010001000000001100000011000101001000010010000010010000100000001000000010000000100001010000100100000001000100000000110000001100010100100001001000001001000010000000100000001000000010000101000010010000000100010000000011000000110001010010000100100000100100001000000010000000100000001000010100001001000000010001000000001100000;
	reg [499:0] lane = 500'b01100010100100001001000001001000010000000100000001000000010000101000010010000000100010000000011000000110001010010000100100000100100001000000010000000100000001000010100001001000000010001000000001100000011000101001000010010000010010000100000001000000010000000100001010000100100000001000100000000110000001100010100100001001000001001000010000000100000001000000010000101000010010000000100010000000011000000110001010010000100100000100100001000000010000000100000001000010100001001000000010001000000001100000;
	// storing the score
	reg [5:0] score0 = 5'b00000;
	
	// ahex_displayssign running state to switch 0, 1 for running, 0 for paused
	assign running = SW[0];
	
	// assign leds to display the las 10 bits of the lane only
	assign LEDR [9:0] = lane [9:0];
	
	// assign lane1 input to key 3
	assign l1_inp = SW[1];

	// display the score
	score_display score_hex(score0, HEX1, HEX0);
	
	assign LEDR[17] = running;
	assign LEDR[16] = clk_out;
	
	// count to 50 million for 1Hz ( for moving notes along lane )
	reg [25:0] rate_max = 26'd9000000;
	reg [25:0] curr_count = 26'b0;
	
	reg clk_out = 1'b0; // the 1hz signal
	always @(posedge clk) begin
		curr_count <= curr_count + 1;
		if(curr_count == rate_max)
			begin
				curr_count <= 0;
				clk_out <= !clk_out;
			end	
			
		if (running) begin 
			if (increment_score) begin
				score0 <= score0 + 1;
			end
			
			if (decrement_score) begin
				score0 <= score0 - 1;
				
			end
		end else begin
			score0 <= 5'd0;
			
		end
	end
	
//	reg doneinc = 1'b1;
//	reg donedec = 1'b1;
	
//	always@(posedge increment_score) begin
//		increment_score <= 1'b0;
//	end
//	
	
	always@(posedge clk_out) begin
		if (running) begin
			lane <= lane >> 1;
		end else begin
			lane <= lane_mem;
		end
	
	end
	

	
	reg increment_score;
	reg decrement_score;
	

		
	always@(posedge l1_inp)
		begin

			if (lane[0] == 1'b1)
				begin
					decrement_score <= 1'b0;
					increment_score <= 1'b1;
					increment_score <= 1'b0;
				end
			else
				begin
					decrement_score <= 1'b1;
					increment_score <= 1'b0;
					decrement_score <= 1'b0;
					
						
				end
		
		end


endmodule

// module for displaying 5 bit score (max is 31)
module score_display(score, OUT1, OUT2);
	input [4:0] score;
    output reg [7:0] OUT1, OUT2;
     
     always @(*)
     begin
        case(score)
            5'd0:
                begin
                    OUT1 = 7'b1000000;
                    OUT2 = 7'b1000000;
                end
            5'd1:
                begin
                    OUT1 = 7'b1000000;
                    OUT2 = 7'b1111001;
                end
            6'd2:
                begin
                    OUT1 = 7'b1000000;
                    OUT2 = 7'b0100100;
                end
            5'd3:
                begin
                    OUT1 = 7'b1000000;
                    OUT2 = 7'b0110000;
                end
            5'd4:
                begin
                    OUT1 = 7'b1000000;
                    OUT2 = 7'b0011001;
                end
            5'd5:
                begin
                    OUT1 = 7'b1000000;
                    OUT2 = 7'b0010010;
                end
            5'd6:
                begin
                    OUT1 = 7'b1000000;
                    OUT2 = 7'b0000010;
                end
            5'd7:
                begin
                    OUT1 = 7'b1000000;
                    OUT2 = 7'b1111000;
                end
            5'd8:
                begin
                    OUT1 = 7'b1000000;
                    OUT2 = 7'b0000000;
                end
            5'd9:
                begin
                    OUT1 = 7'b1000000;
                    OUT2 = 7'b0011000;
                end
            5'd10:
                begin
                    OUT1 = 7'b1111001;
                    OUT2 = 7'b1000000;
                end
            5'd11:
                begin
                    OUT1 = 7'b1111001;
                    OUT2 = 7'b1111001;
                end
            5'd12:
                begin
                    OUT1 = 7'b1111001;
                    OUT2 = 7'b0100100;
                end
            5'd13:
                begin
                    OUT1 = 7'b1111001;
                    OUT2 = 7'b0110000;
                end
            5'd14:
                begin
                    OUT1 = 7'b1111001;
                    OUT2 = 7'b0011001;
                end
            5'd15:
                begin
                    OUT1 = 7'b1111001;
                    OUT2 = 7'b0010010;
                end
            5'd16:
                begin
                    OUT1 = 7'b1111001;
                    OUT2 = 7'b0000010;
                end
            5'd17:
                begin
                    OUT1 = 7'b1111001;
                    OUT2 = 7'b1111000;
                end
            5'd18:
                begin
                    OUT1 = 7'b1111001;
                    OUT2 = 7'b0000000;
                end
            5'd19:
                begin
                    OUT1 = 7'b1111001;
                    OUT2 = 7'b0011000;
                end
            5'd20:
                begin
                    OUT1 = 7'b0100100;
                    OUT2 = 7'b1000000;
                end
            5'd21:
                begin
                    OUT1 = 7'b0100100;
                    OUT2 = 7'b1111001;
                end
            5'd22:
                begin
                    OUT1 = 7'b0100100;
                    OUT2 = 7'b0100100;
                end
            5'd23:
                begin
                    OUT1 = 7'b0100100;
                    OUT2 = 7'b0110000;
                end
            5'd24:
                begin
                    OUT1 = 7'b0100100;
                    OUT2 = 7'b0011001;
                end
            5'd25:
                begin
                    OUT1 = 7'b0100100;
                    OUT2 = 7'b0010010;
                end
            5'd26:
                begin
                    OUT1 = 7'b0100100;
                    OUT2 = 7'b0000010;
                end
            5'd27:
                begin
                    OUT1 = 7'b0100100;
                    OUT2 = 7'b1111000;
                end
            5'd28:
                begin
                    OUT1 = 7'b0100100;
                    OUT2 = 7'b0000000;
                end
            5'd29:
                begin
                    OUT1 = 7'b0100100;
                    OUT2 = 7'b0011000;
                end
            5'd30:
                begin
                    OUT1 = 7'b0110000;
                    OUT2 = 7'b1000000;
                end
            5'd31:
                begin
                    OUT1 = 7'b0110000;
                    OUT2 = 7'b0100100;
                end
           
            default: // score is 0 by default
                begin
                    OUT1 = 7'b1000000;
                    OUT2 = 7'b1000000;
                end
        endcase

    end
endmodule
