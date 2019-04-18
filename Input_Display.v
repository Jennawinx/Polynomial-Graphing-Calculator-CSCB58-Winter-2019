module Input_Display (
	input clk,    // Clock
	input [5:0] current_state,
	input [2:0] degree,
	input [6:0] constant,
	output [6:0] hex_5, hex_6, hex_7,
	output reg [6:0] hex_0, hex_1, hex_2, hex_3, hex_4
);

	localparam 	// Booleans
				ON 					 = 1'b1,
				OFF 				 = 1'b0;

	// States to custom display input for
	localparam  S_INITIALIZATION     = 6'd0,
                S_LOAD_DEGREE        = 6'd1,    
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
                S_PLOT_FINISHED      = 6'd18;
                
	// Display the degree and value
	Hex_Display h7 (5'b01101, hex_7); // d
	Hex_Display h6 (degree, hex_6);

	// Display Load Instruction
	Hex_Display h5 (5'b10010, hex_5); // L

	// Determine the load instruction from the current state
	reg show_sign;
	reg [6:0] constant_Input, abs_Input;
	wire [11:0] constant_Output;

	always @(posedge clk)
	begin
		// Default displayed input values to show in demical
		show_sign = ON;
		hex_0 = h0;
		hex_1 = h1;
		hex_2 = h2;
		hex_4 = 7'b1111111; // Blank
		constant_Input = {7{1'b1}};
		case (current_state)
	        S_LOAD_DEGREE:
	        	begin
	        		constant_Input <= constant;
	        		show_sign = OFF;
	        		hex_4 <= 7'b0100001; // d
	        		hex_2 = 7'b1111111; // Blank
	        		hex_1 = 7'b1111111; // Blank
	        		hex_0 = 7'b1111111; // Blank
	        	end
	        S_LOAD_A:
	        	begin
	        		hex_4 <= 7'b0001000; // A
	        		constant_Input <= constant;
	        	end
	        S_LOAD_B:
	        	begin
	        		hex_4 <= 7'b0000011; // b
	        		constant_Input <= constant;
	        	end
	        S_LOAD_C:
	        	begin
	        		hex_4 <= 7'b1000110; // C
	        		constant_Input <= constant;
	        	end
	        S_LOAD_D:
	        	begin
	        		hex_4 <= 7'b0100001; // d
	        		constant_Input <= constant;
	        	end
	        S_LOAD_E:
	        	begin
	        		hex_4 <= 7'b0000110; // E
	        		constant_Input <= constant;
	        	end
	        S_LOAD_N:
	        	begin
	        		hex_4 <= 7'b0101011; // n
	        		constant_Input <= constant;
	        		show_sign = OFF;
	        	end
	        S_LOAD_S:
	        	begin
	        		hex_4 <= 7'b0010010; // S
	        		show_sign = OFF;
	        		// Set displayed input values to pos or neg
	        		if (constant[0] == 1'b0) begin
	        			hex_2 = 7'b0001100;	// p
	        			hex_1 = 7'b1000000;	// 0
	        			hex_0 = 7'b0010010; // 5
	        			end
	        		else begin
	        			hex_2 = 7'b1001000;	// N
	        			hex_1 = 7'b0000110; // E
	        			hex_0 = 7'b0010000; // g
		        		end
	        	end
	        default: 
	        	begin
	        		hex_4 <= 7'b1111111; // Blank
	        		constant_Input <= constant;
	        	end
	    endcase
	end

	// --------------------------------------
    //    Display input value in decimal
    // --------------------------------------

    // Check if input value is negative
    always @(posedge clk)
    begin
	    if (constant[6] == 1'b1 && show_sign) begin
	    	hex_3 <= 7'b0111111; // -
	    	abs_Input <= ~(constant - 1'b1); // Reverse 2's complement
	    	end
	    else begin
	    	hex_3 <= 7'b1111111; // Blank
	    	abs_Input <= constant_Input[5:0];
	    end
    end

    // Recalculate if the input changes
    reg [6:0] last_constant;
    reg recalculate;
    wire conversion_finished; // no need

    always @(posedge clk)
    begin
        if (last_constant != abs_Input) begin
            last_constant <= abs_Input;
            recalculate <= ON;
            end
        else
            recalculate <= OFF;
    end

    // Convert binary input value to BCD
    Binary_To_BCD b (
    	.i_Clock (clk),
    	.i_Start (recalculate),
    	.i_Binary(abs_Input),
    	.o_BCD   (constant_Output),
    	.o_DV    (conversion_finished)
    );

    wire [6:0] h0, h1, h2;

    // Read BCD values and convert to decimal
    Hex_Display hex0 (constant_Output[3:0], h0);
    Hex_Display hex1 (constant_Output[7:4], h1);
    Hex_Display hex2 (constant_Output[11:8], h2);

endmodule