`timescale 1ns / 1ps

module ripple_carry_adder_Nb #(
    parameter   ADDER_WIDTH = 16
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB, 
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum, 
    output  wire                    oCarry
);

wire [ADDER_WIDTH:0]  Cin;
assign Cin[0] = iCarry;
assign oCarry = Cin[ADDER_WIDTH];

// variable to control for loop
    genvar i;
    
    // instantiate N 1-bit Full adders
    generate
        for (i=0; i<=ADDER_WIDTH-1; i=i+1) 
        begin
        full_adder FA_inst (
            .iA(iA[i]),
            .iB(iB[i]),
            .iCarry(Cin[i]),
            .oSum(oSum[i]),
            .oCarry(Cin[i+1])
        );
        end 
    endgenerate
    
endmodule
