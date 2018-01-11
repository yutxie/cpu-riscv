module i_cache
    #(
        parameter WAYS = 2,
        parameter ADDR_WIDTH = 32,
        parameter INDEX_WIDTH = 5,
        parameter SELECT_WIDTH = 4,
        parameter TAG_WIDTH = ADDR_WIDTH - INDEX_WIDTH - SELECT_WIDTH,
        parameter DATA_WIDTH = 32,
        parameter BENCH_WIDTH = DATA_WIDTH * (1 << (SELECT_WIDTH-2))
    )
    (
        input wire clk,
        input wire rst,

        // connect with core
        input wire[ADDR_WIDTH-1:0] core_addr_i,
        output reg[DATA_WIDTH-1:0] core_data_o,
        output reg core_stallreq_o,

        // connect with mem
        input wire[BENCH_WIDTH-1:0] mem_data_i,
        input wire mem_done_i,
        output reg mem_read_o,
        output reg[ADDR_WIDTH-1:0] mem_addr_o
    );

    wire[TAG_WIDTH-1:0]    tag    = core_addr_i[ADDR_WIDTH-1:INDEX_WIDTH+SELECT_WIDTH];
    wire[INDEX_WIDTH-1:0]  index  = core_addr_i[INDEX_WIDTH+SELECT_WIDTH-1:SELECT_WIDTH];
    wire[SELECT_WIDTH-1:0] select = core_addr_i[SELECT_WIDTH-1:0];

    reg[DATA_WIDTH-1:0] cache_data  [0:(1<<INDEX_WIDTH)-1][0:WAYS-1][0:(1<<(SELECT_WIDTH-2))-1];
    reg[TAG_WIDTH-1:0]  cache_tag   [0:(1<<INDEX_WIDTH)-1][0:WAYS-1];
    reg                 cache_valid [0:(1<<INDEX_WIDTH)-1][0:WAYS-1];
    reg                 cache_recnt [0:(1<<INDEX_WIDTH)-1];

    wire[1:0] hit = (cache_valid[index][0] && cache_tag[index][0] == tag) ? 2'b00 :
                    (cache_valid[index][1] && cache_tag[index][1] == tag) ? 2'b01 : 2'b10;
    wire[1:0] set = (cache_recnt[index] == 1'b0) ? 1'b1 : 1'b0;

    integer way;
    integer row;

    always @(*) begin
        if (rst == `RstEnable) begin
            for (row = 0; row < (1<<INDEX_WIDTH); row = row + 1) begin
                cache_recnt[row] <= 0;
                for (way = 0; way < WAYS; way = way + 1) begin
                    cache_valid[row][way] <= 0;
                end
            end
            mem_read_o <= 1'b0;
            mem_addr_o <= `ZeroWord;
        end else begin
            if (hit == 2'b10) begin
                mem_read_o <= 1'b1;
                mem_addr_o <= {core_addr_i[ADDR_WIDTH-1:SELECT_WIDTH], 4'b0};
                if (mem_done_i) begin
                    cache_data[index][set][0] <= mem_data_i[31:0];
                    cache_data[index][set][1] <= mem_data_i[63:32];
                    cache_data[index][set][2] <= mem_data_i[95:64];
                    cache_data[index][set][3] <= mem_data_i[127:96];
                    cache_valid[index][set] <= 1'b1;
                    cache_tag[index][set] <= tag;
                    mem_read_o <= 1'b0;
                    mem_addr_o <= `ZeroWord;
                end
            end else begin
                mem_read_o <= 1'b0;
                mem_addr_o <= `ZeroWord;
            end 
        end
    end
    
    always @(*) begin
        if (hit < 2'b10) begin
            core_data_o = cache_data[index][hit][select[SELECT_WIDTH-1:2]];
            cache_recnt[index] = hit;
        end
    end

    always @(*) begin
        if (hit == 2'b10) begin
            core_stallreq_o <= 1'b1;
        end else begin
            core_stallreq_o <= 1'b0;
        end
    end

endmodule
