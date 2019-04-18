/*
	Returns a value for converting a 
	50 MHz clock into the following 
	frequencies

	when select is 
	1 -> 5 * 10^7 Hz
	2 -> 1 Hz
	3 -> 0.5 Hz
	4 -> 0.25 Hz
*/
module FrequencySelector (
	input [1:0] select,
	output reg [31:0] out
	);
	
    localparam  // Set rate divider starting vlues
                FR_10 = 32'd5_000_000,
                FR_20 = 32'd2_500_000,
                FR_40 = 32'd1_250_000;
    
	always @(*) 
	begin
		case (select[1:0]) 
			2'b00: out = {32{1'b0}} + 1'b1; 
			2'b01: out = FR_10;
            2'b10: out = FR_20;
            2'b11: out = FR_40;
			default: out = {32{1'b0}};
		endcase 
	end
endmodule