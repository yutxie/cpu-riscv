`include "defines.v"

module pc_reg(

    input wire                    clk,
    input wire                    rst,

    input wire[5:0]               stall,

    output reg[`InstAddrBus]      pc,
    output reg                    ce

);

    always @ (posedge clk) begin
        if (ce == `ChipDisable) begin // rst==RstEnable ce==ChipDisable ?
            pc <= 32'h00000000;
        end else if (stall[0] == `NoStop) begin
            pc <= pc + 4'h4; // += 4byte
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
