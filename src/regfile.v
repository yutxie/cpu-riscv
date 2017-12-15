`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/12/11 15:15:24
// Design Name: 
// Module Name: regfile
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

module regfile(
        
        input wire clk,
        input wire rst,
        
        // 写端口
        input wire we, // write enable
        input wire[`RegAddrBus] waddr,
        input wire[`RegBus] wdata,
        
        // 读端口1
        input wire re1, // read enable
        input wire[`RegAddrBus] raddr1,
        output reg[`RegBus] rdata1,
        
        // 读端口2
        input wire re2,
        input wire[`RegAddrBus] raddr2,
        output reg[`RegBus] rdata2
    );
    
    // 32个寄存器
    reg[`RegBus] regs[0:`RegNum-1];
    
    // 写操作
    always @ (posedge clk) begin // 时钟上升沿写
        if (rst == `RstDisable) begin
            // cannot modify x0==0
            if ((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
                regs[waddr] <= wdata;
            end
        end
    end
    
    // 读端口1的读操作
    always @ (*) begin // input修改时读
        if (rst == `RstEnable) begin
            rdata1 <= `ZeroWord;
        end else if (raddr1 == `RegNumLog2'h0) begin
            rdata1 <= `ZeroWord;
        end else if ((raddr1 == waddr) && (we == `WriteEnable)
                                       && (re1 == `ReadEnable)) begin
            rdata1 <= wdata;
        end else if (re1 == `ReadEnable) begin
            rdata1 <= regs[raddr1];
        end else begin
            rdata1 <= `ZeroWord;
        end
    end
    
    // 读端口2的读操作
    always @ (*) begin
        if (rst == `RstEnable) begin
            rdata2 <= `ZeroWord;
        end else if (raddr2 == `RegNumLog2'h0) begin
            rdata2 <= `ZeroWord;
        end else if ((raddr2 == waddr) && (we == `WriteEnable)
                                       && (re2 == `ReadEnable)) begin
            rdata2 <= wdata;
        end else if (re2 == `ReadEnable) begin
            rdata2 <= regs[raddr2];
        end else begin
            rdata2 <= `ZeroWord;
        end
    end
            
    
endmodule
