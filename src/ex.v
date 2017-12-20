`include "defines.v"

module ex(

    input wire                    rst,

    // from id
    input wire[`AluOpBus]         aluop_i,
    input wire[`AluSelBus]        alusel_i,
    input wire[`RegBus]           reg1_i,
    input wire[`RegBus]           reg2_i,
    input wire[`RegAddrBus]       wd_i,
    input wire                    wreg_i,

    // to mem
    output reg[`RegAddrBus]       wd_o,
    output reg                    wreg_o,
    output reg[`RegBus]           wdata_o
);

    reg[`RegBus] logicout;
    reg[`RegBus] shiftres;
    reg[`RegBus] arithmeticres;

    wire reg1_eq_reg2; // rs1 == rs2 ?
    wire reg1_lt_reg2; // rs1 < rs2 ?
    wire[`RegBus] reg2_i_mux;
    wire[`RegBus] reg1_i_not;
    wire[`RegBus] result_sum; // res of add

    // preperation //////////////////////////////////////////
    assign stallreq = `NoStop;
    assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) ||
                         (aluop_i == `EXE_SLT_OP)) ?
                         (~reg2_i) + 1 : reg2_i;
    assign result_sum = reg1_i + reg2_i_mux;
    assign reg1_lt_reg2 = (aluop_i == `EXE_SLT_OP) ?
                          ((reg1_i[31] && !reg2_i[31]) ||
                           (!reg1_i[31] && !reg2_i[31] && result_sum[31]) ||
                           (reg1_i[31] && reg1_i[31] && result_sum[31])) :
                          (reg1_i < reg2_i);
    assign reg1_i_not = ~reg1_i;

    // 依据 aluop_i 指示的算子进行运算 ////////////////////////
    // logic
    always @ (*) begin
        if(rst == `RstEnable) begin
            logicout <= `ZeroWord;
        end else begin
            case (aluop_i)
                `EXE_OR_OP: begin
                    logicout <= reg1_i | reg2_i;
                end
                `EXE_AND_OP: begin
                    logicout <= reg1_i & reg2_i;
                end
                `EXE_XOR_OP: begin
                    logicout <= reg1_i ^ reg2_i;
                end
                default: begin
                    logicout <= `ZeroWord;
                end
            endcase
        end    //if
    end      //always
    // shift
    always @ (*) begin
        if(rst == `RstEnable) begin
            shiftres <= `ZeroWord;
        end else begin
            case (aluop_i)
                `EXE_SLL_OP: begin
                    shiftres <= reg1_i << reg2_i[4:0];
                end
                `EXE_SRL_OP: begin
                    shiftres <= reg1_i >> reg2_i[4:0];
                end
                `EXE_SRA_OP: begin // not sure
                    shiftres <= ({32{reg1_i[31]}} << (6'd32 - {1'b0,reg2_i[4:0]})) |
                                (reg1_i >> reg2_i[4:0]);
                end
                default: begin
                    shiftres <= `ZeroWord;
                end
            endcase
        end    //if
    end      //always
    // arithmetic
    always @ (*) begin
        if(rst == `RstEnable) begin
            arithmeticres <= `ZeroWord;
        end else begin
            case (aluop_i)
                `EXE_SLT_OP, `EXE_SLTU_OP: begin
                    arithmeticres <= reg1_lt_reg2;
                end
                `EXE_ADD_OP, `EXE_ADDI_OP: begin
                    arithmeticres <= result_sum;
                end
                `EXE_SUB_OP: begin
                    arithmeticres <= result_sum;
                end
                default: begin
                    arithmeticres <= `ZeroWord;
                end
            endcase
        end    //if
    end      //always

    // 依据 alusel_i 指示的运算类型选择运算结果 //////////////////
    always @ ( * ) begin
        wd_o <= wd_i;
        wreg_o <= wreg_i;
        case (alusel_i)
            `EXE_RES_LOGIC: begin
                wdata_o <= logicout;
            end
            `EXE_RES_SHIFT: begin
                wdata_o <= shiftres;
            end
            `EXE_RES_ARITHMETIC: begin
                wdata_o <= arithmeticres;
            end
            default: begin
            end
        endcase // alusel_i
    end

endmodule
