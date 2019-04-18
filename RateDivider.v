/*
    Counts from startValing value down 
    to 0 at the given clock speed
*/
module RateDivider (
    input [31:0] startVal,          
    input reset,
    input enable,
    input clk,
    output reg [31:0] count
    );

    always @(posedge clk)
    begin
        if (reset == 1'b0)
            count <= 0;
        else if (count == {32{1'b0}}    )
            count <= startVal;
        else if (enable == 1'b1)    // Counts only with enable on
            count <= count - 1'b1;
        else                        // Loads start value if enable is off
            count <= startVal;
    end
    
endmodule