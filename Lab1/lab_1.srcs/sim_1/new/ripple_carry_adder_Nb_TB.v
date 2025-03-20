`timescale 1ns / 1ps

module ripple_carry_adder_Nb_tb;
    // Parameter for adder width
    parameter ADDER_WIDTH = 16;
    
    // Declare inputs as reg and outputs as wire
    reg  [ADDER_WIDTH-1:0] riA, riB;
    reg                    rCarry;
    wire [ADDER_WIDTH-1:0] oSum;
    wire                   oCarry;
    
    // Instantiate the adder module under test (UUT)
    ripple_carry_adder_Nb #(
        .ADDER_WIDTH(ADDER_WIDTH)
    ) DUT (
        .iA(riA),
        .iB(riB),
        .iCarry(rCarry),
        .oSum(oSum),
        .oCarry(oCarry)
    );
    
    integer i;  // loop variable
    
    initial begin
        // Monitor outputs at every time step
        $monitor("Time=%0t | A=%0d | B=%0d | CarryIn=%b | Sum=%0d | CarryOut=%b", 
                  $time, riA, riB, rCarry, oSum, oCarry);
        
        // Apply several test vectors with random values
        for (i = 0; i < 10; i = i + 1) begin
            #10;  // wait for 10 ns between tests
            riA   = $random;
            riB   = $random;
            rCarry = $random % 2; // Ensure carry is either 0 or 1
        end
        
        #10; // Wait a little before finishing simulation
        $finish;
    end

endmodule
