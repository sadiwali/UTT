// a rendition of Tap Tap Revenge on DE2-115 using Verilog.

module FinalProj(
	CLOCK_50,
	SW,
	LEDR, 
	KEY,
	GPIO,
	HEX0, 
	HEX1, 
	VGA_CLK,   								//	VGA Clock
	VGA_HS,									//	VGA H_SYNC
	VGA_VS,									//	VGA V_SYNC
	VGA_BLANK_N,							//	VGA BLANK
	VGA_SYNC_N,								//	VGA SYNC
	VGA_R,   								//	VGA Red[9:0]
	VGA_G,	 								//	VGA Green[9:0]
	VGA_B,   								//	VGA Blue[9:0]);
	);
	
	input CLOCK_50;							// on board 50Mhz clock
	input [17:0] SW;						// switches
	output [17:0] LEDR;						// red LEDS
	input [3:0] KEY;						// pushbuttons
	input [0:5] GPIO;						// gpio
	output [6:0] HEX0;						// hex 0 (right)
	output [6:0] HEX1;						// hex 1 (left)
	// Do not change the following outputs for VGA
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [7:0] y;
	wire writeEn;

	
	// score keeping
	wire [4:0] score;
	// input for lanes
	wire lane1_press;
	assign lane1_press = !GPIO[0];
	// speed control
	wire [25:0] lane_rate;
	wire lane_clk; // clock for the lane
	// lane memory
	reg [99:0] lane1_mem = 100'b0001000000100001100010111000010100100000000001000000001000001000000110100000010000000001100010001000;
	wire [99:0] lane1; // copied to from memory
	// reset key
	wire resetn;
	assign resetn = KEY[0];
	// running switch
	wire running;
	assign running = SW[15];
	// LEDs display last 10 bits of lane1 (change this to VGA)
	assign LEDR [9:0] = lane1[9:0];
	
	assign LEDR[17] = lane_clk;
	assign LEDR[15] = lane1_press;
	
	// initialize modules here:
	
	
	
	
	// speed control
	speed_control speed_ctrl(.speed(SW[17:16]), .lane_rate(lane_rate));
	// lane rate divider
	note_rate_div lane_nrd(.clk(CLOCK_50), .rate(lane_rate), .resetn(!resetn), .out_clk(lane_clk));
	// score display
	score_display score_disp(.score(score), .HEX0(HEX0), .HEX1(HEX1));
	// data-path
	datapath d0(.clk(CLOCK_50), .lane_clk(lane_clk), .lane1_press(lane1_press), .lane1_mem(lane1_mem), .lane1(lane1), .score(score), .resetn(!resetn), .running(running), .debug(LEDR[16]), .x(x), .y(y), .colour(colour)
	);
	
endmodule

// set the lane rate based on the speed selected by the switches
module speed_control(
	speed,
	lane_rate
	);
	input [1:0] speed;
	output reg [25:0] lane_rate;
	// set the speed of the lanes according to the speed switch
	always@(*) begin
		case(speed)
			2'd0: begin
				// 1st speed 1hz
				lane_rate <= 26'd50000000;
			end
			2'd1: begin
				// 2nd speed 2hz
				lane_rate <= 26'd25000000;
			end
			2'd2: begin
				// 3rd speed 4hz
				lane_rate <= 26'd10000000;
			
			end
			2'd3: begin
				// 4th speed 8hz
				lane_rate <= 26'd5000000;
			end
		endcase
	end
endmodule

