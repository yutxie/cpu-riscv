`timescale 1ns / 1ps

module cpu_riscv_min_sopc_tb ();
    
    reg CLOCK_50;
    reg rst;

    // �?10ns反转�?次clk信号 �?周期20ns 频率 50MHz
    initial begin
        CLOCK_50 = 1'b0;
        forever #10 CLOCK_50 = ~CLOCK_50;
    end

    initial begin
        rst = `RstEnable;
        #195 rst = `RstDisable;
        #1000 $stop;
    end

    cpu_riscv_min_sopc cpu_riscv_min_sopc0(
            .clk(CLOCK_50),
            .rst(rst)
        );

endmodule // cpu_riscv_min_sopc_tb
