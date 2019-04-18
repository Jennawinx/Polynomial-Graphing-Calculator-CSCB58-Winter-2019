/*

Initialization:
Inputs
	start: 	control --> 	(1 bit)
	reset: 	~ KEY[0] 		(1 bit)
	clk: 	CLOCK_50 		(1 bit)
Outputs
	init_complete: 			(1 bit) --> control
	Y: 						(8 bit) --> vga_input
	X: 						(9 bit) --> vga_input
	col 					(6 bit) --> vga_input

*/

/*
	Must reset to init again, therefore, no self-loops
*/

module Init (	
	input reset,			// active low, resets counters & regs
	input start,			// active high, runs the FSM (should work on pulse or switch)
	input clk,
	output reg [8:0] X,
	output reg [7:0] Y,
	output reg [5:0] col,
	// output [3:0] state,		// Temp
	output init_complete	// active high
);

	// assign state = current_state; // Temp

				// Screen bounds for counter
	localparam 	MAX_XY						= {1'b1, {17{1'b0}}},
				X_MAX 						= 18'd320,
				Y_MAX 						= 18'd240,

				// Screen position for axis
				X_CENTER					= 9'd160,
				Y_CENTER					= 8'd120,

				// Colours
				BLACK 						= 6'b00_0000,
				WHITE 						= 6'b11_1111,

				// Booleans
				ON 							= 1'b1,
				OFF 						= 1'b0,
				RESET_ON					= 1'b0,
				RESET_OFF 					= 1'b1;

	reg counter_enabled;			// counter enabled
	wire [17:0] count;
	
	//reg restart_count;			// active high

	// Resets counter if master reset is active or control tells it to reset
	//wire counter_reset = reset && ~restart_count;	// active low
	
    // States
	reg [3:0] current_state, next_state; 
				// Hopefully bit flips are ok?
    localparam  S_WAITING					= 4'd1,
    			S_CLEARING_SCREEN			= 4'd2,
    			S_CLEARING_SCREEN_FINISHED	= 4'd3,
    			S_DRAW_X_AXIS				= 4'd4,
    			S_DRAW_X_AXIS_FINISHED		= 4'd5,
                S_DRAW_X_TICKS              = 4'd6,
                S_DRAW_X_TICKS_FINISHED     = 4'd7,
    			S_DRAW_Y_AXIS				= 4'd8,
    			S_FINISHED					= 4'd9;				

    // Check for state changes and update
    always@(posedge clk)
    begin: state_updates
        if (reset == RESET_ON)
            current_state <= S_WAITING;
        else
            current_state <= next_state;
    end

    // State table
    always@(*)
    begin: state_table 
            case (current_state)
	            S_WAITING:						next_state = (start == ON) ?		S_CLEARING_SCREEN : S_WAITING; 

	            S_CLEARING_SCREEN:				next_state = (count == MAX_XY) ? 	S_CLEARING_SCREEN_FINISHED : S_CLEARING_SCREEN;
	            S_CLEARING_SCREEN_FINISHED: 	next_state = 						S_DRAW_X_AXIS;

	            S_DRAW_X_AXIS:					next_state = (count == X_MAX) ?		S_DRAW_X_AXIS_FINISHED : S_DRAW_X_AXIS;
	            S_DRAW_X_AXIS_FINISHED: 		next_state = 						S_DRAW_X_TICKS;

                S_DRAW_X_TICKS:                 next_state = (count == X_MAX) ?     S_DRAW_X_TICKS_FINISHED : S_DRAW_X_TICKS;
                S_DRAW_X_TICKS_FINISHED:        next_state =                        S_DRAW_Y_AXIS;

	            S_DRAW_Y_AXIS:					next_state = (count == Y_MAX) ? 	S_FINISHED : S_DRAW_Y_AXIS;
	            S_FINISHED:						next_state = 						S_FINISHED;

            default: next_state = S_WAITING;
        endcase
    end 

    // Output logic
    // Output logic aka all of our datapath control signals
    always @(*)
    begin: output_signals
        case (current_state)
            S_WAITING: begin
                counter_enabled <= OFF;
                end
            S_CLEARING_SCREEN: begin
                counter_enabled <= ON;
                col 			<= BLACK;
                X 				<= count[16:8];
                Y 				<= count[7:0];
                end
            S_CLEARING_SCREEN_FINISHED: begin
                counter_enabled <= OFF;
                end
            S_DRAW_X_AXIS: begin
                counter_enabled <= ON;
                col 			<= WHITE;
                X 				<= count[8:0];
                Y 				<= Y_CENTER;
                end
            S_DRAW_X_AXIS_FINISHED: begin
                counter_enabled <= OFF;
                end
            S_DRAW_X_TICKS: begin
                counter_enabled <= ON;
                col             <= (count[0] == 1'b0) ? WHITE : BLACK;
                X               <= count[8:0];
                Y               <= Y_CENTER - 1'b1;
                end
            S_DRAW_X_TICKS_FINISHED: begin
                counter_enabled <= OFF;
                end
            S_DRAW_Y_AXIS: begin
                counter_enabled <= ON;
                col 			<= WHITE;
                X 				<= X_CENTER;
                Y 				<= count[7:0];
                end
            S_FINISHED: begin
                counter_enabled <= OFF;
                end
        	default: begin
        		counter_enabled <= OFF;
        		col 			<= BLACK;
        		X 				<= 0;
        		Y 				<= 0;
        		end
        endcase
    end 

    // Counter - counter resets when disabled
    Counter c (
		.clk    	(clk),
		.enabled	(counter_enabled),
		.reset  	(reset),
		.count  	(count)
	);

    // Return output
    assign init_complete = (current_state == S_FINISHED);

endmodule

/*					STEPS 				*/

/*
	Clear the screen
	Go through all pixels on (x, y) of screen 
		Count: 0 to 2^(8+9+1)
	Paint each pixel black => RGB(0, 0, 0)
*/

/*
	Draw the x axis
	Go through all x until edge of the screen
		Count: 0 to 320
	Set Y = 120
	Paint each axis pixel white => RGB(1, 1, 1)
*/

/*
	Draw the y axis
	Set X = 160
	Go through all y until edge of the screen
		Count: 0 to 240
	Paint each axis pixel white => RGB(1, 1, 1)
*/