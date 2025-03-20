`timescale 1ns / 1ps

module uart_top_TB ();
 
  // Define signals for module under test
  reg  rClk = 0;
  reg  rRst = 0;
  reg  rRx = 1'b1;  // Changed from wire to reg; idle state for UART is high
  wire wTx;
  
  // Downscale the values in the simulation
  localparam CLK_FREQ_inst  = 100;
  localparam BAUD_RATE_inst = 10;
  
  // Instantiate DUT  
  uart_top 
  #(  .CLK_FREQ(CLK_FREQ_inst), .BAUD_RATE(BAUD_RATE_inst) )
  uart_top_inst
  ( .iClk(rClk), .iRst(rRst), .iRx(rRx), .oTx(wTx) );
  
  // Define clock signal
  localparam CLOCK_PERIOD = 4;
  
  // Clock generation
  always
    #(CLOCK_PERIOD/2) rClk <= ~rClk;
 
  // Input stimulus
  initial begin
      // Reset the device
      rRst = 1;
      rRx  = 1; // Idle state
      #(5 * CLOCK_PERIOD);
      rRst = 0;
      #(10 * CLOCK_PERIOD);
      
      // --- Transmit Byte 1: 0x55 (binary 01010101, LSB first) ---
      // Start Bit (0)
      rRx = 0;
      #(10 * CLOCK_PERIOD);
      
      // Data Bits (LSB first)
      rRx = 1;  // Bit 0: 1
      #(10 * CLOCK_PERIOD);
      rRx = 0;  // Bit 1: 0
      #(10 * CLOCK_PERIOD);
      rRx = 1;  // Bit 2: 1
      #(10 * CLOCK_PERIOD);
      rRx = 0;  // Bit 3: 0
      #(10 * CLOCK_PERIOD);
      rRx = 1;  // Bit 4: 1
      #(10 * CLOCK_PERIOD);
      rRx = 0;  // Bit 5: 0
      #(10 * CLOCK_PERIOD);
      rRx = 1;  // Bit 6: 1
      #(10 * CLOCK_PERIOD);
      rRx = 0;  // Bit 7: 0
      #(10 * CLOCK_PERIOD);
      
      // Stop Bit (1)
      rRx = 1;
      #(10 * CLOCK_PERIOD);
      
      // Optionally, wait a bit before the next byte if needed
      #(20 * CLOCK_PERIOD);
      
      // --- Transmit Byte 2: 0xAA (binary 10101010, LSB first) ---
      // Start Bit (0)
      rRx = 0;
      #(10 * CLOCK_PERIOD);
      
      // Data Bits (LSB first)
      // For 0xAA (10101010), LSB is 0, then 1, 0, 1, 0, 1, 0, 1.
      rRx = 0;  // Bit 0: 0
      #(10 * CLOCK_PERIOD);
      rRx = 1;  // Bit 1: 1
      #(10 * CLOCK_PERIOD);
      rRx = 0;  // Bit 2: 0
      #(10 * CLOCK_PERIOD);
      rRx = 1;  // Bit 3: 1
      #(10 * CLOCK_PERIOD);
      rRx = 0;  // Bit 4: 0
      #(10 * CLOCK_PERIOD);
      rRx = 1;  // Bit 5: 1
      #(10 * CLOCK_PERIOD);
      rRx = 0;  // Bit 6: 0
      #(10 * CLOCK_PERIOD);
      rRx = 1;  // Bit 7: 1
      #(10 * CLOCK_PERIOD);
      
      // Stop Bit (1)
      rRx = 1;
      #(10 * CLOCK_PERIOD);
      
      // Let simulation run to observe output on oTx
      #(1000 * CLOCK_PERIOD);
      
      $stop;
  end
endmodule
