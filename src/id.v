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

    // load relate stall
    input wire[`AluOpBus] ex_aluop_i,

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

    output wire                   stallreq,

    output reg                    branch_flag_o,
    output reg[`RegBus]           branch_target_addr_o,
    output reg[`RegBus]           link_addr_o,

    output reg[`RegBus]           offset_o
);

    wire[6:0] opcode = inst_i[6:0];
    wire[2:0] funct3 = inst_i[14:12];
    wire[6:0] funct7 = inst_i[31:25];

    wire[4:0] rd_addr = inst_i[11:7];
    wire[4:0] rs1_addr = inst_i[19:15];
    wire[4:0] rs2_addr = inst_i[24:20];

    reg[`RegBus] imm; // default: signed ext
    reg[`RegBus] imm_unsigned;
    reg[`RegBus] offset_imm; // default: signed ext
    reg[`RegBus] offset_imm_unsigned;
    reg instvalid;
    reg stallreq_for_reg1_loadrelate;
    reg stallreq_for_reg2_loadrelate;
    wire[`RegBus] pc_plus_4;
    wire pre_inst_is_load;

    // assign stallreq = `NoStop;
    assign pc_plus_4 = pc_i + 4;
    assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
    assign pre_inst_is_load = ((ex_aluop_i == `EXE_LB_OP) ||
                               (ex_aluop_i == `EXE_LBU_OP) ||
                               (ex_aluop_i == `EXE_LH_OP) ||
                               (ex_aluop_i == `EXE_LHU_OP) ||
                               (ex_aluop_i == `EXE_LW_OP));

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
            link_addr_o <= `ZeroWord;
            branch_target_addr_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            offset_o <= `ZeroWord;
        end
        else begin
            aluop_o <= `EXE_NOP_OP;     //
            alusel_o <= `EXE_RES_NOP;   //
            wd_o <= rd_addr;
            wreg_o <= `WriteDisable;    //
            instvalid <= `InstInvalid;
            reg1_read_o <= 1'b0;        //
            reg2_read_o <= 1'b0;        //
            reg1_addr_o <= rs1_addr;
            reg2_addr_o <= rs2_addr;
            imm <= `ZeroWord;           //
            link_addr_o <= `ZeroWord;           //
            branch_target_addr_o <= `ZeroWord;  //
            branch_flag_o <= `NotBranch;        //
            offset_o <= `ZeroWord;       //
            // op
            case (opcode)
                `OPCODE_AUIPC: begin
                    aluop_o <= `EXE_OR_OP;
                    alusel_o <= `EXE_RES_LOGIC;
                    wreg_o <= `WriteEnable;
                    reg1_read_o <= 1'b1;
                    reg1_addr_o <= 5'b00000;
                    imm <= {inst_i[31:12], 12'h0} + pc_i;
                end
                `OPCODE_LUI: begin
                    aluop_o <= `EXE_OR_OP;
                    alusel_o <= `EXE_RES_LOGIC;
                    wreg_o <= `WriteEnable;
                    reg1_read_o <= 1'b1;
                    reg1_addr_o <= 5'b00000;
                    imm <= {inst_i[31:12], 12'h0};
                end // lui
                `OPCODE_JAL: begin
                    aluop_o <= `EXE_JAL_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    wreg_o <= `WriteEnable;
                    link_addr_o <= pc_plus_4;
                    branch_flag_o <= `Branch;
                    branch_target_addr_o <= pc_i + {{12{inst_i[31:31]}},
                        inst_i[19:12], inst_i[20:20], inst_i[30:21], 1'b0};
                end // jal
                `OPCODE_JALR: begin
                    aluop_o <= `EXE_JALR_OP;
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    wreg_o <= `WriteEnable;
                    reg1_read_o <= 1'b1;
                    link_addr_o <= pc_plus_4;
                    branch_flag_o <= `Branch;
                    branch_target_addr_o <= (reg1_o + {{21{inst_i[31:31]}},
                        inst_i[30:20]}) & {31'b1, 1'b0};
                end // jalr
                `OPCODE_BRANCH: begin
                    alusel_o <= `EXE_RES_JUMP_BRANCH;
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b1;
                    offset_imm <= {{20{inst_i[31:31]}},
                        inst_i[7:7], inst_i[30:25], inst_i[11:8], 1'b0};
                    offset_imm_unsigned <= {19'b0, inst_i[31:31],
                        inst_i[7:7], inst_i[30:25], inst_i[11:8], 1'b0};
                    case (funct3)
                        `FUNCT3_BEQ: begin
                            aluop_o <= `EXE_BEQ_OP;
                            if (reg1_o == reg2_o) begin
                                branch_target_addr_o <= pc_i + offset_imm;
                                branch_flag_o <= `Branch;
                            end
                        end
                        `FUNCT3_BNE: begin
                            aluop_o <= `EXE_BNE_OP;
                            if (reg1_o != reg2_o) begin
                                branch_target_addr_o <= pc_i + offset_imm;
                                branch_flag_o <= `Branch;
                            end
                        end
                        `FUNCT3_BLT: begin
                            aluop_o <= `EXE_BLT_OP;
                            if ((reg1_o[31] == 1'b1 && reg2_o[31] == 1'b0) ||
                                (reg1_o[31] == reg2_o[31] && reg1_o[30:0] < reg2_o[30:0])) begin
                                branch_target_addr_o <= pc_i + offset_imm;
                                branch_flag_o <= `Branch;
                            end
                        end
                        `FUNCT3_BGE: begin
                            aluop_o <= `EXE_BGE_OP;
                            if ((reg1_o[31] == 1'b0 && reg2_o[31] == 1'b1) ||
                                (reg1_o[31] == reg2_o[31] && reg1_o[30:0] >= reg2_o[30:0])) begin
                                branch_target_addr_o <= pc_i + offset_imm;
                                branch_flag_o <= `Branch;
                            end
                        end
                        `FUNCT3_BLTU: begin
                            aluop_o <= `EXE_BLTU_OP;
                            imm <= imm_unsigned;
                            if (reg1_o < reg2_o) begin
                                branch_target_addr_o <= pc_i + offset_imm;
                                branch_flag_o <= `Branch;
                            end
                        end
                        `FUNCT3_BGEU: begin
                            aluop_o <= `EXE_BGEU_OP;
                            imm <= imm_unsigned;
                            if (reg1_o >= reg2_o) begin
                                branch_target_addr_o <= pc_i + offset_imm;
                                branch_flag_o <= `Branch;
                            end
                        end
                        default: begin
                        end
                    endcase
                end // branch
                `OPCODE_LOAD: begin
                    alusel_o <= `EXE_RES_LOAD_STORE;
                    wreg_o <= `WriteEnable;
                    reg1_read_o <= 1'b1;
                    offset_o <= {{20{inst_i[31:31]}}, inst_i[31:20]};
                    case (funct3)
                        `FUNCT3_LB: begin
                            aluop_o <= `EXE_LB_OP;
                        end
                        `FUNCT3_LH: begin
                            aluop_o <= `EXE_LH_OP;
                        end
                        `FUNCT3_LW: begin
                            aluop_o <= `EXE_LW_OP;
                        end
                        `FUNCT3_LBU: begin
                            aluop_o <= `EXE_LBU_OP;
                        end
                        `FUNCT3_LHU: begin
                            aluop_o <= `EXE_LHU_OP;
                        end
                        default: begin
                        end
                    endcase
                end // load
                `OPCODE_STORE: begin
                    alusel_o <= `EXE_RES_LOAD_STORE;
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b1;
                    offset_o <= {{21{inst_i[31:31]}}, inst_i[30:25], inst_i[11:7]};
                    case (funct3)
                        `FUNCT3_SB: begin
                            aluop_o <= `EXE_SB_OP;
                        end
                        `FUNCT3_SH: begin
                            aluop_o <= `EXE_SH_OP;
                        end
                        `FUNCT3_SW: begin
                            aluop_o <= `EXE_SW_OP;
                        end
                        default: begin
                        end
                    endcase
                end // store
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
                end // op imm
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
                end // op
                default: begin
                end
            endcase // opcode

        end //if
    end //always

    // get src data ///////////////////////////////
    always @ (*) begin
        stallreq_for_reg1_loadrelate <= `NoStop;
        if(rst == `RstEnable) begin
            reg1_o <= `ZeroWord;
        end else if (pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o
                                              && reg1_read_o == 1'b1) begin
            stallreq_for_reg1_loadrelate <= `Stop;
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
        stallreq_for_reg2_loadrelate <= `NoStop;
        if(rst == `RstEnable) begin
            reg2_o <= `ZeroWord;
        end else if (pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o
                                              && reg2_read_o == 1'b1) begin
            stallreq_for_reg2_loadrelate <= `Stop;
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
