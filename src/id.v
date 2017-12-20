`include "defines.v"

module id(

    input wire                    rst,

    // from if
    input wire[`InstAddrBus]      pc_i,
    input wire[`InstBus]          inst_i,

    // from regfile
    input wire[`RegBus]           reg1_data_i,
    input wire[`RegBus]           reg2_data_i,

    // forwarding from ex
    input wire ex_wreg_i,
    input wire[`RegBus] ex_wdata_i,
    input wire[`RegAddrBus] ex_wd_i,

    // forwarding from mem
    input wire mem_wreg_i,
    input wire[`RegBus] mem_wdata_i,
    input wire[`RegAddrBus] mem_wd_i,

    // to regfile
    output reg                    reg1_read_o,
    output reg                    reg2_read_o,
    output reg[`RegAddrBus]       reg1_addr_o,
    output reg[`RegAddrBus]       reg2_addr_o,

    // to ex
    output reg[`AluOpBus]         aluop_o,
    output reg[`AluSelBus]        alusel_o,
    output reg[`RegBus]           reg1_o,
    output reg[`RegBus]           reg2_o,
    output reg[`RegAddrBus]       wd_o,
    output reg                    wreg_o,

    output wire                   stallreq
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

    wire[19:12] imm12_j_type = inst_i[19:12];
    wire[11:11] imm11_j_type = inst_i[20:20];
    wire[10:1] imm1_j_type = inst_i[30:21];
    wire[20:20] imm20_j_type = inst_i[31:31];

    reg[`RegBus]  imm;
    reg instvalid;

    assign stallreq = `NoStop;

    // decode  /////////////////////////////////////////
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
        end
        else begin
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

            // op
            case (opcode)
                `OPCODE_LUI: begin
                    wreg_o <= `WriteEnable;
                    aluop_o <= `EXE_OR_OP;
                    alusel_o <= `EXE_RES_LOGIC;
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b0;
                    imm <= {inst_i[31:12], 12'h0};
                    wd_o <= rd_addr;
                    instvalid <= `InstValid;
                end
                `OPCODE_OP_IMM: begin
                    wreg_o <= `WriteEnable;
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b0;
                    imm <= {{20{inst_i[31:31]}}, inst_i[31:20]};
                    wd_o <= rd_addr;
                    instvalid <= `InstValid;
                    case (funct3)
                        `FUNCT3_XORI: begin
                            aluop_o <= `EXE_XOR_OP;
                            alusel_o <= `EXE_RES_LOGIC;
                        end
                        `FUNCT3_ORI: begin
                            aluop_o <= `EXE_OR_OP;
                            alusel_o <= `EXE_RES_LOGIC;
                        end
                        `FUNCT3_ANDI: begin
                            aluop_o <= `EXE_AND_OP;
                            alusel_o <= `EXE_RES_LOGIC;
                        end
                        `FUNCT3_SLLI: begin
                            aluop_o <= `EXE_SLL_OP;
                            alusel_o <= `EXE_RES_SHIFT;
                            imm[4:0] <= inst_i[24:20];
                        end
                        `FUNCT3_SRLI: begin
                            if (funct7 == `FUNCT7_SRL) begin
                                aluop_o <= `EXE_SRL_OP;
                                alusel_o <= `EXE_RES_SHIFT;
                                imm[4:0] <= inst_i[24:20];
                            end else if (funct7 == `FUNCT7_SRA) begin
                                aluop_o <= `EXE_SRA_OP;
                                alusel_o <= `EXE_RES_SHIFT;
                                imm[4:0] <= inst_i[24:20];
                            end
                        end
                        `FUNCT3_SLTI: begin
                            aluop_o <= `EXE_SLT_OP;
                            alusel_o <= `EXE_RES_ARITHMETIC;
                        end
                        `FUNCT3_SLTIU: begin
                            aluop_o <= `EXE_SLTU_OP;
                            alusel_o <= `EXE_RES_ARITHMETIC;
                        end
                        `FUNCT3_ADDI: begin
                            aluop_o <= `EXE_ADD_OP;
                            alusel_o <= `EXE_RES_ARITHMETIC;
                        end
                        default: begin
                        end
                    endcase //funct3
                end // opcode op imm
                `OPCODE_OP: begin
                    wreg_o <= `WriteEnable;
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b1;
                    wd_o <= rd_addr;
                    instvalid <= `InstValid;
                    case (funct3)
                        `FUNCT3_XOR: begin
                            aluop_o <= `EXE_XOR_OP;
                            alusel_o <= `EXE_RES_LOGIC;
                        end
                        `FUNCT3_OR: begin
                            aluop_o <= `EXE_OR_OP;
                            alusel_o <= `EXE_RES_LOGIC;
                        end
                        `FUNCT3_AND: begin
                            aluop_o <= `EXE_AND_OP;
                            alusel_o <= `EXE_RES_LOGIC;
                        end
                        `FUNCT3_SLL: begin
                            aluop_o <= `EXE_SLL_OP;
                            alusel_o <= `EXE_RES_SHIFT;
                        end
                        `FUNCT3_SRL: begin
                            if (funct7 == `FUNCT7_SRL) begin
                                aluop_o <= `EXE_SRL_OP;
                                alusel_o <= `EXE_RES_SHIFT;
                            end else if (funct7 == `FUNCT7_SRA) begin
                                aluop_o <= `EXE_SRA_OP;
                                alusel_o <= `EXE_RES_SHIFT;
                            end
                        end
                        `FUNCT3_SLT: begin
                            aluop_o <= `EXE_SLT_OP;
                            alusel_o <= `EXE_RES_ARITHMETIC;
                        end
                        `FUNCT3_SLTU: begin
                            aluop_o <= `EXE_SLTU_OP;
                            alusel_o <= `EXE_RES_ARITHMETIC;
                        end
                        `FUNCT3_ADD: begin
                            if (funct7 == `FUNCT7_ADD) begin
                                aluop_o <= `EXE_ADD_OP;
                                alusel_o <= `EXE_RES_ARITHMETIC;
                            end else if(funct7 == `FUNCT7_SUB) begin
                                aluop_o <= `EXE_SUB_OP;
                                alusel_o <= `EXE_RES_ARITHMETIC;
                            end
                        end
                        default: begin
                        end
                    endcase //funct3
                end // opcode op
                default: begin
                end
            endcase // opcode

        end //if
    end //always

    // get src data ///////////////////////////////
    always @ (*) begin
        if(rst == `RstEnable) begin
            reg1_o <= `ZeroWord;
        end else if ((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1)
                                           && (ex_wd_i == reg1_addr_o)) begin
            reg1_o <= ex_wdata_i;
        end else if ((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1)
                                           && (mem_wd_i == reg1_addr_o)) begin
            reg1_o <= mem_wdata_i;
        end else if(reg1_read_o == 1'b1) begin
            reg1_o <= reg1_data_i;
        end else if(reg1_read_o == 1'b0) begin
            reg1_o <= imm;
        end else begin
            reg1_o <= `ZeroWord;
        end
    end
    always @ (*) begin
        if(rst == `RstEnable) begin
            reg2_o <= `ZeroWord;
        end else if ((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1)
                                           && (ex_wd_i == reg2_addr_o)) begin
            reg2_o <= ex_wdata_i;
        end else if ((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1)
                                           && (mem_wd_i == reg2_addr_o)) begin
            reg2_o <= mem_wdata_i;
        end else if(reg2_read_o == 1'b1) begin
            reg2_o <= reg2_data_i;
        end else if(reg2_read_o == 1'b0) begin
            reg2_o <= imm;
        end else begin
            reg2_o <= `ZeroWord;
        end
    end



endmodule
