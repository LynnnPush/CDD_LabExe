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
    parameter   NBYTES        = 12,
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
  reg [NBYTES*8-1:0] rBuffer;//can store 12 bytes
  reg [7:0] rByte;
  
  // State definition  
  localparam s_IDLE         = 3'b000;
  localparam s_RX           = 3'b001;
  localparam s_WAIT_RX      = 3'b010;
  localparam s_TX           = 3'b011;
  localparam s_WAIT_TX      = 3'b100;
  localparam s_DONE         = 3'b101;
   
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
  reg [$clog2(NBYTES):0] rCnt;
  
  always@(negedge iClk)begin
    rRxDone <= wRxDone;
  end

  
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
      end 
  else 
    begin
      case (rFSM)
        s_IDLE :
            rFSM <= s_RX;
          
        s_RX:
        begin
        if(rCnt<NBYTES)begin
            if(wRxDone==1)begin
                $display("Now rBit is still smaller than NBYTES which is %h!", rCnt);
                rBuffer <= {rBuffer[NBYTES*8-9:0], wRxByte};  // ? ֻ�� `wRxDone == 1` ʱд������
                rCnt <= rCnt + 1;
                rFSM <= s_RX;
            end 
            else
                rFSM <= s_RX;
        end
        else begin
                $display("Reach the boundary");
                rFSM <= s_TX;
                rCnt <= 0;
        end
        end

             
        s_TX :
          begin
            if ( (rCnt < NBYTES) && (wTxBusy ==0) ) 
              begin
                rFSM <= s_WAIT_TX;
                rTxStart <= 1; 
                //for mote bytes
                rTxByte <= rBuffer[NBYTES*8-1:NBYTES*8-8];            // we send the uppermost byte
                rBuffer <= {rBuffer[NBYTES*8-9:0] , 8'b0000_0000};    // we shift from right to left
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
            
            s_WAIT_TX :
              begin
                if (wTxDone)
                  rFSM <= s_TX;
                else begin
                  rFSM <= s_WAIT_TX;
                  rTxStart <= 0;                   
                end
              end 
              
            s_DONE :
                rFSM <= s_IDLE;

            default :
              rFSM <= s_IDLE;
          endcase
      end
    end      
    
    
endmodule