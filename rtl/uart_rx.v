module uart_rx #(
    parameter integer CLKS_PER_BIT = 234
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,

    output reg [7:0]  data_out,
    output reg        data_valid
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;

    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  rx_data;

    always @(posedge clk) begin

        if (rst) begin
            state      <= IDLE;
            clk_count  <= 16'd0;
            bit_index  <= 3'd0;
            rx_data    <= 8'd0;
            data_out   <= 8'd0;
            data_valid <= 1'b0;
        end

        else begin

            data_valid <= 1'b0;

            case (state)

                IDLE: begin
                    clk_count <= 16'd0;
                    bit_index <= 3'd0;

                    if (!rx) begin
                        state <= START;
                    end
                end

                START: begin

                    if (clk_count == (CLKS_PER_BIT / 2)) begin

                        clk_count <= 16'd0;

                        if (!rx) begin
                            state <= DATA;
                        end
                        else begin
                            state <= IDLE;
                        end
                    end

                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA: begin

                    if (clk_count == CLKS_PER_BIT - 1) begin

                        clk_count <= 16'd0;

                        rx_data[bit_index] <= rx;

                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state <= STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end

                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP: begin

                    if (clk_count == CLKS_PER_BIT - 1) begin

                        clk_count <= 16'd0;

                        state <= IDLE;

                        data_out <= rx_data;
                        data_valid <= 1'b1;
                    end

                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
