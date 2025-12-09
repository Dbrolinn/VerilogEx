//compile: iverilog -f psdsqrt52.dat -o mysimout52
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
parameter DECIMAL = 4;
parameter NBITS_INT = NBITS + DECIMAL*2

//Now all registers and wires are declared with NBITS_INT
reg [NBITS_INT-1:0] reg_xin;
reg [NBITS_INT/2-1:0] tempsqrt_A, tempsqrt_B, sqrt_aux;

wire [NBITS_INT-1:0] sqtestsqrt, xin_decimal;
wire [NBITS_INT/2-1:0] mux1, mux2, mux3, testsqrt;
wire comparator;

assign mux1 = comparator ? testsqrt : tempsqrt_A;
assign mux2 = start ? 'h0 : mux1;
assign mux3 = start ? (1<<NBITS_INT/2-1) : (tempsqrt_B >> 1);

assign testsqrt = tempsqrt_A | tempsqrt_B;
assign sqtestsqrt = testsqrt * testsqrt;
assign comparator = (reg_xin >= sqtestsqrt);

assign xin_decimal = (xin<<DECIMAL*2);

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
        reg_xin <= xin_decimal;
end


always @(posedge clock) begin
    if(reset)
        sqrt_aux <= 'b0;
    else if (stop)
        sqrt_aux <= tempsqrt_A;
end

always @* begin

    //Round down if the fractional part of the square root is less than 0.5 (0.1000b)
    if(sqrt_aux[DECIMAL-1:0] < (1<<DECIMAL-1))
        sqrt = (sqrt_aux >> DECIMAL);

    //Round up if the fractional part is greater or equal to 0.5625 (0.1001b)
    if(sqrt_aux[DECIMAL-1:0] >= (1<<DECIMAL-1) +1)
        sqrt = 1 + (sqrt_aux >> DECIMAL);

    //Round to the nearest even integer if the 4-bit fractional part is equal to 0.5 (0.1000b)
    if(sqrt_aux[DECIMAL-1:0] = (1<<DECIMAL-1)) begin
        if(sqrt_aux[DECIMAL] == 0)
            sqrt = (sqrt_aux >> DECIMAL);
        else
            sqrt = 1 + (sqrt_aux >> DECIMAL);
    end
end

endmodule

