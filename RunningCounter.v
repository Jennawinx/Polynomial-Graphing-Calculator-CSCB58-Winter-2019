
/*
    Automatically counts from 0 - F 
    (on repeat) at the given speed
*/
module RunningCounter (
    input [1:0] selectfreq,
    input reset,
    input enable,
    input clk,
    output [17:0] out
    );

    wire [31:0] freqConvertVal;
    wire [31:0] count;
    wire isEnabled;
    
    FrequencySelector f (
        .select(selectfreq),
        .out(freqConvertVal)
    );
    
    RateDivider r (
        .startVal(freqConvertVal),
        .reset(reset),
        .enable(enable),
        .clk(clk),
        .count(count)
    );
    
    assign isEnabled = (count == {32{1'b0}}) ? 1 : 0;
    
    DisplayCounter c (
        .reset(reset),
        .counting(isEnabled),
        .enable(enable),
        .clk(clk),
        .count(out)
    );
    
endmodule