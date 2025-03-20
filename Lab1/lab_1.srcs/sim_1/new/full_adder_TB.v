`timescale 1ns / 1ps

module full_adder_tb;

    // Testbench signals
    reg iA;
    reg iB;
    reg iCarry;
    wire oSum;
    wire oCarry;

    // Instantiate the full adder (Unit Under Test)
    full_adder uut (
        .iA(iA),
        .iB(iB),
        .iCarry(iCarry),
        .oSum(oSum),
        .oCarry(oCarry)
    );
    
    integer i;

    initial begin
        $display("Time\tA B Cin | Sum Carry");
        // Loop through all 8 combinations of inputs
        for (i = 0; i < 8; i = i + 1) begin
            {iA, iB, iCarry} = i; // Assign bits to iA, iB, iCarry
            #10; // Wait 10 ns for outputs to settle
            $display("%0t:\t%b %b  %b  |  %b   %b", $time, iA, iB, iCarry, oSum, oCarry);
        end
        
        $finish; // End the simulation
    end

endmodule
