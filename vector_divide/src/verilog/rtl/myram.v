
/*
FEUP / MEEC - Digital Systems Design 2025/2026

Generic Dual-port RAM memory

Memory access timing diagram:

         ____      ____     ____     ____     ____     ____     ____     ____
CLK  ___/    \____/    \___/    \___/    \___/    \___/    \___/    \___/    \___
     ____ _________ _________ ________________ _________________ ________________
ADDR ____X_________X_________X________________X_________________X________________
      A0      A1        A2           A3               A4               A5	  
     ____ _________ _________ ________ _________________ ________________ _______
Rdata____X_________X_________X________X_________________X________________X_______
     ???   Mem[A0]   Mem[A1]   Mem[A2]      Mem[A3]           Mem[A4]     Mem[A5]

                                                _________           _________
Wenable________________________________________/         \_________/         \___

     ________________________________________ _________________ _________________
Wdata________________________________________X_________________X_________________
                         ????                  data to addr A4    data to addr A5


*/

`timescale 1ns/1ns

module myRAM
       #( 
		   parameter RAMSIZE=1924, 
	       parameter DATAWIDTH=32 )
        (
		   // Port 1:
           input clock1,
		 
		   input [$clog2( RAMSIZE )-1 :0] addr1,   // Read/Write address
		   input [DATAWIDTH-1:0]          Wdata1,  // Data to write to RAM
		   output reg [DATAWIDTH-1:0]     Rdata1,  // Data read from RAM

		   input Wenable1,                         // Write enable


         // Port 2:
           input clock2,
		 
		   input [$clog2( RAMSIZE )-1 :0] addr2,   // Read/Write address
		   input [DATAWIDTH-1:0]          Wdata2,  // Data to write to RAM
		   output reg [DATAWIDTH-1:0]     Rdata2,  // Data read from RAM

		   input Wenable2                          // Write enable
		 
		 );
		 

// RAM with 64 locations of 32 bits each:
reg [DATAWIDTH-1:0] MYRAM[0:RAMSIZE-1];

//------ RAM Initialization ---------------------------------
// How to initialize the RAM at compile time:
integer i, Nwords;

integer ii;

initial
begin

`ifndef SYNTHESIS
    $display("Nbits of address bus: %d", $clog2( RAMSIZE ) );
	$display("Initializing memory with data read from %s", "./datafile.hex" );
`endif	 

//############################################################################
// Fill whole RAM with some data known at compile time:
//  for(ii=0; ii<RAMSIZE; ii=ii+1)
//    MYRAM[ ii ] = ii+ii;


// Alternative ways to initializa a RAM block:


//############################################################################
// Fill RAM from data files:
// the datafile entries must have the same number of bits as the RAM locations

// Fill RAM	with data read from a text file with one RAM location per line, in hex format:

`ifndef SYNTHESIS
	$display("Initializing memory with data read from %s", "./datafile.hex" );
`endif	 
 	 $readmemh( "./datafile.hex", MYRAM );

// Fill RAM	with data read from a text file with one RAM location per line, in binary format:
// 	 $readmemb( "./datafile.bin", MYRAM );

//############################################################################
// Read the RAM contents, count the number of data values read from file,
// and fill the rest of the RAM with zeros:

  Nwords = RAMSIZE; // Nwords defaults to the RAM size
  for(i=0; i<RAMSIZE; i=i+1)
  begin
    if ( MYRAM[i] === 'hX )
	 begin
// Register the number of words read to variable "Nwords", may be useful for
// implementing a testbench:
	  Nwords = i;
// "Soft" break the loop:
	  i = RAMSIZE;
	end

      // just to confirm: print the contents of the RAM after initialization:
`ifndef SYNTHESIS
	else
	  $display("RAM[%3d] = %d (%08Hh)", i, MYRAM[i], MYRAM[i] );
`endif

  end
  
`ifndef SYNTHESIS
    $display("Read %d words from data file.", Nwords );
`endif
  
  $display("Nwords:%d, RAMSIZE:%d\n", Nwords, RAMSIZE);
  
// Complete the initialization of the RAM, fill the rest with zeros:
  for(i=Nwords; i<RAMSIZE; i=i+1)
    MYRAM[i] = 0;
end


//------ END OF RAM Initialization ---------------------------------


//------- RTL description of synchronous RAM ------------------------
// ------ Port 1:
// Write/read synchronous process:
always @(posedge clock1)
begin

  if ( Wenable1 )
    MYRAM[ addr1 ] <= Wdata1;
	
  Rdata1 <= MYRAM[ addr1 ];
end

//------ Port 2:
// Write/read synchronous process:
always @(posedge clock2)
begin

  if ( Wenable2 )
    MYRAM[ addr2 ] <= Wdata2;
	
  Rdata2 <= MYRAM[ addr2 ];
end

		 
endmodule
