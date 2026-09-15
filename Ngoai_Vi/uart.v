module uart_rx #(
    parameter CLK_FREQ = 27_000_000,
    parameter BAUD     = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,

    output reg [7:0]  data,
    output reg        valid
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD;

    reg rx1;
    reg rx2;

    reg [2:0] state;
    reg [31:0] count;
    reg [2:0] bit_index;
    reg [7:0] shift;

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx1       <= 1;
            rx2       <= 1;
            state     <= IDLE;
            count     <= 0;
            bit_index <= 0;
            shift     <= 0;
            data      <= 0;
            valid     <= 0;
        end
        else begin
            rx1   <= rx;
            rx2   <= rx1;
            valid <= 0;

            case (state)

                IDLE: begin
                    count <= 0;

                    if (!rx2) begin
                        state <= START;
                    end
                end

                START: begin
                    if (count == CLKS_PER_BIT/2) begin
                        count <= 0;

                        if (!rx2)
                            state <= DATA;
                        else
                            state <= IDLE;
                    end
                    else begin
                        count <= count + 1;
                    end
                end

                DATA: begin
                    if (count == CLKS_PER_BIT-1) begin
                        count <= 0;

                        shift[bit_index] <= rx2;

                        if (bit_index == 3'd7) begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1;
                        end
                    end
                    else begin
                        count <= count + 1;
                    end
                end

                STOP: begin
                    if (count == CLKS_PER_BIT-1) begin
                        count <= 0;
                        data  <= shift;
                        valid <= 1;
                        state <= IDLE;
                    end
                    else begin
                        count <= count + 1;
                    end
                end

                default:
                    state <= IDLE;

            endcase
        end
    end

endmodule