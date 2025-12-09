module vector_divider #(
    parameter RAM_SIZE = 10,       // RAM 1024x32 (10-bit address)
    parameter N = 5,
    parameter NBITS = 32           // 32-bit data registers
)(
    //global
    input clock,
    input reset,

    //OUTPUT REGs to RAM
    output [RAM_SIZE-1:0] Addr,    // Address bus (10 bits)
    output [NBITS-1:0] Wdata,      // [FIX] Data bus must be 32 bits (NBITS)

    //INPUT REGs from RAM
    input [NBITS-1:0] Rdata,       // Data from RAM
    input [RAM_SIZE-1:0] Ndata,    // Number of pairs (Limit)

    //OUTPUT WRITE COMMAND to RAM
    output Wenable,                // from fsm

    //IO_PORTS CONNECTIONS
    input startvd,                 // from IO
    output busyvd                  // to IO
);

// INTERNAL WIRES (Connecting FSM to Datapath)
wire LoadX_w;
wire LoadY_w;
wire [2:0] control_Addr_w;
wire stop_div_w;
wire start_div_w;
wire Wdata_control_w;
wire stopvd_w;

fsm #(
    .RAM_SIZE(RAM_SIZE),
    .N(N),
    .NBITS(NBITS)
)   u_fsm(
    .clock(clock),
    .reset(reset),
    .Wdata_control(Wdata_control_w),
    .LoadX_reg(LoadX_w),
    .LoadY_reg(LoadY_w),
    .control_Addr(control_Addr_w),
    .stop_div(stop_div_w),
    .start_div(start_div_w),
    .Wenable(Wenable),
    .busyvd(busyvd),
    .startvd(startvd),
    .stopvd(stopvd_w)
);

datapath #(
    .RAM_SIZE(RAM_SIZE),
    .N(N),
    .NBITS(NBITS)
)   u_datapath(
    .clock(clock),
    .reset(reset),
    .Addr(Addr),
    .Wdata(Wdata),
    .Rdata(Rdata),
    .Ndata(Ndata),
    .Wdata_control(Wdata_control_w),
    .LoadX_reg(LoadX_w),
    .LoadY_reg(LoadY_w),
    .control_Addr(control_Addr_w),
    .stop_div(stop_div_w),
    .start_div(start_div_w),
    .stopvd(stopvd_w)
);

endmodule