// data-path controls game logic
module datapath(
	clk,											// 50Mhz clock
	lane_clk,										// lane clock is much slower
	lane1_press,									// input for lane 1 press 
	lane1_mem,										// lane 1 memory
	lane1,											// lane 1 actual
	score,											// 5 bit score
	resetn,											// reset 
	running,											// running or paused
	debug,
	x,
	y,
	colour
	);
	input clk;
	input lane_clk;
	input lane1_press;
	input [99:0] lane1_mem;
	output reg [99:0] lane1; 						// variable lane output
	output reg[4:0] score;
	input resetn;
	input running;
	output reg debug;
	output reg [7:0] x;
	output reg [7:0] y;
	output reg [2:0] colour;
	
	// flag used to prevent over cycling of the lane on FSM clock
	reg shifted = 1'b0;
	// flag used to prevent double pressing for score
	reg pressed = 1'b0;
	// keep track of	assign LEDR[16:0] = lane_rate[16:0]; current state
	reg [4:0] currs;
	
	reg newclk = 1'b1;
	
	reg[7:0] dotx;
	reg[7:0] doty;
	
	// the FSM inspired by https://github.com/nathan78906/CaveCatchers/blob/master/cavecatchers.v
	always@(posedge clk) begin
		if (resetn) begin
			// reset the game, go to reset state
			currs <= 5'd0;
		end 
		
		case (currs)
			5'd0: begin // reset state (begin)
				score <= 5'd0;			
				lane1 <= lane1_mem;
				shifted <= 1'b0;
				// if running, then start, else, stay here
				if (running) begin
					currs <= 5'd1; // go to start state
				end
			end
			5'd1: begin	// move lane on lane clock (wait for it)
				if (lane_clk) begin
					newclk <= 1'b0;
					// if not shifted once, shift
					if (!shifted & newclk) begin
						shifted <= 1'b1;
						// move lane only on lane clock
						lane1 <= lane1 >> 1;
						doty <= doty + 1;
						currs <= 5'd4;
					end
				end else begin
					newclk <= 1'b1;
				end
			end
			5'd2: begin	// check for input 
				// only do this while the clock is still down and button was not pressed before
				if (!lane_clk) begin
					currs <= 5'd3;
					shifted <= 1'b0;
					newclk <= 1'b1;
				end else begin
					if (lane1_press) begin
						currs <= 5'd3;
						shifted <= 1'b0;
						if (lane1[0]) begin
							score <= score + 1;
						end else begin
							if (score != 5'd0) begin
								score <= score - 1;
							end
						end
					
					end
					
				end
		
			end
			5'd3: begin // clear state
			
				x <= dotx;
				y <= doty;
				colour <= 3'b000;
				currs <= 5'd1;
			end
			
			5'd4: begin // draw state
				x <= dotx;
				y <= doty;
				colour <= 3'b111;
				currs <= 5'd2;
			
			
			end
		endcase
	end
endmodule

// module controls the speed of the notes
module note_rate_div(clk, rate, resetn, out_clk);
	input clk;
	input [25:0] rate;
	input resetn;
	output reg out_clk;
		
	// count to given rate 
	reg [25:0] curr_count = 26'b0;
	
	always @(posedge clk, posedge resetn) begin
		
		if (resetn) begin
			curr_count <= 26'b0;
			out_clk <= 1'b0;
		end else begin
			// do the count
			curr_count <= curr_count + 1'b1;
			if (curr_count == rate) begin
				curr_count <= 26'b0;
				// pulse out if not in reset mode
				out_clk <= !out_clk;
			end
		end
	end
endmodule

// display a score up to 20 in decimal form on hex displays
module score_display(
	score,
	HEX0,
	HEX1
	);
	input [4:0] score;
	output [7:0] HEX0;
	output [7:0] HEX1;
	// variables for each digit
	reg [3:0] a; // tens
	reg [3:0] b; // ones
	// display the digits separately
	hex_display tens(a, HEX1);
	hex_display ones(b, HEX0);
	
	always@(*) begin
		case (score)
			5'd0: begin
				a <= 4'd0;
				b <= 4'd0;
			end
			5'd1: begin
				a <= 4'd0;
				b <= 4'd1;
			end
			5'd2: begin
				a <= 4'd0;
				b <= 4'd2;
			end
			5'd3: begin
				a <= 4'd0;
				b <= 4'd3;
			end
			5'd4: begin
				a <= 4'd0;
				b <= 4'd4;
			end
			5'd5: begin
				a <= 4'd0;
				b <= 4'd5;
			end
			5'd6: begin
				a <= 4'd0;
				b <= 4'd6;
			end
			5'd7: begin
				a <= 4'd0;
				b <= 4'd7;
			end
			5'd8: begin
				a <= 4'd0;
				b <= 4'd8;
			end
			5'd9: begin
				a <= 4'd0;
				b <= 4'd9;
			end
			5'd10: begin
				a <= 4'd1;
				b <= 4'd0;
			end
			5'd11: begin
				a <= 4'd1;
				b <= 4'd1;
			end
			5'd12: begin
				a <= 4'd1;
				b <= 4'd2;
			end
			5'd13: begin
				a <= 4'd1;
				b <= 4'd3;
			end
			5'd14: begin
				a <= 4'd1;
				b <= 4'd4;
			end
			5'd15: begin
				a <= 4'd1;
				b <= 4'd5;
			end
			5'd16: begin
				a <= 4'd1;
				b <= 4'd6;
			end
			5'd17: begin
				a <= 4'd1;
				b <= 4'd7;
			end
			5'd18: begin
				a <= 4'd1;
				b <= 4'd8;
			end
			5'd19: begin
				a <= 4'd1;
				b <= 4'd9;
			end
			5'd20: begin
				a <= 4'd2;
				b <= 4'd0;
			end
		endcase
			
	
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

// given a score of at most 999, split into 3 digits for easy displaying onto HEX. Reset is positive edge.
module split_digits(score, digit1, digit2, digit3, clk, reset);

	input [9:0] score; // 0 - 999
	output reg [3:0] digit1; // 0 - 9
	output reg [3:0] digit2; // 0 - 9
	output reg [3:0] digit3; // 0 - 9
	input clk; // clock
	input reset; // reset the display for new score


	reg [9:0] copy_score; // copied score for decrementing

	reg started = 1'b0;
	reg running = 1'b1; // running until number reached

	always@(posedge clk, posedge reset) begin

		if (reset) begin
			running <= 1'b1;
			started <= 1'b0;
		end

		if (running) begin
			if (!started) begin
				started <= 1'b1;
				// initialization
				copy_score <= score; // copy the score
				digit1 <= 4'd0;
				digit2 <= 4'd0;
				digit3 <= 4'd0;
			end else begin
				// every loop except init
				copy_score <= copy_score - 1;
				if (copy_score == 10'd0) begin
					running <= 1'b0;
				end

				digit1 <= digit1 + 1; // increment digit 1

				if (digit1 == 4'd10) begin
					// increment digit 2
					digit1 <= 4'd0;
					digit2 <= digit2 + 1;
				end

				if (digit2 == 4'd10) begin
					// increment digit 3
					digit2 <= 4'd0;
					digit3 <= digit3 + 1;
				end

				if (digit3 == 4'd10) begin
					// more than 999, reset
					digit3 <= 4'd0;
					digit2 <= 4'd0;
					digit1 <= 4'd0;
				end
			end
		end
	end


endmodule
