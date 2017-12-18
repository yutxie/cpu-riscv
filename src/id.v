`include "defines.v"

module id(

    input wire                    rst,
    input wire[`InstAddrBus]      pc_i,
    input wire[`InstBus]          inst_i,

    input wire[`RegBus]           reg1_data_i,
    input wire[`RegBus]           reg2_data_i,

    //送到regfile的信息
    output reg                    reg1_read_o,
    output reg                    reg2_read_o,
    output reg[`RegAddrBus]       reg1_addr_o,
    output reg[`RegAddrBus]       reg2_addr_o,

    //送到执行阶段的信息
    output reg[`AluOpBus]         aluop_o,
    output reg[`AluSelBus]        alusel_o,
    output reg[`RegBus]           reg1_o,
    output reg[`RegBus]           reg2_o,
    output reg[`RegAddrBus]       wd_o,
    output reg                    wreg_o
);

    wire[6:0] opcode = inst_i[6:0];
    wire[2:0] funct3 = inst_i[14:12];
    wire[6:0] funct7 = inst_i[31:25];

    wire[4:0] rd_addr = inst_i[11:7];
    wire[4:0] rs1_addr = inst_i[19:15];
    wire[4:0] rs2_addr = inst_i[24:20];

    wire[4:0] imm0_s_type = inst_i[11:7];
    wire[11:5] imm5_s_type = inst_i[31:25];

    wire[11:11] imm11_b_type = inst_i[7:7];
    wire[4:1] imm1_b_type = inst_i[11:8];
    wire[10:5] imm5_b_type = inst_i[30:25];
    wire[12:12] imm12_b_type = inst_i[31:31];

    wire[31:12] imm_u_type = inst_i[31:12];

    wire[19:12] imm12_j_type = inst_i[19:12];
    wire[11:11] imm11_j_type = inst_i[20:20];
    wire[10:1] imm1_j_type = inst_i[30:21];
    wire[20:20] imm20_j_type = inst_i[31:31];

    reg[`RegBus]  imm;
    reg instvalid;

    // 对指令进行译码 ///////////////////////////////////////
    always @ (*) begin
        if (rst == `RstEnable) begin
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wd_o <= `NOPRegAddr;
            wreg_o <= `WriteDisable;
            instvalid <= `InstValid;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= `NOPRegAddr;
            reg2_addr_o <= `NOPRegAddr;
            imm <= 32'h0;
        end else begin
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wd_o <= rd_addr;
            wreg_o <= `WriteDisable;
            instvalid <= `InstInvalid;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= rs1_addr;
            reg2_addr_o <= rs2_addr;
            imm <= `ZeroWord;

            // 指令
            case (opcode) begin
                `OPCODE_OP_IMM: begin
                    wreg_o <= `WriteEnable;
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b0;
                    imm <= {20{inst_i[31:31]}, inst_i[31:20]};
                    wd_o <= rd_addr;
                    instvalid <= `InstValid;
                    case (funct3)
                        `FUNCT3_ORI`: begin
                            aluop_o <= `EXE_OR_OP;
                            alusel_o <= `EXE_RES_LOGIC;
                        default: begin
                        end
                    endcase // op imm funct3
                default: begin
                end
            endcase // opcode

        end //if
    end //always

    // 确定进行运算的源操作数 ///////////////////////////////
    always @ (*) begin
        if(rst == `RstEnable) begin
            reg1_o <= `ZeroWord;
        end else if(reg1_read_o == 1'b1) begin
            reg1_o <= reg1_data_i;
        end else if(reg1_read_o == 1'b0) begin
            reg1_o <= imm;
        end else begin
            reg1_o <= `ZeroWord;
        end
    end

    always @ (*) begin
        stallreq_for_reg2_loadrelate <= `NoStop;
        if(rst == `RstEnable) begin
            reg2_o <= `ZeroWord;
        end else if(reg2_read_o == 1'b1) begin
            reg2_o <= reg2_data_i;
        end else if(reg2_read_o == 1'b0) begin
            reg2_o <= imm;
        end else begin
            reg2_o <= `ZeroWord;
        end
    end



endmodule
