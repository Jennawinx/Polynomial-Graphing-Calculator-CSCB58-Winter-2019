/*
Control:
    Inputs
        degree:                     SW[9:7]     (3 bits)
        go:                         ~KEY[1]     (1 bit)
        reset:                      ~KEY[0]     (1 bit)
        clk:                        CLOCK_50    (1 bit)
        out_of_bounds: function_generator -->   (1 bit)
        init_complete: initialization -->       (1 bit)
        speed -->                               (2 bit)
    Outputs
        plot:       1 bit --> VGA
        load_f:     1 bit --> vga_input
        select_in:  3 bit --> function_generator         (selects regs that switches go into)
        calculate:  3 bit --> function_generator
        x_val:      7 bit --> function_generator (signed graph version)
        x:          9 bit --> vga_input (unsigned VGA version)
        start_init: 1 bit --> initialization
*/

// ###################################################
//                      Notes
// I added counter, tho counter always starts at 0
// and resets when you disable it, so you may need to
// do some math when feeding x into the function
// ###################################################

module Control (
    input clk,
	input reset,
	input go,
	input [2:0] degree,
	input out_of_bounds,
	input init_complete,
    input [1:0] speed,
	
	output reg plot,
	output reg load_f,
	output reg [2:0] select_in,
	output reg [2:0] calculate,
	output reg signed [7:0] x_val,
	output reg [8:0] x,
    output [5:0] state,
    output reg start_init
    // Testing output below
	);
	
    //** Internal registers and wires**//
    // Plot registers
    reg counter_enabled;            // counter enabled
    wire signed [17:0] count;
    // State registers
    reg [5:0] current_state, next_state;
    // Frame rate register
    reg [1:0] FR;

    localparam  // Screen bounds for counter
                X_MAX                       = 18'sd320,
                
                // Select codes
                LOAD_A                      = 3'b001,
                LOAD_B                      = 3'b010,
                LOAD_C                      = 3'b011,
                LOAD_D                      = 3'b100,
                LOAD_E                      = 3'b101,
                LOAD_N                      = 3'b110,
                LOAD_S                      = 3'b111,

                // Booleans
                ON                          = 1'b1, // Active high
                OFF                         = 1'b0,
                RESET_ON                    = 1'b0, // Active low
                RESET_OFF                   = 1'b1;

	// State regs
    localparam  S_INITIALIZATION     = 6'd0,
                S_LOAD_DEGREE        = 6'd1,    // add an extra state here
                S_LOAD_DEGREE_WAIT   = 6'd2,
                S_LOAD_A             = 6'd3,
                S_LOAD_A_WAIT        = 6'd4,
                S_LOAD_B             = 6'd5,
                S_LOAD_B_WAIT        = 6'd6,
                S_LOAD_C             = 6'd7,
                S_LOAD_C_WAIT        = 6'd8,
                S_LOAD_D             = 6'd9,
                S_LOAD_D_WAIT        = 6'd10,
                S_LOAD_E             = 6'd11,
                S_LOAD_E_WAIT        = 6'd12,
                S_LOAD_N             = 6'd13,
                S_LOAD_N_WAIT        = 6'd14,
                S_LOAD_S             = 6'd15,
                S_LOAD_S_WAIT        = 6'd16,
                S_PLOT               = 6'd17,
                S_PLOT_FINISHED      = 6'd18;    // ##### NEED THIS IN USING COUNTER #####
                
    
    // Next state logic
    always @ (*)
    begin
        case (current_state)
            S_INITIALIZATION:       next_state = init_complete      ? S_LOAD_DEGREE         : S_INITIALIZATION;
            S_LOAD_DEGREE:          next_state = go                 ? S_LOAD_DEGREE_WAIT    : S_LOAD_DEGREE; // Loop in current state until input
            S_LOAD_DEGREE_WAIT: begin
                if (go)
                   next_state = S_LOAD_DEGREE_WAIT;
                else begin
                    case(degree)
                        3'b000:     next_state = S_LOAD_E;
                        3'b001:     next_state = S_LOAD_D;
                        3'b010:     next_state = S_LOAD_C;
                        3'b011:     next_state = S_LOAD_B;
                        3'b100:     next_state = S_LOAD_A;
                        default:    next_state = S_LOAD_DEGREE;
                    endcase
                end
            end
            S_LOAD_A:        next_state = go ? S_LOAD_A_WAIT : S_LOAD_A;
            S_LOAD_A_WAIT:   next_state = go ? S_LOAD_A_WAIT : S_LOAD_B;
            S_LOAD_B:        next_state = go ? S_LOAD_B_WAIT : S_LOAD_B;
            S_LOAD_B_WAIT:   next_state = go ? S_LOAD_B_WAIT : S_LOAD_C;
            S_LOAD_C:        next_state = go ? S_LOAD_C_WAIT : S_LOAD_C;
            S_LOAD_C_WAIT:   next_state = go ? S_LOAD_C_WAIT : S_LOAD_D;
            S_LOAD_D:        next_state = go ? S_LOAD_D_WAIT : S_LOAD_D;
            S_LOAD_D_WAIT:   next_state = go ? S_LOAD_D_WAIT : S_LOAD_E;
            S_LOAD_E:        next_state = go ? S_LOAD_E_WAIT : S_LOAD_E;
            S_LOAD_E_WAIT:   next_state = go ? S_LOAD_E_WAIT : S_LOAD_N;
            S_LOAD_N:        next_state = go ? S_LOAD_N_WAIT : S_LOAD_N;
            S_LOAD_N_WAIT:   next_state = go ? S_LOAD_N_WAIT : S_LOAD_S;
            S_LOAD_S:        next_state = go ? S_LOAD_S_WAIT : S_LOAD_S;
            S_LOAD_S_WAIT:   next_state = go ? S_LOAD_S_WAIT : S_PLOT;
            S_PLOT:          next_state = (count == X_MAX + 1) ? S_PLOT_FINISHED : S_PLOT;
            S_PLOT_FINISHED: next_state = S_INITIALIZATION;     // #### Allow user to plot another function

        endcase
    end
    
    // Output logic, datapath control signals
    always @(*)
    begin: enable_signals
        // Set default control signals
        start_init      = OFF;
        select_in       = 3'b000;
        load_f          = ON;
        plot            = plot;
        counter_enabled = OFF;
        calculate       = calculate;
        
        // Maintain x values
        x_val  = x_val;
        x      = x;
        
        // Case statement output logic
        case (current_state)
            S_INITIALIZATION: begin
                plot        = ON;
                start_init  = ON;
                load_f      = OFF;          // Load from initialization
                x_val       = {7{1'b0}};    
                x           = {9{1'b0}};
                counter_enabled = OFF;
                end
            S_LOAD_DEGREE: begin            // Opportunity to display degree and store
                plot        = OFF;
                start_init  = OFF;
                calculate   = degree;
                FR          = speed;
                end
            S_LOAD_A: select_in = LOAD_A;
            S_LOAD_B: select_in = LOAD_B;
            S_LOAD_C: select_in = LOAD_C;
            S_LOAD_D: select_in = LOAD_D;
            S_LOAD_E: select_in = LOAD_E;
            S_LOAD_N: select_in = LOAD_N;
            S_LOAD_S: select_in = LOAD_S;
            S_PLOT: begin
                load_f          = ON;
                plot            = out_of_bounds ? OFF : ON;
                counter_enabled = ON;
                
                // x_val fed in
                x = count[8:0];
                x_val = count[7:0]; 
                x_val = x_val - 8'sd160;
                end
            S_PLOT_FINISHED: begin
                plot = OFF;
                counter_enabled = OFF;
                end
        endcase     
    end

    // Updates current state
    always @(posedge clk)
    begin
        if (reset == RESET_ON)
            current_state = S_INITIALIZATION;
        else
            current_state = next_state;
    end
    
    // Combinatorial logic
    assign state = current_state;
    
    // Counter - counter resets when disabled
    RunningCounter c (
        .selectfreq (FR),
        .clk        (clk),
        .enable     (counter_enabled),
        .reset      (reset),
        .out        (count)
    );

endmodule