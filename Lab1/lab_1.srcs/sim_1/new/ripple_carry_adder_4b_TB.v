`timescale 1ns / 1ps

module ripple_carry_adder_4b_TB(

    );
    reg [3:0] riA, riB;
    reg rCin;
    wire [3:0] oSum;
    wire wCout;
    
    ripple_carry_adder_4b rca_inst
    (.iA(riA), .iB(riB), .iCarry(rCin), 
    .oSum(oSum), .oCarry(wCout));
    
    integer i;

initial
    begin

    $monitor ("(%d + %d + %d) = %d", riA, riB, rCin, {wCout, oSum});  

    // Use a for loop to apply random values to the input  
    for (i = 0; i < 5; i = i+1) 
    begin  
        #10 
        riA <= $random;  
        riB <= $random;  
        rCin <= $random;  
    end  
end
endmodule
