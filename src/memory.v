`include "defines.v"

module memory(

    input wire                              clk,

    // inst_rom
    input wire                              rom_ce,
    input wire[`InstAddrBus]                rom_addr,
    output reg[`InstBus]                    rom_inst,

    // data_ram
    input wire                              ram_ce,
    input wire                              ram_we,
    input wire[`DataAddrBus]                ram_addr,
    input wire[3:0]                         ram_sel,
    input wire[`DataBus]                    ram_data_i,
    output reg[`DataBus]                    ram_data_o

);

    reg[`InstBus]  inst_mem[0:`InstMemNum-1];
    reg[`ByteWidth]  data_mem0[0:`DataMemNum-1]; // low ram_addr
    reg[`ByteWidth]  data_mem1[0:`DataMemNum-1];
    reg[`ByteWidth]  data_mem2[0:`DataMemNum-1];
    reg[`ByteWidth]  data_mem3[0:`DataMemNum-1]; // high ram_addr

    integer i;
    initial begin
        $readmemh ("D:\\Users\\DELL\\Desktop\\inst_rom.data", inst_mem);
        for (i = 0; i < `InstMemNum; i = i + 1) begin
            data_mem3[i] <= inst_mem[i][7:0];
            data_mem2[i] <= inst_mem[i][15:8];
            data_mem1[i] <= inst_mem[i][23:16];
            data_mem0[i] <= inst_mem[i][31:24];
        end
    end

    always @ (*) begin
        if (rom_ce == `ChipDisable) begin
            rom_inst <= `ZeroWord;
        end else begin
            // small ending
            rom_inst <= {data_mem3[rom_addr >> 2],
                         data_mem2[rom_addr >> 2],
                         data_mem1[rom_addr >> 2],
                         data_mem0[rom_addr >> 2]};
        end
    end

    always @ (posedge clk) begin
        if (ram_ce == `ChipDisable) begin
            // ram_data_o <= `ZeroWord;
        end else if(ram_we == `WriteEnable) begin
            if (ram_sel[3] == 1'b1) begin
                data_mem3[ram_addr[`DataMemNumLog2+1:2]] <= ram_data_i[31:24];
                if (ram_addr == 32'h00000104) begin
  			       $write("%c", ram_data_i[31:24]);
      			end
            end
            if (ram_sel[2] == 1'b1) begin
                data_mem2[ram_addr[`DataMemNumLog2+1:2]] <= ram_data_i[23:16];
                if (ram_addr == 32'h00000104) begin
  			       $write("%c", ram_data_i[23:16]);
      			end
            end
            if (ram_sel[1] == 1'b1) begin
                data_mem1[ram_addr[`DataMemNumLog2+1:2]] <= ram_data_i[15:8];
                if (ram_addr == 32'h00000104) begin
  			       $write("%c", ram_data_i[15:8]);
      			end
            end
            if (ram_sel[0] == 1'b1) begin
                data_mem0[ram_addr[`DataMemNumLog2+1:2]] <= ram_data_i[7:0];
                if (ram_addr == 32'h00000104) begin
  			       $write("%c", ram_data_i[7:0]);
      			end
            end
        end
    end

    always @ (*) begin
        if (ram_ce == `ChipDisable) begin
            ram_data_o <= `ZeroWord;
        end else if(ram_we == `WriteDisable) begin
            ram_data_o <= {data_mem3[ram_addr[`DataMemNumLog2+1:2]],
                           data_mem2[ram_addr[`DataMemNumLog2+1:2]],
                           data_mem1[ram_addr[`DataMemNumLog2+1:2]],
                           data_mem0[ram_addr[`DataMemNumLog2+1:2]]};
        end else begin
            ram_data_o <= `ZeroWord;
        end
    end

endmodule
