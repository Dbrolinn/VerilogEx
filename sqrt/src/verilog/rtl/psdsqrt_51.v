//compile: iverilog -f psdsqrt51.dat -o mysimout51
//run: vvp mysimout

module psdsqrt(
    input clock,
    input reset,
    input start,
    input stop,
    input [NBITS-1:0] xin,
    output reg [NBITS/2-1:0] sqrt
);

parameter NBITS = 32;

reg [NBITS-1:0] reg_xin;
reg [NBITS/2-1:0] tempsqrt_A, tempsqrt_B;

wire [NBITS-1:0] sqtestsqrt;
wire [NBITS/2-1:0] mux1, mux2, mux3, testsqrt;
wire comparator;

assign mux1 = comparator ? testsqrt : tempsqrt_A;
assign mux2 = start ? 'h0 : mux1;
assign mux3 = start ? (1<<NBITS/2-1) : (tempsqrt_B >> 1);

assign testsqrt = tempsqrt_A | tempsqrt_B;
assign sqtestsqrt = testsqrt * testsqrt;
assign comparator = (reg_xin >= sqtestsqrt);

always @(posedge clock) begin
    if(reset) begin
        tempsqrt_B <= 'b0;
        tempsqrt_A <= 'b0;
    end
    else begin
        tempsqrt_A <= mux2;
        tempsqrt_B <= mux3;
    end
end

always @(posedge clock) begin
    if(reset)
        reg_xin <= 'b0;
    else if (start)
        reg_xin <= xin;
end


always @(posedge clock) begin
    if(reset)
        sqrt <= 'b0;
    else if (stop)
        sqrt <= tempsqrt_A;
end

endmodule

