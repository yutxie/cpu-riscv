`include "defines.v"

module ex_mem(

    input wire                    clk,
    input wire                    rst,

    input wire[5:0]               stall,

    // from ex
    input wire[`RegAddrBus]       ex_wd,
    input wire                    ex_wreg,
    input wire[`RegBus]           ex_wdata,

    // to mem
    output reg[`RegAddrBus]       mem_wd,
    output reg                    mem_wreg,
    output reg[`RegBus]           mem_wdata
);

    always @ (posedge clk) begin
        if(rst == `RstEnable) begin
            mem_wd <= `NOPRegAddr;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;
        end else if (stall[3] == `Stop && stall[4] == `NoStop) begin
            mem_wd <= `NOPRegAddr;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;
        end else if (stall[3] == `NoStop) begin
            mem_wd <= ex_wd;
            mem_wreg <= ex_wreg;
            mem_wdata <= ex_wdata;
        end //if
    end //always

endmodule
