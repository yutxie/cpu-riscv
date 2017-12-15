`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/12/12 22:24:16
// Design Name: 
// Module Name: ex_mem
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

module ex_mem(
        
        input wire clk,
        input wire rst,
        
        // from ex
        input wire[`RegAddrBus] ex_wd,
        input wire ex_wreg,
        input wire[`RegBus] ex_wdata,
        
        // to mem
        output reg[`RegAddrBus] mem_wd,
        output reg mem_wreg,
        output reg[`RegBus] mem_wdata
    );
    
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            mem_wd <= `NOPRegAddr;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;
        end else begin
            mem_wd <= ex_wd;
            mem_wreg <= ex_wreg;
            mem_wdata <= ex_wdata;
        end
    end
            
    
endmodule
