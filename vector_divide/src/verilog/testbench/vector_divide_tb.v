`timescale 1ns/1ns

module vector_divider_tb;

    // Parameters matches your design
    parameter RAM_SIZE = 10;
    parameter N = 5;
    parameter NBITS = 32;

    // Testbench Signals
    reg clock;
    reg reset;
    reg startvd;
    wire busyvd;

    // RAM Interface Signals (for Port 2 - connected to Vector Divider)
    wire [RAM_SIZE-1:0] Addr2;
    wire [NBITS-1:0] Wdata2;
    wire [NBITS-1:0] Rdata2;
    wire Wenable2;

    // RAM Interface Signals (for Port 1 - used by Testbench to read/verify)
    reg [RAM_SIZE-1:0] Addr1;
    reg [NBITS-1:0] Wdata1; // Not used in this test
    wire [NBITS-1:0] Rdata1;
    reg Wenable1;           // Not used in this test

    // Number of elements to process
    reg [RAM_SIZE-1:0] Ndata;

    // Instantiate the Dual-Port RAM
    // Port 1: Controlled by Testbench (for dumping results)
    // Port 2: Controlled by Vector Divider (for processing)
    myRAM #(
        .RAMSIZE(1024),
        .DATAWIDTH(32)
    ) u_ram (
        // Port 1 (Testbench view)
        .clock1(clock),
        .addr1(Addr1),
        .Wdata1(Wdata1),
        .Rdata1(Rdata1),
        .Wenable1(Wenable1),

        // Port 2 (Vector Divider view)
        .clock2(clock),
        .addr2(Addr2),
        .Wdata2(Wdata2),
        .Rdata2(Rdata2),
        .Wenable2(Wenable2)
    );

    // Instantiate your Vector Divider Design
    vector_divider #(
        .RAM_SIZE(RAM_SIZE),
        .N(N),
        .NBITS(NBITS)
    ) u_dut (
        .clock(clock),
        .reset(reset),

        // RAM Interface (Connecting to Port 2)
        .Addr(Addr2),
        .Wdata(Wdata2),
        .Rdata(Rdata2),
        .Ndata(Ndata),
        .Wenable(Wenable2),

        // Control Interface
        .startvd(startvd),
        .busyvd(busyvd)
    );

    // Clock Generation
    initial begin
        clock = 0;
        forever #5 clock = ~clock; // 10ns period
    end

    // Main Test Sequence
    initial begin
        // 0. Initialize Signals
        reset = 1;
        startvd = 0;
        Addr1 = 0;
        Wdata1 = 0;
        Wenable1 = 0;
        // Set number of pairs to process.
        // Example: Process 3 pairs (Addresses 0-1, 2-3, 4-5)
        Ndata = 3;

        // 1. Load RAM with known data
        // Note: In a real lab, you might use $readmemh in myram.v.
        // Here, we force data into the RAM array directly for simplicity
        // as allowed by the "RAM Initialization" logic in myram.v
        // Pair 1: 100 / 20 -> Q=5, R=0
        u_ram.MYRAM[0] = 32'd100;   // Dividend
        u_ram.MYRAM[1] = 32'd20;    // Divisor

        // Pair 2: 50 / 3 -> Q=16, R=2
        u_ram.MYRAM[2] = 32'd50;
        u_ram.MYRAM[3] = 32'd3;

        // Pair 3: 200 / 100 -> Q=2, R=0
        u_ram.MYRAM[4] = 32'd200;
        u_ram.MYRAM[5] = 32'd100;

        $display("--- Starting Simulation ---");
        $display("Loaded Data:");
        $display("Pair 1: 100 / 20");
        $display("Pair 2: 50 / 3");
        $display("Pair 3: 200 / 100");

        // 2. Reset the System
        #20;
        reset = 0;
        #20;

        // 3. Start the Vector Division Module
        $display("Asserting Start...");
        @(posedge clock);
        startvd = 1;
        @(posedge clock);
        startvd = 0;

        // 4. Wait for process to complete (wait for busyvd to go high then low)
        // Wait for busy to rise first (interaction start)
        wait(busyvd == 1);
        $display("System Busy...");

        // Wait for busy to fall (process end)
        wait(busyvd == 0);
        $display("Process Complete!");

        // Small delay to ensure writes settle
        #20;

        // 5. Dump RAM contents and Check Results
        DumpRam(0, 6); // Dump first 6 words (3 pairs)

        $finish;
    end

    // Task to Read and Print RAM (Adapted from myram_tb.v)
    // Uses Port 1 to read data without disturbing the DUT on Port 2
    task DumpRam;
        input [RAM_SIZE-1:0] StartAddress;
        input [31:0] Count;
        integer i;
        begin
            $display("-------------------------------");
            $display("Dump RAM Results (Addr: Data)");
            for(i = StartAddress; i < StartAddress + Count; i = i + 1) begin

                // Setup Address on Port 1
                @(posedge clock);
                Addr1 = i;

                // Wait for read access time
                @(posedge clock);
                #1; // Small delay for display stability

                // Display logic to identify Quotient vs Rest
                if (i % 2 == 0)
                    $display("Addr %2d (Quotient): %d", i, Rdata1);
                else
                    $display("Addr %2d (Rest)    : %d", i, Rdata1);
            end
            $display("-------------------------------");
        end
    endtask

endmodule
