    `include "defines.v"

    module cpu_riscv(

        input wire                     clk,
        input wire                     rst,

        // inst rom
        input wire[`RegBus]            rom_data_i,
        output wire[`RegBus]           rom_addr_o,
        output wire                    rom_ce_o,

        // data ram
        input wire[`RegBus]            ram_data_i,
        output wire[`RegBus]           ram_addr_o,
        output wire[`RegBus]           ram_data_o,
        output wire                    ram_we_o,
        output wire[3:0]               ram_sel_o,
        output wire                    ram_ce_o
    );

        // connect if_id and id
        wire[`InstAddrBus] pc;
        wire[`InstAddrBus] id_pc_i;
        wire[`InstBus] id_inst_i;

        // connect id and id_ex
        wire[`AluOpBus] id_aluop_o;
        wire[`AluSelBus] id_alusel_o;
        wire[`RegBus] id_reg1_o;
        wire[`RegBus] id_reg2_o;
        wire id_wreg_o;
        wire[`RegAddrBus] id_wd_o;
        wire[`RegBus] id_link_addr_o;
        wire[`RegBus] id_offset_o;

        // connect id_ex and ex
        wire[`AluOpBus] ex_aluop_i;
        wire[`AluSelBus] ex_alusel_i;
        wire[`RegBus] ex_reg1_i;
        wire[`RegBus] ex_reg2_i;
        wire ex_wreg_i;
        wire[`RegAddrBus] ex_wd_i;
        wire[`RegBus] ex_link_addr_i;
        wire[`RegBus] ex_offset_i;

        // connect ex and ex_mem
        wire ex_wreg_o;
        wire[`RegAddrBus] ex_wd_o;
        wire[`RegBus] ex_wdata_o;
        wire[`AluOpBus] ex_aluop_o;
        wire[`RegBus] ex_mem_addr_o;
        wire[`RegBus] ex_reg2_o;

        // connect ex_mem and mem
        wire mem_wreg_i;
        wire[`RegAddrBus] mem_wd_i;
        wire[`RegBus] mem_wdata_i;
        wire[`AluOpBus] mem_aluop_i;
        wire[`RegBus] mem_mem_addr_i;
        wire[`RegBus] mem_reg2_i;

        // connect mem and mem_wb
        wire mem_wreg_o;
        wire[`RegAddrBus] mem_wd_o;
        wire[`RegBus] mem_wdata_o;

        // connect mem_wb and wb
        wire wb_wreg_i;
        wire[`RegAddrBus] wb_wd_i;
        wire[`RegBus] wb_wdata_i;

        // connect id and regfile
        wire reg1_read;
        wire reg2_read;
        wire[`RegBus] reg1_data;
        wire[`RegBus] reg2_data;
        wire[`RegAddrBus] reg1_addr;
        wire[`RegAddrBus] reg2_addr;

        wire id_branch_flag_o;
        wire [`RegBus] id_branch_target_addr_o;

        wire[5:0] stall;
        wire stallreq_from_id;

        pc_reg pc_reg0(
            .clk(clk),
            .rst(rst),
            .stall(stall),
            .branch_flag_i(id_branch_flag_o),
            .branch_target_addr_i(id_branch_target_addr_o),
            .pc(pc),
            .ce(rom_ce_o)
        );

        assign rom_addr_o = pc;

        if_id if_id0(
            .clk(clk),
            .rst(rst),
            .stall(stall),
            .if_pc(pc),
            .if_inst(rom_data_i),
            .id_pc(id_pc_i),
            .id_inst(id_inst_i)
        );

        id id0(
            .rst(rst),

            // from if_id
            .pc_i(id_pc_i),
            .inst_i(id_inst_i),

            // forwarding from ex
            .ex_wreg_i(ex_wreg_o),
            .ex_wdata_i(ex_wdata_o),
            .ex_wd_i(ex_wd_o),

            // forwarding from mem
            .mem_wreg_i(mem_wreg_o),
            .mem_wdata_i(mem_wdata_o),
            .mem_wd_i(mem_wd_o),

            // load relate stall
            .ex_aluop_i(ex_aluop_o),


            // from regfile
            .reg1_data_i(reg1_data),
            .reg2_data_i(reg2_data),

            // to regfile
            .reg1_read_o(reg1_read),
            .reg2_read_o(reg2_read),
            .reg1_addr_o(reg1_addr),
            .reg2_addr_o(reg2_addr),

            // to id_ex
            .aluop_o(id_aluop_o),
            .alusel_o(id_alusel_o),
            .reg1_o(id_reg1_o),
            .reg2_o(id_reg2_o),
            .wd_o(id_wd_o),
            .wreg_o(id_wreg_o),
            .offset_o(id_offset_o),

            .branch_flag_o(id_branch_flag_o),
            .branch_target_addr_o(id_branch_target_addr_o),
            .link_addr_o(id_link_addr_o),

            .stallreq(stallreq_from_id)
        );

        regfile regfile0(
            .clk (clk),
            .rst (rst),
            .we    (wb_wreg_i),
            .waddr (wb_wd_i),
            .wdata (wb_wdata_i),
            .re1    (reg1_read),
            .raddr1 (reg1_addr),
            .rdata1 (reg1_data),
            .re2    (reg2_read),
            .raddr2 (reg2_addr),
            .rdata2 (reg2_data)
        );

        id_ex id_ex0(
            .clk(clk),
            .rst(rst),

            .stall(stall),

            // from id
            .id_aluop(id_aluop_o),
            .id_alusel(id_alusel_o),
            .id_reg1(id_reg1_o),
            .id_reg2(id_reg2_o),
            .id_wd(id_wd_o),
            .id_wreg(id_wreg_o),
            .id_link_addr(id_link_addr_o),
            .id_offset(id_offset_o),

            // to ex
            .ex_aluop(ex_aluop_i),
            .ex_alusel(ex_alusel_i),
            .ex_reg1(ex_reg1_i),
            .ex_reg2(ex_reg2_i),
            .ex_wd(ex_wd_i),
            .ex_wreg(ex_wreg_i),
            .ex_link_addr(ex_link_addr_i),
            .ex_offset(ex_offset_i)
        );

        ex ex0(
            .rst(rst),

            // from id_ex
            .aluop_i(ex_aluop_i),
            .alusel_i(ex_alusel_i),
            .reg1_i(ex_reg1_i),
            .reg2_i(ex_reg2_i),
            .wd_i(ex_wd_i),
            .wreg_i(ex_wreg_i),

            .link_addr_i(ex_link_addr_i),
            .offset_i(ex_offset_i),

            // to ex_mem
            .wd_o(ex_wd_o),
            .wreg_o(ex_wreg_o),
            .wdata_o(ex_wdata_o),
            .aluop_o(ex_aluop_o),
            .mem_addr_o(ex_mem_addr_o),
            .reg2_o(ex_reg2_o)
        );

        ex_mem ex_mem0(
            .clk(clk),
            .rst(rst),

            .stall(stall),

            // from ex
            .ex_wd(ex_wd_o),
            .ex_wreg(ex_wreg_o),
            .ex_wdata(ex_wdata_o),
            .ex_aluop(ex_aluop_o),
            .ex_mem_addr(ex_mem_addr_o),
            .ex_reg2(ex_reg2_o),

            // to mem
            .mem_wd(mem_wd_i),
            .mem_wreg(mem_wreg_i),
            .mem_wdata(mem_wdata_i),
            .mem_aluop(mem_aluop_i),
            .mem_mem_addr(mem_mem_addr_i),
            .mem_reg2(mem_reg2_i)
        );

        mem mem0(
            .rst(rst),

            //from ex_mem
            .wd_i(mem_wd_i),
            .wreg_i(mem_wreg_i),
            .wdata_i(mem_wdata_i),
            .aluop_i(mem_aluop_i),
            .mem_addr_i(mem_mem_addr_i),
            .reg2_i(mem_reg2_i),

            // from data_ram
            .mem_data_i(ram_data_i),

            //to mem_wb
            .wd_o(mem_wd_o),
            .wreg_o(mem_wreg_o),
            .wdata_o(mem_wdata_o),

            // to data_ram
            .mem_addr_o(ram_addr_o),
            .mem_we_o(ram_we_o),
            .mem_sel_o(ram_sel_o),
            .mem_data_o(ram_data_o),
            .mem_ce_o(ram_ce_o)
        );

        mem_wb mem_wb0(
            .clk(clk),
            .rst(rst),

            .stall(stall),

            // from mem
            .mem_wd(mem_wd_o),
            .mem_wreg(mem_wreg_o),
            .mem_wdata(mem_wdata_o),

            // to wb
            .wb_wd(wb_wd_i),
            .wb_wreg(wb_wreg_i),
            .wb_wdata(wb_wdata_i)
        );

        ctrl ctrl0(
            .rst(rst),
            .stallreq_from_id(stallreq_from_id),
            .stall(stall)
        );

    endmodule
