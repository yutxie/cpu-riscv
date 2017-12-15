`include "defines.v"

module id(

    input wire                    rst,
    input wire[`InstAddrBus]      pc_i,
    input wire[`InstBus]          inst_i,

  //处于执行阶段的指令的一些信息，用于解决load相关
  input wire[`AluOpBus]           ex_aluop_i,

    //处于执行阶段的指令要写入的目的寄存器信息
    input wire                    ex_wreg_i,
    input wire[`RegBus]           ex_wdata_i,
    input wire[`RegAddrBus]       ex_wd_i,
    
    //处于访存阶段的指令要写入的目的寄存器信息
    input wire                    mem_wreg_i,
    input wire[`RegBus]           mem_wdata_i,
    input wire[`RegAddrBus]       mem_wd_i,
    
    input wire[`RegBus]           reg1_data_i,
    input wire[`RegBus]           reg2_data_i,

    //如果上一条指令是转移指令，那么下一条指令在译码的时候is_in_delayslot为true
    input wire                    is_in_delayslot_i,

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
    output reg                    wreg_o,
    output wire[`RegBus]          inst_o,

    output reg                    next_inst_in_delayslot_o,
    
    output reg                    branch_flag_o,
    output reg[`RegBus]           branch_target_address_o,       
    output reg[`RegBus]           link_addr_o,
    output reg                    is_in_delayslot_o,
    
    output wire                   stallreq    
);

    

  wire[5:0] op = inst_i[31:26];
  wire[4:0] op2 = inst_i[10:6];
  wire[5:0] op3 = inst_i[5:0];
  wire[4:0] op4 = inst_i[20:16];
  reg[`RegBus]  imm;
  reg instvalid;
  wire[`RegBus] pc_plus_8;
  wire[`RegBus] pc_plus_4;
  wire[`RegBus] imm_sll2_signedext;  

  reg stallreq_for_reg1_loadrelate;
  reg stallreq_for_reg2_loadrelate;
  wire pre_inst_is_load;
  
  assign pc_plus_8 = pc_i + 8;
  assign pc_plus_4 = pc_i +4;
  assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00 };  
  assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
  assign pre_inst_is_load = ((ex_aluop_i == `EXE_LB_OP) || 
                                                      (ex_aluop_i == `EXE_LBU_OP)||
                                                      (ex_aluop_i == `EXE_LH_OP) ||
                                                      (ex_aluop_i == `EXE_LHU_OP)||
                                                      (ex_aluop_i == `EXE_LW_OP) ||
                                                      (ex_aluop_i == `EXE_LWR_OP)||
                                                      (ex_aluop_i == `EXE_LWL_OP)||
                                                      (ex_aluop_i == `EXE_LL_OP) ||
                                                      (ex_aluop_i == `EXE_SC_OP)) ? 1'b1 : 1'b0;

  assign inst_o = inst_i;
    
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
            branch_target_address_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            next_inst_in_delayslot_o <= `NotInDelaySlot;                    
        end else begin
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wd_o <= inst_i[15:11];
            wreg_o <= `WriteDisable;
            instvalid <= `InstInvalid;       
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= inst_i[25:21];
            reg2_addr_o <= inst_i[20:16];        
            imm <= `ZeroWord;
            link_addr_o <= `ZeroWord;
            branch_target_address_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;    
            next_inst_in_delayslot_o <= `NotInDelaySlot;
        end       //if
    end         //always
    

    always @ (*) begin
        stallreq_for_reg1_loadrelate <= `NoStop;    
        if(rst == `RstEnable) begin
            reg1_o <= `ZeroWord;    
        end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o 
                                             && reg1_read_o == 1'b1 ) begin
            stallreq_for_reg1_loadrelate <= `Stop;                            
        end else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
                                          && (ex_wd_i == reg1_addr_o)) begin
            reg1_o <= ex_wdata_i; 
        end else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
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
        end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o 
                                             && reg2_read_o == 1'b1 ) begin
            stallreq_for_reg2_loadrelate <= `Stop;            
        end else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) 
                                          && (ex_wd_i == reg2_addr_o)) begin
            reg2_o <= ex_wdata_i; 
        end else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) 
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

    always @ (*) begin
        if(rst == `RstEnable) begin
            is_in_delayslot_o <= `NotInDelaySlot;
        end else begin
            is_in_delayslot_o <= is_in_delayslot_i;        
        end
    end

endmodule


/************************

    
    wire[6:0] opcode = inst_i[6:0]; 
    wire[2:0] funct3 = inst_i[14:12];
    wire[6:0] funct7 = inst_i[31:25];
    
    wire[4:0] rd_addr = inst_i[11:7];
    wire[4:0] rs1_addr = inst_i[19:15];
    wire[4:0] rs2_addr = inst_i[24:20];
    
    wire[11:0] imm_i_type = inst_i[31:20];
    
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
    
**********************/