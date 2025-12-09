//compile: iverilog -f psdsqrt.dat -o mysimout
//run: vvp mysimout

module psdsqrt(
    input clock,
    input reset,
    input start,
    input stop,
    input [31:0] xin,
    output reg [15:0] sqrt
);

reg [31:0] reg_xin;
reg [15:0] tempsqrt_A, tempsqrt_B;

wire [31:0] sqtestsqrt;
wire[15:0] mux1, mux2, mux3, testsqrt;
wire comparator;
^
assign mux1 = comparator ? testsqrt : tempsqrt_A;
assign mux2 = start ? 16'h0 : mux1;
assign mux3 = start ? 16'h8000 : (tempsqrt_B >> 1);

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

