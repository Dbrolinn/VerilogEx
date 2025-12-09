/***********************************************************************************
 * PSDi 2018/19
 *
 * Lab 1 - Design and verification of a sequential square root calculator
 *
 *   This Verilog code is property of University of Porto
 *   Its utilization beyond the scope of the course Digital Systems Design
 *   (Projeto de Sistemas Digitais) of the Integrated Master in Electrical
 *   and Computer Engineering requires explicit authorization from the author.
 *
 *   jca@fe.up.pt, Oct 2018
 ***********************************************************************************
 * Authors of the module psdsqrt:
 *   - Beatriz Neves Garrido (up201504710@fe.up.pt | bianevesgarrido@gmail.com)
 *   - Ricardo Barbosa Sousa (up201503004@fe.up.pt | sousa.ricardobarb@gmail.com)
 ***********************************************************************************/
//`timescale 1ns / 1ns;

module psdsqrt_tb;

// general parameters
parameter CLOCK_PERIOD = 10;              // Clock period in ns
parameter MAX_SIM_TIME = 100_000_000;     // Set the maximum simulation time (time units=ns)


// Registers for driving the inputs:
reg  clock, reset;
reg  start, stop;
reg  [31:0] x;

// Registers used in the verification program:
parameter PRINT_EN = 1;   // Enables the print in simulation's mode
reg [31:0] i;             // Variable used to test the module with sereval possibilities
reg [15:0] testsqrt;      // Holds a possible result for the sqrt(xin)
reg [15:0] testbit;       // Testbit to execute the algorithm from MSB to LSB
reg [15:0] tempsqrt;      // Temporary value of sqrt(xin) - after all itereations, tempsqrt = sqrt(xin)
reg [15:0] iteration;     // Present iteration of the algorithm
reg [15:0] sqrt_value;    // Output of the verification task

// Wires to connect to the outputs:
wire [15:0] sqrt;


// Instantiate the module under verification:
psdsqrt psdsqrt_1
      (
	    .clock(clock), // master clock, active in the positive edge
        .reset(reset), // master reset, synchronous and active high

        .start(start), // set to 1 during one clock cycle to start a sqrt
        .stop(stop),   // set to 1 during one clock cycle to load the output registers

        .xin(x),       // the operands
        .sqrt(sqrt)
        );


//---------------------------------------------------
// Setup initial signals
initial
begin
  clock = 1'b0;
  reset = 1'b0;
  x = 0;
  start = 1'b0;
  stop  = 1'b0;
end

//---------------------------------------------------
// generate a 50% duty-cycle clock signal
initial
begin
  forever
    # (CLOCK_PERIOD / 2 ) clock = ~clock;
end

//---------------------------------------------------
// Apply the initial reset for 2 clock cycles:
initial
begin
  # (CLOCK_PERIOD/3)    // wait a fraction of the clock period to
                        // misalign the reset pulse with the clock edges:
  reset = 1;
  # (2 * CLOCK_PERIOD ) // apply the reset for 2 clock periods
  reset = 0;
end

//---------------------------------------------------
// Set the maximum simulation time:
initial
begin
  # ( MAX_SIM_TIME )
  $stop;
end

/***********************************************************************************/
/*************************** VERIFICATION PROGRAM(BEGIN) ***************************/

initial
begin
  #( 10*CLOCK_PERIOD );            // Wait 10 clock periods
  reset=1'b1;                      // Execute the reset in the module

  #( 2*CLOCK_PERIOD );             // Wait 10 clock periods
  reset=1'b0;

  #( 10*CLOCK_PERIOD );            // Wait 10 clock periods
  execsqrt( 0 );                   // Test the square root of zero

  for(i = 0; i < 32; i=i+1) begin
    execsqrt( (1<<i) );            // Test the square root of xin_test - powers of 2
  end
  for(i = 0; i < 32; i=i+1) begin
    execsqrt( (1<<i) + i );        // Test the square root of xin_test - random values
  end

  #( 10*CLOCK_PERIOD );            // Wait 10 clock periods
  reset=1'b1;                      // Execute the reset in the module

  #( 2*CLOCK_PERIOD );             // Wait 10 clock periods
  reset=1'b0;

  #( 10*CLOCK_PERIOD );            // Wait 10 clock periods
  $stop;                           // Stops the simulation after the tests are executed or the MAX_SIM_TIME is reached
end

/**************************** VERIFICATION PROGRAM(END) ****************************/
/***********************************************************************************/


//---------------------------------------------------
// Execute a sqrt by simulate the module's execution:
task execsqrt;
input [31:0] xin;
begin
  x = xin;                        // Apply operands
  @(negedge clock);
  start = 1'b1;                   // Assert start
  @(negedge clock );
  start = 1'b0;
  repeat (16) @(posedge clock);   // Execute division
  @(negedge clock);
  stop = 1'b1;                    // Assert stop
  @(negedge clock);
  stop = 1'b0;
  @(negedge clock);

  // Print the results:
  // You may not watt to do this when verifying some millions of operands...
  // Add a flag to enable/disable this print
  verifysqrt(xin, sqrt_value);
  if (PRINT_EN)
    $display("SQRT(%d) = %d (expected value = %d)", x, sqrt, sqrt_value);

end
endtask

/***********************************************************************************/
/************************** VERIFICATION SQRT TASK(BEGIN) **************************/
task verifysqrt;
input  [31:0] xin_sqrt;
output [15:0] sqrt_output;

begin
  tempsqrt=0;       // Initial value to the final result
  testbit=1<<15;    // Variable used for building the result from the MSB to the last significant bit

  for(iteration=0;iteration<16;iteration=iteration+1) begin    // Number of itereations necessary = number of bits in the input / 2
    testsqrt = testbit | tempsqrt;
    if(xin_sqrt>=testsqrt*testsqrt) begin    // testsqrt*testsqrt is the tentative result
      tempsqrt=testsqrt;                     // If true, the final result (sqrt) is greater or equal to testsqrt
    end
    testbit = testbit>>1;                    // Test next bit
  end
  sqrt_output=tempsqrt;

end
endtask

/*************************** VERIFICATION SQRT TASK(END) ***************************/
/***********************************************************************************/

endmodule
