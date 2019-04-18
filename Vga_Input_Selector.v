module Vga_Input_Selector(
    input clk,
	input reset,
	input load_f,
	
	input [8:0] x_function,
	input [7:0] y_function,
	input [5:0] col_function,
	
	input [8:0] x_init,
	input [7:0] y_init,
	input [5:0] col_init,
	
	output reg [8:0] x_out,
	output reg [7:0] y_out,
	output reg [5:0] col_out
	);
	
	/*
	Module that stores values going into the VGA to determine what is
	plotted.  Controls where input is taken from.
	*/
	
	// Set input for output regs
	always @(posedge clk)
	begin
	    if (reset == 1'b0) begin
			x_out <= {9{1'b0}};
			y_out <= {8{1'b0}};
			col_out <= {3{1'b0}};
			end
		else if (load_f) begin
		    x_out <= x_function;
			y_out <= y_function;
			col_out <= col_function;
			end
		else begin
		    x_out <= x_init;
			y_out <= y_init;
			col_out <= col_init;
		end
	end
endmodule