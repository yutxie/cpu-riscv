module cpu_riscv_min_sopc (

    input wire clk,
    input wire rst
);

    // connect inst_rom
    wire[`InstAddrBus] inst_addr;
    wire[`InstBus] inst;
    wire rom_ce;

    // connect data_ram
    wire mem_we_i;
    wire[`RegBus] mem_addr_i;
    wire[`RegBus] mem_data_i;
    wire[`RegBus] mem_data_o;
    wire[3:0] mem_sel_i;
    wire mem_ce_i;

    cpu_riscv cpu_riscv0(
        .clk(clk),
        .rst(rst),

        .rom_addr_o(inst_addr),
        .rom_data_i(inst),
        .rom_ce_o(rom_ce),

        .ram_we_o(mem_we_i),
        .ram_addr_o(mem_addr_i),
        .ram_sel_o(mem_sel_i),
        .ram_data_o(mem_data_i),
        .ram_data_i(mem_data_o),
        .ram_ce_o(mem_ce_i)
    );

    memory memory0(
        .clk(clk),

        .rom_ce(rom_ce),
        .rom_addr(inst_addr),
        .rom_inst(inst),

        .ram_we(mem_we_i),
        .ram_addr(mem_addr_i),
        .ram_sel(mem_sel_i),
        .ram_data_i(mem_data_i),
        .ram_data_o(mem_data_o),
        .ram_ce(mem_ce_i)
    );

endmodule // cpu_riscv_min_so
