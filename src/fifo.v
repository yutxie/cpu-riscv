module fifo
    #(
        parameter size_bit = 3,
        parameter width = 8
    )
    (
        input wire clk,
        input wire rst,

        input wire read_flag,
        output reg[width-1:0] read_data,
        input wire write_flag,
        input reg[width-1:0] write_data,
        output reg empty,
        output reg full
    );

    localparam  size = 1 << size_bit;
    reg[width-1:0] buffer[size-1:0];
    reg[size_bit-1:0] read_ptr;
    reg[size_bit-1:0] write_ptr;
    reg[size_bit:0] buffer_size;

    assign empty = buffer_size == 0;
    assign full = buffer_size == size;

    wire read, write;
    assign read = read_flag && !empty;
    assign write = write_flag && !full;

    assign read_data = buffer[read_ptr];

    integer i;
    always @(negedge clk or posedge rst) begin
        if (rst) begin
            read_ptr <= 0;
            write_ptr <= 0;
            buffer_size <= 0;
            for (i = 0; i < size; i = i + 1)
                buffer[i] <= 0;
        end else begin
            if (read && write) begin
                buffer[write_ptr] <= write_data;
                read_ptr <= read_ptr + 1;
                write_ptr <= write_ptr + 1;
            end else if (read) begin
                read_ptr <= read_ptr + 1;
                buffer_size <= buffer_size - 1;
            end else if (write) begin
                buffer[write_ptr] <= write_data;
                write_ptr <= write_ptr + 1;
                buffer_size <= buffer_size + 1;
            end
        end
    end

endmodule
