`include "defines.v"

module ex(

    input wire                    rst,

    //送到执行阶段的信息
    input wire[`AluOpBus]         aluop_i,
    input wire[`AluSelBus]        alusel_i,
    input wire[`RegBus]           reg1_i,
    input wire[`RegBus]           reg2_i,
    input wire[`RegAddrBus]       wd_i,
    input wire                    wreg_i,

    //执行的结果
    output reg[`RegAddrBus]       wd_o,
    output reg                    wreg_o,
    output reg[`RegBus]           wdata_o
);

    reg[`RegBus] logicout;
    reg[`RegBus] shiftres;

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
            logicout <= `ZeroWord;
        end else begin
            case (aluop_i)
                `EXE_SLL_OP: begin
                    shiftres <= reg1_i << reg2_i[4:0];
                end
                `EXE_SRL_OP: begin
                    shiftres <= reg1_i >> reg2_i[4:0];
                end
                `EXE_SRA_OP: begin // not sure
                    shiftres <= reg1_i >> reg2_i[4:0];
                    shiftres[31:31] <= reg1_i[31:31];
                end
                default: begin
                    shiftres <= `ZeroWord;
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
            default: begin
            end
        endcase // alusel_i
    end

endmodule
