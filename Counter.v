/*
Counter:
Inputs
	enabled: 				(1 bit)
	reset: 			 		(1 bit)
	clk: 			 		(1 bit)
Outputs
	count:					(18 bit)
*/

module Counter (
	// If enabled is turned off, count is reseted
	input clk,
	input enabled,
	input reset,			// Asynchronous reset active low
	//input restart,
	output reg [17:0] count
);

	always @(posedge clk) 
	begin
		if(reset == 1'b0) begin
			count <= 0;
		// end else if (restart == 1'b1) begin
		// 	count <= 0;
		end else if (count == {18{1'b1}}) begin
			count <= 0;
		end else if (enabled == 1'b1) begin
			count <= count + 1'b1;
		end else begin
			count <= 0;
		end
	end

endmodule