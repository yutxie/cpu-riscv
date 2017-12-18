module cpu_riscv_min_sopc (

    input wire clk,
    input wire rst
);

    // 连接 inst_rom
    wire[`InstAddrBus] inst_addr;
    wire[`InstBus] inst;
    wire rom_ce;


    cpu_riscv cpu_riscv0(
        .clk(clk),
        .rst(rst),

        .rom_addr_o(inst_addr),
        .rom_data_i(inst),
        .rom_ce_o(rom_ce)
    );

    inst_rom inst_rom0(
        .addr(inst_addr),
        .inst(inst),
        .ce(rom_ce)
    );

endmodule // cpu_riscv_min_so
