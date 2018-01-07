`include "defines.v"

module mem(

    input wire                    rst,

    // from mem
    input wire[`RegAddrBus]       wd_i,
    input wire                    wreg_i,
    input wire[`RegBus]           wdata_i,

    input wire[`AluOpBus]         aluop_i,
    input wire[`RegBus]           mem_addr_i,
    input wire[`RegBus]           reg2_i,

    // from data_ram
    input wire[`RegBus]           mem_data_i,

    // to data_ram
    output reg[`RegBus]           mem_addr_o,
    output reg                    mem_we_o,
    output reg[3:0]               mem_sel_o,
    output reg[`RegBus]           mem_data_o,
    output reg                    mem_ce_o,

    // to wb
    output reg[`RegAddrBus]       wd_o,
    output reg                    wreg_o,
    output reg[`RegBus]           wdata_o
);

    always @ (*) begin
        if(rst == `RstEnable) begin
            wd_o <= `NOPRegAddr;
            wreg_o <= `WriteDisable;
            wdata_o <= `ZeroWord;
            mem_addr_o <= `ZeroWord;
            mem_we_o <= `WriteDisable;
            mem_sel_o <= 4'b0000;
            mem_data_o <= `ZeroWord;
            mem_ce_o <= `ChipDisable;
        end else begin
            wd_o <= wd_i;
            wreg_o <= wreg_i;
            wdata_o <= wdata_i;
            mem_addr_o <= `ZeroWord;
            mem_we_o <= `WriteDisable;
            mem_sel_o <= 4'b0000;
            mem_data_o <= `ZeroWord;
            mem_ce_o <= `ChipDisable;
            case (aluop_i)
                `EXE_LB_OP, `EXE_LH_OP, `EXE_LW_OP, `EXE_LBU_OP, `EXE_LHU_OP: begin
                    mem_addr_o <= mem_addr_i;
                    mem_ce_o <= `ChipEnable;
                    case (aluop_i)
                        `EXE_LB_OP: begin
                            case (mem_addr_i[1:0])
                                2'b00: begin
                                    mem_sel_o <= 4'b0001;
                                    wdata_o <= {{24{mem_data_i[7]}}, mem_data_i[7:0]};
                                end
                                2'b01: begin
                                    mem_sel_o <= 4'b0010;
                                    wdata_o <= {{24{mem_data_i[15]}}, mem_data_i[15:8]};
                                end
                                2'b10: begin
                                    mem_sel_o <= 4'b0100;
                                    wdata_o <= {{24{mem_data_i[23]}}, mem_data_i[23:16]};
                                end
                                2'b11: begin
                                    mem_sel_o <= 4'b1000;
                                    wdata_o <= {{24{mem_data_i[31]}}, mem_data_i[31:24]};
                                end
                                default: begin
                                    wdata_o <= `ZeroWord;
                                end
                            endcase
                        end
                        `EXE_LH_OP: begin
                            case (mem_addr_i[1:0])
                                2'b00: begin
                                    mem_sel_o <= 4'b0011;
                                    wdata_o <= {{16{mem_data_i[15]}}, mem_data_i[15:0]};
                                end
                                2'b10: begin
                                    mem_sel_o <= 4'b1100;
                                    wdata_o <= {{16{mem_data_i[31]}}, mem_data_i[31:16]};
                                end
                                default: begin
                                    wdata_o <= `ZeroWord;
                                end
                            endcase
                        end
                        `EXE_LW_OP: begin
                            mem_sel_o <= 4'b1111;
                            wdata_o <= mem_data_i;
                        end
                        `EXE_LBU_OP: begin
                            case (mem_addr_i[1:0])
                                2'b00: begin
                                    mem_sel_o <= 4'b0001;
                                    wdata_o <= {24'b0, mem_data_i[7:0]};
                                end
                                2'b01: begin
                                    mem_sel_o <= 4'b0010;
                                    wdata_o <= {24'b0, mem_data_i[15:8]};
                                end
                                2'b10: begin
                                    mem_sel_o <= 4'b0100;
                                    wdata_o <= {24'b0, mem_data_i[23:16]};
                                end
                                2'b11: begin
                                    mem_sel_o <= 4'b1000;
                                    wdata_o <= {24'b0, mem_data_i[31:24]};
                                end
                                default: begin
                                    wdata_o <= `ZeroWord;
                                end
                            endcase
                        end
                        `EXE_LHU_OP: begin
                            case (mem_addr_i[1:0])
                                2'b00: begin
                                    mem_sel_o <= 4'b0011;
                                    wdata_o <= {16'b0, mem_data_i[15:0]};
                                end
                                2'b10: begin
                                    mem_sel_o <= 4'b1100;
                                    wdata_o <= {16'b0, mem_data_i[31:16]};
                                end
                                default: begin
                                    wdata_o <= `ZeroWord;
                                end
                            endcase
                        end
                    endcase
                end // load
                `EXE_SB_OP, `EXE_SH_OP, `EXE_SW_OP: begin
                    mem_addr_o <= mem_addr_i;
                    mem_we_o <= `WriteEnable;
                    mem_ce_o <= `ChipEnable;
                    case (aluop_i)
                        `EXE_SB_OP: begin
                            mem_data_o <= {4{reg2_i[7:0]}};
                            case (mem_addr_i[1:0])
                                2'b00: begin
                                    mem_sel_o <= 4'b0001;
                                end
                                2'b01: begin
                                    mem_sel_o <= 4'b0010;
                                end
                                2'b10: begin
                                    mem_sel_o <= 4'b0100;
                                end
                                2'b11: begin
                                    mem_sel_o <= 4'b1000;
                                end
                                default: begin
                                    mem_sel_o <= 4'b0000;
                                end
                            endcase
                        end
                        `EXE_SH_OP: begin
                            mem_data_o <= {2{reg2_i[15:0]}};
                            case (mem_addr_i[1:0])
                                2'b00: begin
                                    mem_sel_o <= 4'b0011;
                                end
                                2'b10: begin
                                    mem_sel_o <= 4'b1100;
                                end
                                default: begin
                                    mem_sel_o <= 4'b0000;
                                end
                            endcase
                        end
                        `EXE_SW_OP: begin
                            mem_sel_o <= 4'b1111;
                            mem_data_o <= reg2_i;
                        end
                    endcase
                end // store
                default: begin
                end
            endcase // aluop_i
        end    //if
    end      //always


endmodule
