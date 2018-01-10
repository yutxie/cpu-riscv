module d_cache
    #(
        parameter DATA_WIDTH = 32,
        parameter ADDRESS_WIDTH = 32,
        parameter BLOCK_OFFSET_WIDTH = 2,
        parameter ASSOCIATIVITY = 2,
        parameter INDEX_WIDTH = 12,
        parameter TAG_WIDTH = ADDRESS_WIDTH - INDEX_WIDTH - BLOCK_OFFSET_WIDTH,
        parameter MEM_MASK_WIDTH = 3 // ?
    )
    (
        // inputs
        input clk,
        input rst,

        input valid_i,
        input [MEM_MASK_WIDTH-1:0] mem_mask_i,
        input [ADDRESS_WIDTH-1:0] addr_i,
        input read_write_i,
        input [DATA_WIDTH-1:0] write_data_i,

        // outputs
        output ready_o,
        output reg valid_o,
        output [DATA_WIDTH-1:0] data_o,

        // mem transaction
        output reg mem_valid_o,
        output reg mem_read_write_o,
        output reg [ADDRESS_WIDTH-1:0] mem_addr_o,
        output reg [DATA_WIDTH-1:0] mem_data_o,
        input mem_valid_i,
        input mem_data_read_i,
        input mem_last_i,
        input [DATA_WIDTH-1:0] mem_data_i
    );

    localparam DEBUG = 1'b0;
    localparam FALSE = 1'b0;
    localparam TRUE = 1'b1;
    localparam UNKNOWN = 1'bx;

    localparam READ = 1'b1;
    localparam WRITE = 1'b0;

    wire debug;

    reg [ADDRESS_WIDTH-1:0] r_addr_i;
    reg [BLOCK_OFFSET_WIDTH-1:0] r_blockoffset_i;
    reg [INDEX_WIDTH-1:0] r_index_i;
    reg [TAG_WIDTH-1:0] r_tag_i;
    reg [DATA_WIDTH-1:0] r_write_data_i, r_data_o;
    reg r_read_write_i;

    // decomposation of addr
    wire [BLOCK_OFFSET_WIDTH-1:0] blockoffset_i = addr_i[BLOCK_OFFSET_WIDTH-1:0];
    wire [INDEX_WIDTH-1:0] index_i = addr_i[INDEX_WIDTH+BLOCK_OFFSET_WIDTH-1:BLOCK_OFFSET_WIDTH];
    wire [TAG_WIDTH-1:0] tag_i = addr_i[ADDRESS_WIDTH-1:INDEX_WIDTH+BLOCK_OFFSET_WIDTH];

    // organization of cache
    reg [TAG_WIDTH-1:0] tag_array [0:(1<<INDEX_WIDTH)-1];
    reg [(DATA_WIDTH*(1<<BLOCK_OFFSET_WIDTH))-1:0] data_array [0:(1<<INDEX_WIDTH)-1];
    reg valid_array [0:(1<<INDEX_WIDTH)-1];
    reg dirty_array [0:(1<<INDEX_WIDTH)-1];

    reg [5:0] state;

    localparam STATE_READY = 0;
    localparam STATE_PAUSE = 1;
    localparam STATE_POPULATE = 2;
    localparam STATE_WRITEOUT = 3;

    // counters
    integer i;
    reg [8:0] gen_count;
    assign ready_o = (state == STATE_READY);
    assign debug = 0;
    wire populate = (r_read_write_i == WRITE) && mem_valid_i
        && (gen_count == r_blockoffset_i) && (state == STATE_POPULATE);
    wire [DATA_WIDTH-1:0] populate_data = populate ? r_write_data_i : mem_data_i;

    // adjust for n-way associativity
    wire cache_hit = valid_i && valid_array[index_i] && (tag_array[index_i] == tag_i) && !valid_o;
    wire cache_read_hit = cache_hit && (read_write_i == READ) && (state == STATE_READY);
    wire cache_write_hit = cache_hit && (read_write_i == WRITE) && (state == STATE_READY);
    wire cache_miss = !cache_hit && valid_i && !valid_o;
    wire valid_read = (r_read_write_i == READ) && valid_o;

endmodule
