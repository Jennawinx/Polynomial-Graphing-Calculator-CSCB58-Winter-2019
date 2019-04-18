module Function_Generator (
    input clk,
    input reset,
    input signed [7:0] x_val,
	input [2:0] select_in, // which register to store
	input [2:0] calculate,
	input signed [6:0] constant,
	
	output reg out_of_bounds,
	output [7:0] y,
    output wire signed [6:0] a_out, b_out, c_out, d_out, e_out, n_out
	);
	/*
	Module that given a signed x_val calculates a y value according to the function
	stored in the registers.
	*/
	
	localparam signed // Constants for screen bounds
                      Y_MAX = 120,
                      Y_MIN = -120,
                      // Negative 1
                      NEG = {32{1'sb1}};
	
	// Internal registers
	reg signed [6:0] a, b, c, d, e; // Roots of the function
	reg [5:0] n; // Used as scaling constant n in equation 1/2^n
    reg s; // Used to reflect function across axes
    
    assign a_out = a;
    assign b_out = b;
    assign c_out = c;
    assign d_out = d;
    assign e_out = e;
    assign n_out = n;
    
	reg signed [31:0] y_temp_signed; // Stores initial calculation of y
	wire[31:0] y_temp; // Stores y value that checks for boundary
    
	// Should an initialization be put here?

	// Selects registers that constant is stored into
	// Should sequential be put into one giant always block?
	always @(posedge clk)
	begin
	    if (!reset) begin
		    a = {7{1'b0}};
			b = {7{1'b0}};
			c = {7{1'b0}};
			d = {7{1'b0}};
			e = {7{1'b0}};
			n = {3{1'b0}};
            s = 1'b0;
			end
	    else begin
		    case(select_in)
				3'b001 : a = constant;
				3'b010 : b = constant;
				3'b011 : c = constant;
				3'b100 : d = constant;
				3'b101 : e = constant;
				3'b110 : n = constant[5:0];
                3'b111 : s = constant[0];
				default : begin // Set defaults
				         a = a;
					     b = b;
					     c = c;
					     d = d;
					     e = e;
					     n = n;
                         s = s;
				    end
			endcase
		end
	end
	
	// Calculates y based on the degree
	always @(*)
	begin
	    if (!reset)
		    y_temp_signed <= {32{1'sb0}};
		else begin
		    case(calculate)
			    3'b000: y_temp_signed = 0;
			    3'b001: y_temp_signed = (x_val - d);
				3'b010: y_temp_signed = (x_val - c)*(x_val - d);
				3'b011: y_temp_signed = (x_val - b)*(x_val - c)*(x_val - d);
				3'b100: y_temp_signed = (x_val - a)*(x_val - b)*(x_val - c)*(x_val - d);
				default: y_temp_signed = {32{1'sb0}};
			endcase
            y_temp_signed = s ? y_temp_signed * (NEG) : y_temp_signed; // Flips if sign bit is on
			y_temp_signed <= (y_temp_signed >>> n) + e; // ARS based on scaling value
		end
	end

	// Sends out of bounds signal if y is too large
	always @ (*)
	begin
	    if (!reset)
		    out_of_bounds = 1'b0;
		else begin
		    if (y_temp_signed > Y_MAX || y_temp_signed < Y_MIN)
			   out_of_bounds = 1'b1;
            else
               out_of_bounds = 1'b0;
	    end
	end
	
	// Combinational logic
	assign y_temp = Y_MAX - y_temp_signed;
	assign y = y_temp[7:0];
		
endmodule
	