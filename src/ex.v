`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/12/12 22:10:30
// Design Name: 
// Module Name: ex
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

module ex(
        
        input wire rst,
        
        // from id
        input wire[`AluOpBus] aluop_i,
        input wire[`AluSelBus] alusel_i,
        input wire[`RegBus] reg1_i,
        input wire[`RegBus] reg2_i,
        input wire[`RegAddrBus] wd_i,
        input wire wreg_i,
        
        // ex result
        output reg[`RegAddrBus] wd_o,
        output reg wreg_o,
        output reg[`RegBus] wdata_o
    );
    
    reg[`RegBus] logicout;
    
    // 依据 aluop_i 进行运算 /////////////////////////////////
    always @ (*) begin
        if (rst == `RstEnable) begin
            logicout <= `ZeroWord;
        end else begin
            case (aluop_i)
                `EXE_OR_OP: begin
                    logicout <= reg1_i | reg2_i;
                end // EXE_OR_OP
                default: begin
                    logicout <= `ZeroWord;
                end // default
            endcase
        end // if
    end // always
    
    // 依据 alusel_i 选择运算结果 /////////////////////////////
    always @ (*) begin
        wd_o <= wd_i;
        wreg_o <= wreg_i;
        case (alusel_i)
            `EXE_RES_LOGIC: begin
                wdata_o <= logicout;
            end // EXE_RES_LOGIC
            default: begin
                wdata_o <= `ZeroWord;
            end // default
        endcase
    end // always
    
endmodule
