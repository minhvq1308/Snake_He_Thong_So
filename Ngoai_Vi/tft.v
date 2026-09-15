module tft_st7789(
    input  wire       clk,
    input  wire       rst,

    input  wire [1:0] direction,
    input  wire       game_tick,

    output reg        tft_cs,
    output reg        tft_dc,
    output reg        tft_rst,

    output wire       tft_sck,
    output wire       tft_mosi
);

    localparam UP    = 2'd0;
    localparam RIGHT = 2'd1;
    localparam DOWN  = 2'd2;
    localparam LEFT  = 2'd3;

    reg spi_start;
    reg [7:0] spi_data;

    wire spi_busy;
    wire spi_done;

    spi_master #(
        .CLK_DIV(4)
    ) spi (
        .clk      (clk),
        .rst      (rst),
        .start    (spi_start),
        .data_in  (spi_data),
        .busy     (spi_busy),
        .done     (spi_done),
        .spi_sck  (tft_sck),
        .spi_mosi (tft_mosi)
    );

    reg [7:0] init_cmd;
    reg [7:0] init_data;

    reg [7:0] state;

    localparam S_RESET  = 0;
    localparam S_SWRESET = 1;
    localparam S_DELAY  = 2;
    localparam S_SLPOUT = 3;
    localparam S_COLMOD = 4;
    localparam S_MADCTL = 5;
    localparam S_INVON  = 6;
    localparam S_DISPON = 7;
    localparam S_IDLE   = 8;

    reg [31:0] delay_cnt;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            tft_cs    <= 1;
            tft_dc    <= 0;
            tft_rst   <= 0;

            spi_start <= 0;
            spi_data  <= 0;

            state     <= S_RESET;
            delay_cnt <= 0;
        end

        else begin

            spi_start <= 0;

            case (state)

                S_RESET: begin
                    tft_rst <= 0;

                    if (delay_cnt == 27_000_000 / 100) begin
                        delay_cnt <= 0;
                        tft_rst <= 1;
                        state <= S_SWRESET;
                    end
                    else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end

                S_SWRESET: begin
                    if (!spi_busy) begin
                        tft_cs    <= 0;
                        tft_dc    <= 0;
                        spi_data  <= 8'h01;
                        spi_start <= 1;
                        state     <= S_DELAY;
                    end
                end

                S_DELAY: begin
                    tft_cs <= 1;

                    if (delay_cnt == 27_000_000 / 20) begin
                        delay_cnt <= 0;
                        state <= S_SLPOUT;
                    end
                    else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end

                S_SLPOUT: begin
                    if (!spi_busy) begin
                        tft_cs    <= 0;
                        tft_dc    <= 0;
                        spi_data  <= 8'h11;
                        spi_start <= 1;
                        state     <= S_COLMOD;
                    end
                end

                S_COLMOD: begin
                    if (spi_done) begin
                        tft_dc    <= 0;
                        spi_data  <= 8'h3A;
                        spi_start <= 1;
                        state     <= S_MADCTL;
                    end
                end

                S_MADCTL: begin
                    if (spi_done) begin
                        tft_dc    <= 1;
                        spi_data  <= 8'h55;
                        spi_start <= 1;
                        state     <= S_INVON;
                    end
                end

                S_INVON: begin
                    if (spi_done) begin
                        tft_dc    <= 0;
                        spi_data  <= 8'h21;
                        spi_start <= 1;
                        state     <= S_DISPON;
                    end
                end

                S_DISPON: begin
                    if (spi_done) begin
                        tft_dc    <= 0;
                        spi_data  <= 8'h29;
                        spi_start <= 1;
                        state     <= S_IDLE;
                    end
                end

                S_IDLE: begin
                    tft_cs <= 1;
                end

                default:
                    state <= S_RESET;

            endcase
        end
    end

endmodule