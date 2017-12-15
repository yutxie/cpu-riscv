`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/12/12 22:29:21
// Design Name: 
// Module Name: mem
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

`include "defines.v"

module mem(
        
        input wire rst,
        
        // from ex
        input wire[`RegAddrBus] wd_i,
        input wire wreg_i,
        input wire[`RegBus] wdata_i,
        
        // mem result
        output reg[`RegAddrBus] wd_o,
        output reg wreg_o,
        output reg[`RegBus] wdata_o
    );
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            wd_o <= `NOPRegAddr;
            wreg_o <= `WriteDisable;
            wdata_o <= `ZeroWord;
        end else begin
            wd_o <= wd_i;
            wreg_o <= wreg_i;
            wdata_o <= wdata_i;
        end
    end
    
endmodule
