`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/03 09:51:22
// Design Name: 
// Module Name: uart_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module uart_top #(
    parameter   OPERAND_WIDTH = 512,
    parameter   ADDER_WIDTH   = 16,
    parameter   NBYTES        = OPERAND_WIDTH / 8,    
    // values for the UART (in case we want to change them)
    parameter   CLK_FREQ      = 125_000_000,
    parameter   BAUD_RATE     = 115_200
)  
(
    input   wire   iClk, iRst,
    input   wire   iRx,
    output  wire   oTx
);
  
  // Buffer to exchange data between Pynq-Z2 and laptop
  reg [NBYTES*8-1:0] rA;//Store operand A
  reg [NBYTES*8-1:0] rB;//Store operand B
  wire [OPERAND_WIDTH:0] wResult;//Linked to result output of adder. It will keep updating, and only the result when adder_done =1 is valid.
  reg [(NBYTES+1)*8-1:0] rBuffer; //Store the reuslt for transmitting (Tx)

  
  // State definition  
  localparam s_IDLE         = 3'b000;
  localparam s_RX_A         = 3'b001; // Receive operand A and store into reg rA
  localparam s_RX_B         = 3'b010; // Receive operand B and store into reg rB
  localparam s_CAL          = 3'b011; // Calculate and store result into reg rRes
  localparam s_TX           = 3'b100; // uart_tx retrieve res from rRes and send through Tx
  localparam s_WAIT_TX      = 3'b101;
  localparam s_DONE         = 3'b110;
   
  // Declare all variables needed for the finite state machine 
  // -> the FSM state
  reg [2:0]   rFSM;  
  
  // Connection to UART TX (inputs = registers, outputs = wires)
  reg         rTxStart;
  reg         rRxDone;
  reg [7:0]   rTxByte;
  wire[7:0]   wRxByte;
  
  wire        wTxBusy;
  wire        wTxDone;
  wire        wRxDone;
      
  uart_tx #(  .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE) )
  UART_TX_INST
    (.iClk(iClk),
     .iRst(iRst),
     .iTxStart(rTxStart),
     .iTxByte(rTxByte),
     .oTxSerial(oTx),
     .oTxBusy(wTxBusy),
     .oTxDone(wTxDone)
     );
     
  uart_rx #(  .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE) )
  UART_RX_INST
  (.iClk(iClk),
   .iRst(iRst),
   .iRxSerial(iRx),
   .oRxByte(wRxByte),
   .oRxDone(wRxDone)
  );

  reg adder_start;
  wire adder_done;
  mp_adder #( .OPERAND_WIDTH(OPERAND_WIDTH), .ADDER_WIDTH(ADDER_WIDTH))
  MP_ADDER_INST
  (.iClk(iClk),
   .iRst(iRst),
   .iStart(adder_start),
   .iOpA(rA),
   .iOpB(rB),
   .oRes(wResult),
   .oDone(adder_done)
  );

  
  reg [$clog2(NBYTES):0] rCnt;
  
  always @(posedge iClk)
  begin
  // reset all registers upon reset
  if (iRst == 1 ) 
    begin
      rFSM <= s_IDLE;
      rTxStart <= 0;
      rCnt <= 0;
      rTxByte <= 0;
      rBuffer <= 0;
      adder_start <= 0;
      rA <= 0;
      rB <= 0;
      end 
  else 
    begin
      case (rFSM)
        s_IDLE :  // (rFSM=0)
            rFSM <= s_RX_A;
          
        s_RX_A: // (rFSM=1)
        begin
        if(rCnt<NBYTES)begin
            if(wRxDone==1)begin
                $display("Now rBit is still smaller than NBYTES which is %h!", rCnt);
                rA <= {rA[NBYTES*8-9:0], wRxByte};  //Shift left rbuffer val and concatenate received value
                rCnt <= rCnt + 1;
                rFSM <= s_RX_A;
            end 
            else
                rFSM <= s_RX_A;
        end
        else begin
                $display("Reach the boundary");
                rFSM <= s_RX_B;
                rCnt <= 0;
        end
        end

        s_RX_B: // (rFSM=2)
        begin
        if(rCnt<NBYTES)
        begin
            if(wRxDone==1)
            begin
                $display("Now rBit is still smaller than NBYTES which is %h!", rCnt);
                rB <= {rB[NBYTES*8-9:0], wRxByte};  //Shift left rbuffer val and concatenate received value
                rCnt <= rCnt + 1;
                rFSM <= s_RX_B;
            end 
            else
                rFSM <= s_RX_B;
        end
        else begin
                $display("Reach the boundary");
                rFSM <= s_CAL;
                adder_start <= 1;
                rCnt <= 0;
        end
        end

      s_CAL: // (rFSM=3)
      begin
        if(adder_done==1)
        begin
          rFSM <= s_TX;
          rBuffer <= wResult;
          adder_start <= 0;
        end
        else
          rFSM <= s_CAL;
      end
        
        // Note that now the size of rBuffer is NBYTES+1     
        s_TX : // (rFSM=4)
          begin
            if ( (rCnt < NBYTES+1) && (wTxBusy ==0) ) 
              begin
                rFSM <= s_WAIT_TX;
                rTxStart <= 1; 
                //for mote bytes
                rTxByte <= rBuffer[(NBYTES+1)*8-1:(NBYTES+1)*8-8];            // we send the uppermost byte
                rBuffer <= {rBuffer[(NBYTES+1)*8-9:0] , 8'b0000_0000};    // we shift from right to left
                //rTxByte <= rBuffer;//for single byte
                rCnt <= rCnt + 1;
              end 
            else 
              begin
                rFSM <= s_DONE;
                rTxStart <= 0;
                rTxByte <= 0;
                rCnt <= 0;
              end
            end 
            
            s_WAIT_TX : // (rFSM=5)
              begin
                if (wTxDone)
                  rFSM <= s_TX;
                else begin
                  rFSM <= s_WAIT_TX;
                  rTxStart <= 0;                   
                end
              end 
              
            s_DONE : // (rFSM=6)
                rFSM <= s_IDLE;

            default :
              rFSM <= s_IDLE;
          endcase
      end
    end      
    
    
endmodule