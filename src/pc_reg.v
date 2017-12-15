`include "defines.v"

module pc_reg(

    input wire                    clk,
    input wire                    rst,

    //来自控制模块的信息
    input wire[5:0]               stall,

    //来自译码阶段的信息
    input wire                    branch_flag_i,
    input wire[`RegBus]           branch_target_address_i,
    
    output reg[`InstAddrBus]      pc, // 要取的指令地址 以byte为单位
    output reg                    ce // chip enable 存储器可用
    
);

    always @ (posedge clk) begin
        if (ce == `ChipDisable) begin // rst==RstEnable ce==ChipDisable ?
            pc <= 32'h00000000;
        end else if(stall[0] == `NoStop) begin
            if(branch_flag_i == `Branch) begin
                pc <= branch_target_address_i;
            end else begin
                pc <= pc + 4'h4; // += 4byte
            end
        end
    end

    always @ (posedge clk) begin // reset or not
        if (rst == `RstEnable) begin
            ce <= `ChipDisable;
        end else begin
            ce <= `ChipEnable;
        end
    end

endmodule