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

    // 依据 aluop_i 指示的算子进行运算 ////////////////////////
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
                `EXE_NOR_OP: begin
                    logicout <= ~(reg1_i |reg2_i);
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

    // 依据 alusel_i 指示的运算类型选择运算结果 //////////////////
    always @ ( * ) begin
        wd_o <= wd_i;
        wreg_o <= wreg_i;
        case (alusel_i)
            `EXE_RES_LOGIC: begin
                wdata_o <= logicout;
            end
            default: begin
            end
        endcase // alusel_i
    end

endmodule
