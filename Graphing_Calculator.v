
module Graphing_Calculator (
    input CLOCK_50,

    input [17:0] SW,
    input [3:0] KEY,
    
    output [17:0] LEDR,
    output [7:0] LEDG,
    
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [6:0] HEX4,
    output [6:0] HEX5,
    output [6:0] HEX6,
    output [6:0] HEX7,
    
    // The ports below are for the VGA output.  Do not change.
    output VGA_CLK,                         //  VGA clock
    output VGA_HS,                          //  VGA H_SYNC
    output VGA_VS,                          //  VGA V_SYNC
    output VGA_BLANK_N,                     //  VGA BLANK
    output VGA_SYNC_N,                      //  VGA SYNC
    output [9:0] VGA_R,                     //  VGA Red     [9:0]
    output [9:0] VGA_G,                     //  VGA Green   [9:0]
    output [9:0] VGA_B                      //  VGA Blue    [9:0]
    );

    // Button configs
    wire [3:0] nKey;            assign nKey     = ~KEY;
    assign LEDG[3:0] = nKey[3:0];

    // Adapter Plots & Stores the Pixels
    vga_adapter VGA (
            .resetn     (reset),
            .clock      (CLOCK_50),
            .colour     (col),
            .x          (X),
            .y          (Y),
            .plot       (plot),
            
            /* Signals for the DAC to drive the monitor. */
            .VGA_R      (VGA_R),
            .VGA_G      (VGA_G),
            .VGA_B      (VGA_B),
            .VGA_HS     (VGA_HS),
            .VGA_VS     (VGA_VS),
            .VGA_BLANK  (VGA_BLANK_N),
            .VGA_SYNC   (VGA_SYNC_N),
            .VGA_CLK    (VGA_CLK));
        defparam VGA.RESOLUTION = "320x240";
        defparam VGA.MONOCHROME = "FALSE";
        defparam VGA.BITS_PER_COLOUR_CHANNEL = 2;
        defparam VGA.BACKGROUND_IMAGE = "black.mif";

    // Control Input
    wire clk;                   assign clk      = CLOCK_50;
    wire reset;                 assign reset    = KEY[3];
    wire [2:0] degree;          assign degree   = SW[9:7];
    wire [6:0] constant;        assign constant = SW[6:0];
    wire [1:0] speed;           assign speed    = SW[11:10];
    wire go;                    assign go       = ~KEY[2];
    wire [5:0] col_in;          assign col_in   = SW[17:12];

    // VGA
    wire [8:0] X;
    wire [7:0] Y;
    wire [5:0] col;
    wire plot;                  //assign plot   = 1'b1; 

    // Init Input/Output
    wire [8:0] x_init;
    wire [7:0] y_init;
    wire [5:0] col_init;
    wire start_init;
    wire init_complete;

    // Function Input/Output
    wire out_of_bounds;
    wire load_f;
    wire [2:0] select_in;
    wire [2:0] calculate;
    wire [7:0] x_val;           // x that feeds into function

    wire [7:0] y_function;
    wire [8:0] x_function;
    wire [5:0] current_state;

    Init i (
    	.clk          (clk),
        .reset        (reset),
        .start        (start_init),    
    	.X            (x_init),        
    	.Y            (y_init),        
    	.col          (col_init),      
    	.init_complete(init_complete)  
   	);

    Control c (
        // Input
        .clk          (clk),
        .reset        (reset),
        .go           (go),        
        .degree       (degree),        
        .out_of_bounds(out_of_bounds),  
        .init_complete(init_complete),
        .speed        (speed),

        // Output
        .plot         (plot),           
        .load_f       (load_f),         
        .select_in    (select_in),      
        .calculate    (calculate),      
        .x_val        (x_val),          
        .x            (x_function),
        .state        (current_state),    
        .start_init   (start_init)      
    );

    Function_Generator f (
        // Input
        .clk          (clk),
        .reset        (reset),
        .x_val        (x_val),          
        .select_in    (select_in),      
        .calculate    (calculate),      
        .constant     (constant),        

        // Testing
        // .a_out        (a_out),
        // .b_out        (b_out),
        // .c_out        (c_out),
        // .d_out        (d_out),
        // .e_out        (e_out),
        // .n_out        (n_out),

        // Output
        .out_of_bounds(out_of_bounds),  
        .y            (y_function)      
    );


    // Makes finalized decisions on X, Y coords and colour
    Vga_Input_Selector v (
        // Input
        .clk         (clk),
        .reset       (reset),
        .load_f      (load_f),          
        .x_function  (x_function),      
        .y_function  (y_function),      
        .col_function(col_in),       
        .x_init      (x_init),          
        .y_init      (y_init),          
        .col_init    (col_init),        

        // Out
        .x_out       (X),               
        .y_out       (Y),        
        .col_out     (col)              
    );

    // Hex display instructions
    Input_Display display (
        .clk          (CLOCK_50),
        .current_state(current_state),
        .degree       (calculate),
        .constant     (constant),
        .hex_0        (HEX0),
        .hex_1        (HEX1),
        .hex_2        (HEX2),
        .hex_3        (HEX3),
        .hex_4        (HEX4),
        .hex_5        (HEX5),
        .hex_6        (HEX6),
        .hex_7        (HEX7)
    );

    // Current state, for debugging
    assign LEDR[5:0] = current_state;

endmodule