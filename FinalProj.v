

module FinalProj(output [17:0] LEDR, input [17:0] SW, input CLOCK50, input [3:0] KEY, output reg [7:0] HEX1, output reg [7:0] HEX0);
	
	single_lane sl(SW, CLOCK50, KEY, LEDR,);


endmodule

// this is a single lane test
module single_lane (SW, clk, KEY, LEDR, HEXA, HEXB);
	input [17:0] SW;
	input clk;
	input [3:0] KEY;
	output [17:0] LEDR;
	output [7:0] HEXA, HEXB;
	
	// game reset
	wire reset = 0;
	wire resetsw = 0;
	assign resetsw = SW[1];

	// mem is not changed
	reg [99:0] lane_mem = 100'b0010100001000010000000000000000010000000010000000101000000000000000001001000001000000000000000000000;

	// a lane represents a lane of notes, right shifted on every rate clock
	reg [99:0] lane;

	// for storing the score (max is 31)
	wire [4:0] score = 5'd0;
	
	// note movement clock
	wire out_clk;

	// assign lane1 input to key 3
	assign l1 = KEY[3];
	
	// program is running or paused
	wire running = 0;
	assign running = SW[0];  
	
	
	// assign leds to display the last 10 bits of the lane only
	assign LEDR [9:0] = lane[9:0];


	// initialize the game
	initial begin
		// copy lane from memory to current game
		lane = lane_mem;
	end

	
	// on the 1 second clock, shift the register right ( move notes along lane )
	always@(posedge out_clk, posedge resetsw) begin	
		// if reset, reset
		if (resetsw) begin
			reset = 1;
			lane = lane_mem;
		end
	
		// if the game us running
		if (running)
			begin
				// shift the bits
				lane = 1 >> lane;
			end
	end
	
	
	
	// module declarations
	note_rate_div nrd(clk, 25d'd10000000 , reset, out_clk); 
	tap_detect lane1tap(l1, running, reset, score);
	score_display(score, HEXA, HEXB);
	
	
endmodule


module tap_detect(inp, running, reset, score);
	input inp;  // switch input from user
	input running;  // if game is running
	input reset;  // reset switch resets score
	output reg [4:0] score;  // score
	
	wire keyenable = 1;  // for disabling key on press down (prevent multi-presses)
	// on key-press, check correctness if running, reset if paused
	always@(posedge inp, negedge inp, posedge reset) begin
		// enable the key on key up
		if (!inp) begin
			keyenable = 1;
		end
		
		if (keyenable & running) begin
			keyenable = 0; // disable key since key not released yet
			if (lane[0] == 1'b1) begin
				// correct input, increment score by 1
				score = score + 1;
			end	else begin
				// incorrect, subtract 2 from score, maintain positive
				if (score == 5'd0 | score == 5'd1)
					// cannot subtract 2, simply set to 0
					score = 5'd0;
				else
					// can subtract 2, do it
					score = score - 2;
			end			
		end
		
		// reset the score
		if (reset) begin
			score = 5'd0;
		end
	end
endmodule

// module controls the speed of the notes
module note_rate_div(clk, rate, reset, out_clk);
	input clk;
	input [25:0] rate;
	input reset;
	output reg out_clk;
	
	// count to given rate 
	reg [25:0] curr_count = 26'b0;
	out_clk = 0; // the signal
	
	always @(posedge clk) begin
		if (reset) begin
			// do nothing in reset mode
			curr_count <= 0;
			out_clk <= 0;
		end else begin
			curr_count <= curr_count + 1;
			if (curr_count == rate) begin
				curr_count <= 0;
				// pulse out if not in reset mode
				out_clk <= !out_clk;
			end
		end
	end
endmodule

// module for displaying 5 bit score (max is 31)
module score_display(score, HEXA, HEXB);
	input [4:0] score;
    output reg [7:0] HEXA, HEXB;
     
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
