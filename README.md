
# Polynomial Graphing Calculator ( CSCB58 Winter 2019 )
By Linda Lo and Jenny Quach

## What's the Project?

Our project is to create a graphing calculator that can graph polynomial  functions up to 4 degrees. This calculator allows the user to specify a degree function they would like to graph. After which, the user would provide values to customize and transform the parent function of that degree into something more complex for plotting on screen. For each degree, the user must provide the roots of the function (a, b ... up to d), a vertical translation factor (e), a vertical compression factor (n), and select whether they would like to reflect the graph across the x-axis. For example, the formula for a 4th degree function would take in the form y = s(1/2^n)(x - a)(x - b)(x - c)(x - d) + e 

## Controls
| Input | Controls | Notes
|--|--|--|
| RGB Colour | SW[17:12] | Each colour is 2-bit
| Draw Speed | SW[11:10] | 0 - Instantaneous (off); 1-3 - increase speed 
| Degree | SW[9:7] | Degree input
| Values | SW[0:6] | Load Constants
| Reset | Key 3 | Reset & Clear Graph
| Go | Key 2 | Continue

## Video 
Watch live demo here: [https://youtu.be/HUC2An-jvmg](https://youtu.be/HUC2An-jvmg)

---
---

## Description of Structure of Graphing Calculator

Our program consists of a top level module, an input display module, master control and datapath that contains 4 modules responsible for the functionality of the program.  First we will describe the datapath, then the functionality of the control.

**Init:**

The first module in the datapath is the init module, which is responsible for drawing the axis every time the program is reset.  It receives a start, reset and clock input and outputs X, Y and colour to the VGA Module as well as an init complete signal back to the control.  Once it receives a pulse from start, it runs it's on its own finite state machine to erase the screen and then initialize the axes.

**Function Generator:**

This module is responsible for calculating the y values based on the function given by the user.  It contains 6 internal registers that stores the 4 constants, n value and 1 bit sign value (determines whether the function should be fliped).  The control uses a 3 bit select in value to determine which register is loaded from the switches.

In addition to storing the constants, this function takes in reset, clock, calculate and the x_value it needs to calculate.  The reset clears all the registers, but otherwise this function is continuously computing a 32 bit y value based on the degree passed in through the calculate input. The function is chosen using a case statement, and then the y_value is shifted n bits based on the compression factor and translated up by the constant e.  Finally, the y_value is translated to a coordinate on the screen by subtracting it from 120 and taking only the last 8 bits.

Finally, the function generator is also responsible for checking that
the y_val is not out of screen bounds by checking that the full 32 bit
value is within screen bounds.  Otherwise, it outputs a out_of_bounds signal
that tells the control to turn plot off while y is out of bounds.

**VGA Input Selector:**

Determines whether the VGA module receives input from the function generator/control/colour switches or from the init module.  It is controled by the load_f signal from the control module, which when high loads from the function generator. It also receives reset and clock input.

**VGA Module:**

Given plot, 6 bit colour input, 9 bit x input and 8 bit y input this module will
output a pixel to the VGA display.

**Control:**

The control module is the finite state machine for the entire program and in addition to the signals received from other modules above, it takes in a clock, reset, the degree and speed of plotting.  It controls the plotting via a x that is incremented by a counter and the x directly in the VGA module.  It supplies the function generator with an adjusted x_value as well (x - 160) for calculation purposes.  The running counter that updates the x only runs if it is enabled, once enable turns off it resets completely.  Besides enable, this internal module also takes in a reset, clock and frequency input that feed from an internal register which stores the speed from
the switches.

The finite state machine contains 19 states, 16 of which are used to load values
from the user (2 states per value for a total of 8 needed: degree, 4 constants, E for
translation, n for compression and s for flipping).  By default, start_init is OFF, select_in is set to 000 (does not load anything in the function generator), load_f is ON, counter is OFF, and plot, calculate and x values maintain their previous value.
 
The first state is the initialization state which moves to the first load degree state
when the control receives the init_complete signal.  In the init state, plot is ON,
load_f is OFF, the counter is OFF and x/y values are reset.  Once in load_degree state plot is OFF, start_init is OFF and the internal registers for calculate and FR (speed) are loaded from the switches into control.  Once go is pressed, it transitions to LOAD_A, B C, etc. where the only change in signal is that select_in is set to the appropriate signal so the function generator knows which constant is being loaded.

The last two states are plot and plot_finished which are used to graph the function and reset the signals after graphing is finished.  Once in plot state, load_f is turned ON, plot is turned on only if out_of_bounds is OFF and the x_values are set appropriately based on the counter.  When count reaches the max, the state transitions to plot finished where plot and counter are both turned OFF.

**Counter:**

The counter module is based on the module we designed in Practical 004 except it was modified so that it only runs when enable is on, and resets when it turns off.  The Running counter contains a frequency selector, rate divider and display counter.  The frequency selector receives the input speed and picks the appropriate value for the rate dividor to count down from.  This module can set to speed to instant (based on 50 MHz clock), 10, 20 and 40 frames per second.   The rate divider then counts down by the value given by frequency selector and display counter only increments when rate divider is 0.
