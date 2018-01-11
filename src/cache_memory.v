`include "defines.v"

module cache_memory
    #(
        parameter ADDR_WIDTH = 32,
        parameter SELECT_WIDTH = 4,
        parameter DATA_WIDTH = 32,
        parameter BENCH_WIDTH = DATA_WIDTH * (1 << (SELECT_WIDTH-2))
    )
    (
        input wire                              clk,

        // connect with i_cache
        input wire ic_read_i,
        input wire[ADDR_WIDTH-1:0] ic_addr_i,
        output reg[BENCH_WIDTH-1:0] ic_data_o,
        output reg ic_done_o,

        // data_ram
        input wire                              ram_ce,
        input wire                              ram_we,
        input wire[`DataAddrBus]                ram_addr,
        input wire[3:0]                         ram_sel,
        input wire[`DataBus]                    ram_data_i,
        output reg[`DataBus]                    ram_data_o
    );

    reg[`InstBus] inst_mem[0:`InstMemNum-1];
    reg[`ByteWidth]  data_mem0[0:`DataMemNum-1]; // low ram_addr
    reg[`ByteWidth]  data_mem1[0:`DataMemNum-1];
    reg[`ByteWidth]  data_mem2[0:`DataMemNum-1];
    reg[`ByteWidth]  data_mem3[0:`DataMemNum-1]; // high ram_addr

    reg[3:0] cnt;
    
    integer i;
    initial begin
        $readmemh ("D:\\Users\\DELL\\Desktop\\inst_rom.data", inst_mem);
        for (i = 0; i < `InstMemNum; i = i + 1) begin
            data_mem3[i] <= inst_mem[i][7:0];
            data_mem2[i] <= inst_mem[i][15:8];
            data_mem1[i] <= inst_mem[i][23:16];
            data_mem0[i] <= inst_mem[i][31:24];
        end
        cnt <= 0;
    end
    
    always @ (posedge clk) begin
        cnt <= cnt + 1;
    end

    always @ (*) begin
        ic_data_o[31:0]   <= {data_mem3[(ic_addr_i>>2)+0], data_mem2[(ic_addr_i>>2)+0], data_mem1[(ic_addr_i>>2)+0], data_mem0[(ic_addr_i>>2)+0]}; 
        ic_data_o[63:32]  <= {data_mem3[(ic_addr_i>>2)+1], data_mem2[(ic_addr_i>>2)+1], data_mem1[(ic_addr_i>>2)+1], data_mem0[(ic_addr_i>>2)+1]};
        ic_data_o[95:64]  <= {data_mem3[(ic_addr_i>>2)+2], data_mem2[(ic_addr_i>>2)+2], data_mem1[(ic_addr_i>>2)+2], data_mem0[(ic_addr_i>>2)+2]};
        ic_data_o[127:96] <= {data_mem3[(ic_addr_i>>2)+3], data_mem2[(ic_addr_i>>2)+3], data_mem1[(ic_addr_i>>2)+3], data_mem0[(ic_addr_i>>2)+3]};
        if (cnt == 0) begin
            ic_done_o <= 1'b1;
            cnt <= cnt + 1;
        end else begin
            ic_done_o <= 1'b0;
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
