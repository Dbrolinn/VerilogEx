module fsm #(
    parameter RAM_SIZE = 10,
    parameter N = 5,
    parameter NBITS = 32
)(
    //global
    input clock,
    input reset,

    //OUTPUT CONTROL COMMANDS to DATAPATH
    output reg Wdata_control,   //Wdata multiplexer
    /*
      (0 -> MEM[i] <= rest)
      (1 -> MEM[i] <= quotient)
    */

    output reg LoadX_reg,       //Flag: X reg receives dividend value from RAM
    output reg LoadY_reg,       //Flag: Y reg receives divisor value from RAM

    //ADDR REG CONTROL COMMANDS to DATAPATH
    output reg [2:0] control_Addr,
    /*
      (3'd0 -> resetAddr: Addr <= 'h0)
      (3'd1 -> inc_Addr: Addr <= Addr + 1)
      (3'd2 -> inc2_Addr: Addr <= Addr + 2)
      (3'd3 -> dec_Addr: Addr <= Addr - 1)
      (3'd4 -> hold_Addr: Addr <= Addr)
    */

    //OUTPUT CONTROL COMMANDS to DIVIDE
    output reg stop_div,
    output reg start_div,

    //OUTPUT WRITE COMMAND to RAM
    output reg Wenable,

    //OUTPUT BUSY COMMAND to IO_PORTS
    output reg busyvd,

    //FSM STATE CONTROL COMMANDS
    input startvd,  //from IO_PORTs
    input stopvd    //from DATAPATH
);
reg [2:0] state, next_state;
reg [RAM_SIZE-1:0] clock_count;          //Number of cycles for each operation

parameter   IDLE = 3'd0,
            READ_MEM = 3'd1,             //Load MEM[i] to dividend & MEM[i+1] to divisor
            DIVISION = 3'd2,             //Count NBITS clock cycles for the division to complete
            WRITE_MEM = 3'd3,            //Load rest to MEM[i+1] & MEM[i] to quotient
            STOP = 3'd4;

always @(posedge clock) begin
  if(reset) begin
    //RESET INTERNAL LOGIC
    state <= IDLE;
    clock_count <= 'd0;
  end else begin
    state <= next_state;
    if(state != IDLE && state != STOP)
      clock_count <= clock_count + 1;
    else
      clock_count <= 'd0;
  end
end

always @(*) begin
  next_state = state;               //keep state
  start_div = 0;                    //reset start_div flag by default
  stop_div = 0;                     //reset stop_div flag by default
  Wenable = 0;                      //reset write to RAM flag by default

  LoadX_reg = 0;                    //regX doesn't load any data by default
  LoadY_reg = 0;                    //regY doesn't load any data by default
  Wdata_control = 0;                //reset Wdata mux to rest by default

  control_Addr = 3'd4;

  case(state)
    IDLE: begin
      busyvd = 0;
      control_Addr = 'd0;
      if (startvd) begin
        next_state = READ_MEM;      //Clock -1: change state next clock
      end
    end

     READ_MEM: begin                 //Clock 0 to 3
      busyvd = 1;                   //Clock 0 to 3
      if(clock_count == 0) begin
        LoadX_reg = 1;              //Clock 0: load to dividend reg next clock
        control_Addr = 3'd1;        //Clock 0: (addr+1) load from MEM[i+1] next clock
      end
      else if (clock_count == 2)
        LoadY_reg = 1;              //Clock 2: load to divisor reg next clock
      else if (clock_count == 3) begin
        start_div = 1;              //Clock 3: load dividend and divisor reg values to internal regs next clock
        next_state = DIVISION;      //Clock 3: change state next clock
      end
    end

    //1 CLOCK for start + 32 for DIVISION + 1 for STOP
    DIVISION: begin                 //Clock 4 to 37 (division process lasts for 32 cycles)
      if(clock_count == NBITS + 4)
        stop_div = 1;               //Clock 36: divisor block writes results to rest & quotient regs next clock
      if(clock_count == NBITS + 5) begin
        Wenable = 1;                //Clock 37: write rest result to RAM memory next clock
        control_Addr = 3'd3;        //Clock 37: (addr-1) load to MEM[i-1] next clock
        next_state = WRITE_MEM;     //Clock 37: change state next clock
      end
    end

    WRITE_MEM: begin                //Clock 38
        Wenable = 1;                //Clock 38: write quotient result to RAM memory next clock
        Wdata_control = 1;          //Clock 38: load from quotient next clock
        control_Addr = 3'd2;        //Clock 38: (addr+2) load new dividend from RAM next clock cycle
        next_state = STOP;          //Clock 38: change state next clock
    end

    STOP: begin
      if(stopvd) begin
        busyvd = 0;                 //Clock -1: alert end of operation
        next_state = IDLE;          //Clock -1: end FSM
      end else begin
        next_state = READ_MEM;      //Clock -1: change state next clock (start new_div)
      end
    end
  endcase
end

endmodule
