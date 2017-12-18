`include "defines.v"

module inst_rom(

    input wire                          ce,
    input wire[`InstAddrBus]            addr,
    output reg[`InstBus]                inst

);

    reg[`InstBus]  inst_mem[0:`InstMemNum-1]; // 以指令为单位

    // initial $readmemh ("inst_rom.data", inst_mem);

    always @ (*) begin
        if (ce == `ChipDisable) begin
            inst <= `ZeroWord;
        end else begin
            inst <= inst_mem[addr[`InstMemNumLog2+1:2]];
            // 地址是以byte为单位 除以4再使用
        end
    end

endmodule
