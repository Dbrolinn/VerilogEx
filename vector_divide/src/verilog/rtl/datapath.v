module datapath #(
    parameter RAM_SIZE = 10,
    parameter N = 5,
    parameter NBITS = 32
)(
    //global
    input clock,
    input reset,

    //OUTPUT REGs to RAM
    output reg [RAM_SIZE-1:0] Addr,
    output [NBITS-1:0] Wdata,

    //INPUT REGs from RAM
    input [NBITS-1:0] Rdata,
    input [RAM_SIZE-1:0] Ndata,

    //MUX CONTROL from FSM
    input Wdata_control,
    /*
      (0 -> MEM[i] <= rest)
      (1 -> MEM[i] <= quotient)
    */

    //READ RAM CONTROLs from FSM
    input LoadX_reg,            //Flag: X reg receives dividend value from RAM
    input LoadY_reg,            //Flag: Y reg receives divisor value from RAM

    //ADDR REG CONTROL COMMANDS to DATAPATH
    input [2:0] control_Addr,
    /*
      (3'd0 -> resetAddr: Addr <= 'h0)
      (3'd1 -> inc_Addr: Addr <= Addr + 1)
      (3'd2 -> inc2_Addr: Addr <= Addr + 2)
      (3'd3 -> dec_Addr: Addr <= Addr - 1)
      (3'd4 -> hold_Addr: Addr <= Addr)
    */

    //OUTPUT CONTROL COMMANDS to DIVIDE
    input stop_div,
    input start_div,

    //FSM STATE CONTROL COMMANDS
    output stopvd
);

parameter   resetAddr = 3'd0,
            inc_Addr = 3'd1,
            inc2_Addr = 3'd2,
            dec_Addr = 3'd3,
            hold_Addr = 3'd4;

//INTERNAL REGs
reg [NBITS-1:0] regX;  // Dividend Storage
reg [NBITS-1:0] regY;  // Divisor Storage

//INTERNAL WIREs
wire [NBITS-1:0] rest_w;
wire [NBITS-1:0] quotient_w;

divide u_divide(
    .clock(clock),
    .reset(reset),
    .start(start_div),
    .stop(stop_div),
    .dividend(regX),
    .divisor(regY),
    .quotient(quotient_w),
    .rest(rest_w)
);

//OUTPUT LOGIC
assign stopvd = (Addr == (Ndata << 1)) ? 1'b1 : 1'b0;
assign Wdata = Wdata_control ? quotient_w : rest_w;

//ADDRESS CONTROL LOGIC
always @(posedge clock) begin
    case (control_Addr)
        resetAddr:
            Addr <= 'h0;
        inc_Addr:
            Addr <= Addr + 1;
        inc2_Addr:
            Addr <= Addr + 2;
        dec_Addr:
            Addr <= Addr - 1;
        hold_Addr:
            Addr <= Addr;
        default:
            Addr <= Addr;
    endcase
end

always @(posedge clock) begin
    if(reset) begin
        regX <= 0;
        regY <= 0;
    end else begin
        if(LoadX_reg) regX <= Rdata;
        if(LoadY_reg) regY <= Rdata;
    end
end

endmodule
