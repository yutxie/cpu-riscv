module uart
    #(
        parameter width = 8,
        parameter baud_rate = 9600,
        parameter clk_rate = 100000000
    )
    (

        input wire clk,
        input wire rst,

        input wire send_flag,
        input wire[width-1:0] send_data,
        input wire recv_flag,
        output reg[width-1:0] recv_data,

        output reg send_able,
        output reg recv_able,

        output reg tx,
        input wire rx
    );

    reg recv_write_flag;
    reg[width-1:0] recv_write_data;
    wire recv_empty, recv_full;
    fifo#(.width(width)) recv_buffer(clk,
                                     rst,
                                     recv_flag,
                                     recv_data,
                                     recv_write_flag,
                                     recv_write_data,
                                     recv_empty,
                                     recv_full);
    reg send_read_flag;
    wire[width-1:0] send_read_data;
    reg[width-1:0] send_read_data_buf;
    wire send_empty, send_full;
    fifo#(.width(width)) send_buffere(clk,
                                      rst,
                                      send_read_flag,
                                      send_read_data,
                                      send_flag,
                                      send_data,
                                      send_empty,
                                      send_full);

    assign recv_able = !recv_empty;
    assign send_able = !send_full;

    localparam  sample_interval = clk_rate / baud_rate;

    localparam  status_idle = 0;
    localparam  status_begin = 1;
    localparam  status_data = 2;
    localparam  status_valid = 4;
    localparam  status_end = 8;
    reg[3:0] recv_status;
    reg[2:0] recv_bit;
    reg recv_parity;

    integer recv_cnt; // clk passed
    reg recv_clk; // in clk or not

    wire sample = recv_cnt == sample_interval / 2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            recv_write_flag <= 0;
            recv_write_data <= 0;
            recv_status <= status_idle;
            recv_bit <= 0;
            recv_parity <= 0;
            recv_cnt <= 0;
            recv_clk <= 0;
        end else begin
            recv_write_flag <= 0;
            if (recv_clk) begin
                if (recv_cnt == sample_interval - 1)
                    recv_cnt <= 0;
                else
                    recv_cnt <= recv_cnt + 1;
            end
            if (recv_status == status_idle) begin
                if (!rx) begin
                    recv_status <= status_begin;
                    recv_cnt <= 0;
                    recv_clk <= 1;
                end
            end else if (sample) begin
                case (recv_status)
                    status_begin: begin
                        if (!rx) begin
                            recv_status <= status_data;
                            recv_bit <= 0;
                            recv_parity <= 0;
                        end else begin
                            recv_status <= status_idle;
                            recv_clk <= 0;
                        end
                    end
                    status_data: begin
                        recv_parity <= recv_parity ^ rx;
                        recv_write_data[recv_bit] <= rx;
                        recv_bit <= recv_bit + 1;
                        if (recv_bit == 7)
                            recv_status <= status_valid;
                    end
                    status_valid: begin
                        if (recv_parity == rx && !recv_full)
                            recv_write_flag <= 1;
                        recv_status <= status_end;
                    end
                    status_end: begin
                        recv_status <= status_idle;
                        recv_clk <= 0;
                    end
                endcase // recv_status
            end
        end
    end // always

    integer cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
        end else begin
            cnt <= cnt + 1;
            if (cnt == sample_interval - 1)
                cnt <= 0;
        end
    end

    reg[3:0] send_status;
    reg[2:0] send_bit;
    reg send_parity;
    reg tosend;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            send_read_flag <= 0;
            send_read_data_buf <= 0;
            send_status <= status_idle;
            send_bit <= 0;
            send_parity <= 0;
            tosend <= 0;
            tx <= 1;
        end else begin
            send_read_flag <= 0;
            if (cnt == 0) begin
                case (send_status)
                    status_idle: begin
                        if (!send_empty) begin
                            send_read_data_buf <= send_read_data;
                            send_read_flag <= 1;
                            tx <= 0;
                            send_status <= status_data;
                            send_bit <= 0;
                            send_parity <= 0;
                        end
                    end
                    status_data: begin
                        tx <= send_read_data_buf[send_bit];
                        send_parity <= send_parity ^ send_read_data_buf[send_bit];
                        send_bit <= send_bit + 1;
                        if (send_bit == 7)
                            send_status <= status_valid;
                    end
                    status_valid: begin
                        tx <= send_parity;
                        send_status <= status_end;
                    end
                    status_end: begin
                        tx <= 1;
                        send_status <= status_idle;
                        tosend = 0;
                    end
                endcase // send_status
            end // if
        end // else
    end // always

endmodule // uat
