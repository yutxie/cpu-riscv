module cpu_riscv_min_sopc (

    input wire clk,
    input wire rst
);

    // connect inst_rom
    wire[`InstAddrBus] rom_addr;
    wire[127:0] rom_data;
    wire rom_done;
    wire rom_read;

    // connect data_ram
    wire ram_we;
    wire[`RegBus] ram_addr;
    wire[`RegBus] ram_data_i;
    wire[`RegBus] ram_data_o;
    wire[3:0] ram_sel;
    wire ram_ce;

    cpu_riscv cpu_riscv0(
        .clk(clk),
        .rst(rst),

        .rom_data_i(rom_data),
        .rom_done_i(rom_done),
        .rom_addr_o(rom_addr),
        .rom_read_o(rom_read),

        .ram_we_o(ram_we),
        .ram_addr_o(ram_addr),
        .ram_sel_o(ram_sel),
        .ram_data_o(ram_data_i),
        .ram_data_i(ram_data_o),
        .ram_ce_o(ram_ce)
    );

    cache_memory cache_memory0(
        .clk(clk),

        .ic_read_i(rom_read),
        .ic_addr_i(rom_addr),
        .ic_data_o(rom_data),
        .ic_done_o(rom_done),

        .ram_we(ram_we),
        .ram_addr(ram_addr),
        .ram_sel(ram_sel),
        .ram_data_i(ram_data_i),
        .ram_data_o(ram_data_o),
        .ram_ce(ram_ce)
    );

endmodule // cpu_riscv_min_so
