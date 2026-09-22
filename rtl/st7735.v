`timescale 1ns / 1ps

module st7735 #(
    parameter CLK_FREQ = 27_000_000,
    parameter SPI_DIV  = 4
)(
    input  wire       clk,
    input  wire       rst,

    input  wire       cmd_valid,
    input  wire [7:0] cmd_data,

    input  wire       data_valid,
    input  wire [7:0] data_in,

    output wire       busy,
    output wire       ready,

    output wire       tft_cs,
    output wire       tft_dc,
    output wire       tft_rst,
    output wire       tft_sck,
    output wire       tft_mosi
);


    /*
     * ========================================================
     * SPI MASTER
     * ========================================================
     *
     * spi_master.v KHÔNG THAY ĐỔI.
     */

    reg       spi_start;
    reg [7:0] spi_data;

    wire spi_busy;
    wire spi_done;


    spi_master #(
        .CLK_DIV(SPI_DIV)
    ) spi_inst (
        .clk      (clk),
        .rst      (rst),

        .start    (spi_start),
        .data_in  (spi_data),

        .busy     (spi_busy),
        .done     (spi_done),

        .spi_sck  (tft_sck),
        .spi_mosi (tft_mosi)
    );


    /*
     * ========================================================
     * TFT signals
     * ========================================================
     */

    reg tft_cs_reg;
    reg tft_dc_reg;
    reg tft_rst_reg;

    assign tft_cs  = tft_cs_reg;
    assign tft_dc  = tft_dc_reg;
    assign tft_rst = tft_rst_reg;


    /*
     * ========================================================
     * STATES
     * ========================================================
     */

    localparam STATE_RESET          = 6'd0;
    localparam STATE_RESET_WAIT     = 6'd1;

    localparam STATE_SWRESET        = 6'd2;
    localparam STATE_SWRESET_WAIT   = 6'd3;

    localparam STATE_SLPOUT         = 6'd4;
    localparam STATE_SLPOUT_WAIT    = 6'd5;
    localparam STATE_SLPOUT_DELAY   = 6'd6;

    localparam STATE_COLMOD         = 6'd7;
    localparam STATE_COLMOD_WAIT    = 6'd8;
    localparam STATE_COLMOD_DATA    = 6'd9;
    localparam STATE_COLMOD_DATA_WAIT = 6'd10;

    localparam STATE_MADCTL         = 6'd11;
    localparam STATE_MADCTL_WAIT    = 6'd12;
    localparam STATE_MADCTL_DATA    = 6'd13;
    localparam STATE_MADCTL_DATA_WAIT = 6'd14;

    localparam STATE_INVON          = 6'd15;
    localparam STATE_INVON_WAIT     = 6'd16;

    localparam STATE_NORON          = 6'd17;
    localparam STATE_NORON_WAIT     = 6'd18;

    localparam STATE_DISPON         = 6'd19;
    localparam STATE_DISPON_WAIT    = 6'd20;

    localparam STATE_READY          = 6'd21;

    localparam STATE_CPU_CMD        = 6'd22;
    localparam STATE_CPU_DATA       = 6'd23;

    localparam STATE_STREAM         = 6'd24;


    reg [5:0] state;

    /*
     * Lưu command cuối cùng.
     *
     * Đặc biệt cần biết command có phải RAMWR 0x2C hay không.
     */

    reg [7:0] current_cmd;


    /*
     * ========================================================
     * Delay
     * ========================================================
     *
     * Hardware:
     *
     * RESET  ~5 ms
     * SLPOUT ~120 ms
     *
     * Simulation:
     * delay rất ngắn để không phải chờ thật.
     */

`ifdef SIMULATION

    localparam integer RESET_DELAY_CYCLES  = 27;
    localparam integer SLPOUT_DELAY_CYCLES = 270;

`else

    localparam integer RESET_DELAY_CYCLES =
        CLK_FREQ / 200;

    localparam integer SLPOUT_DELAY_CYCLES =
        CLK_FREQ / 8;

`endif


    reg [31:0] delay_cnt;


    /*
     * ========================================================
     * STATUS
     * ========================================================
     *
     * READY = 1 khi CPU có thể gửi byte tiếp theo.
     *
     * STATE_STREAM cũng READY.
     */

    assign busy =
        (state != STATE_READY) &&
        (state != STATE_STREAM);


    assign ready =
        ((state == STATE_READY) ||
         (state == STATE_STREAM)) &&
        !spi_busy;


    /*
     * ========================================================
     * MAIN FSM
     * ========================================================
     */

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state <= STATE_RESET;

            delay_cnt <= 0;

            spi_start <= 0;
            spi_data  <= 0;

            current_cmd <= 0;

            tft_cs_reg  <= 1;
            tft_dc_reg  <= 0;
            tft_rst_reg <= 0;

        end

        else begin

            /*
             * spi_start chỉ kéo HIGH một clock.
             */

            spi_start <= 0;


            case (state)


                /*
                 * ==================================================
                 * RESET
                 * ==================================================
                 */

                STATE_RESET: begin

                    tft_cs_reg  <= 1;
                    tft_dc_reg  <= 0;
                    tft_rst_reg <= 0;

                    delay_cnt <= 0;

                    state <= STATE_RESET_WAIT;
                end


                STATE_RESET_WAIT: begin

                    if (delay_cnt >= RESET_DELAY_CYCLES) begin

                        delay_cnt <= 0;

                        tft_rst_reg <= 1;

                        state <= STATE_SWRESET;
                    end

                    else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end


                /*
                 * ==================================================
                 * SOFTWARE RESET 0x01
                 * ==================================================
                 */

                STATE_SWRESET: begin

                    if (!spi_busy) begin

                        tft_cs_reg <= 0;
                        tft_dc_reg <= 0;

                        spi_data  <= 8'h01;
                        spi_start <= 1;

                        state <= STATE_SWRESET_WAIT;
                    end
                end


                STATE_SWRESET_WAIT: begin

                    if (spi_done) begin

                        tft_cs_reg <= 1;

                        delay_cnt <= 0;

                        state <= STATE_SLPOUT;
                    end
                end


                /*
                 * ==================================================
                 * SLEEP OUT 0x11
                 * ==================================================
                 */

                STATE_SLPOUT: begin

                    if (!spi_busy) begin

                        tft_cs_reg <= 0;
                        tft_dc_reg <= 0;

                        spi_data  <= 8'h11;
                        spi_start <= 1;

                        state <= STATE_SLPOUT_WAIT;
                    end
                end


                STATE_SLPOUT_WAIT: begin

                    if (spi_done) begin

                        tft_cs_reg <= 1;

                        delay_cnt <= 0;

                        state <= STATE_SLPOUT_DELAY;
                    end
                end


                STATE_SLPOUT_DELAY: begin

                    if (delay_cnt >= SLPOUT_DELAY_CYCLES) begin

                        delay_cnt <= 0;

                        state <= STATE_COLMOD;
                    end

                    else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end


                /*
                 * ==================================================
                 * COLMOD 0x3A
                 * RGB565 = 0x05
                 * ==================================================
                 */

                STATE_COLMOD: begin

                    if (!spi_busy) begin

                        tft_cs_reg <= 0;
                        tft_dc_reg <= 0;

                        spi_data  <= 8'h3A;
                        spi_start <= 1;

                        state <= STATE_COLMOD_WAIT;
                    end
                end


                STATE_COLMOD_WAIT: begin

                    if (spi_done) begin

                        tft_dc_reg <= 1;

                        state <= STATE_COLMOD_DATA;
                    end
                end


                STATE_COLMOD_DATA: begin

                    if (!spi_busy) begin

                        spi_data  <= 8'h05;
                        spi_start <= 1;

                        state <= STATE_COLMOD_DATA_WAIT;
                    end
                end


                STATE_COLMOD_DATA_WAIT: begin

                    if (spi_done) begin

                        tft_cs_reg <= 1;
                        tft_dc_reg <= 0;

                        state <= STATE_MADCTL;
                    end
                end


                /*
                 * ==================================================
                 * MADCTL 0x36
                 *
                 * 0xC0:
                 * MX + MY + RGB
                 *
                 * Phù hợp hướng portrait kiểu black-tab.
                 * ==================================================
                 */

                STATE_MADCTL: begin

                    if (!spi_busy) begin

                        tft_cs_reg <= 0;
                        tft_dc_reg <= 0;

                        spi_data  <= 8'h36;
                        spi_start <= 1;

                        state <= STATE_MADCTL_WAIT;
                    end
                end


                STATE_MADCTL_WAIT: begin

                    if (spi_done) begin

                        tft_dc_reg <= 1;

                        state <= STATE_MADCTL_DATA;
                    end
                end


                STATE_MADCTL_DATA: begin

                    if (!spi_busy) begin

                        spi_data  <= 8'hC0;
                        spi_start <= 1;

                        state <= STATE_MADCTL_DATA_WAIT;
                    end
                end


                STATE_MADCTL_DATA_WAIT: begin

                    if (spi_done) begin

                        tft_cs_reg <= 1;
                        tft_dc_reg <= 0;

                        state <= STATE_INVON;
                    end
                end


                /*
                 * ==================================================
                 * INVERSION ON 0x21
                 * ==================================================
                 */

                STATE_INVON: begin

                    if (!spi_busy) begin

                        tft_cs_reg <= 0;
                        tft_dc_reg <= 0;

                        spi_data  <= 8'h21;
                        spi_start <= 1;

                        state <= STATE_INVON_WAIT;
                    end
                end


                STATE_INVON_WAIT: begin

                    if (spi_done) begin

                        tft_cs_reg <= 1;

                        state <= STATE_NORON;
                    end
                end


                /*
                 * ==================================================
                 * NORMAL DISPLAY ON 0x13
                 * ==================================================
                 */

                STATE_NORON: begin

                    if (!spi_busy) begin

                        tft_cs_reg <= 0;
                        tft_dc_reg <= 0;

                        spi_data  <= 8'h13;
                        spi_start <= 1;

                        state <= STATE_NORON_WAIT;
                    end
                end


                STATE_NORON_WAIT: begin

                    if (spi_done) begin

                        tft_cs_reg <= 1;

                        state <= STATE_DISPON;
                    end
                end


                /*
                 * ==================================================
                 * DISPLAY ON 0x29
                 * ==================================================
                 */

                STATE_DISPON: begin

                    if (!spi_busy) begin

                        tft_cs_reg <= 0;
                        tft_dc_reg <= 0;

                        spi_data  <= 8'h29;
                        spi_start <= 1;

                        state <= STATE_DISPON_WAIT;
                    end
                end


                STATE_DISPON_WAIT: begin

                    if (spi_done) begin

                        tft_cs_reg <= 1;
                        tft_dc_reg <= 0;

                        state <= STATE_READY;
                    end
                end


                /*
                 * ==================================================
                 * READY
                 * ==================================================
                 */

                STATE_READY: begin

                    /*
                     * Không có giao dịch:
                     * CS HIGH.
                     */

                    tft_cs_reg <= 1;
                    tft_dc_reg <= 0;


                    /*
                     * CPU gửi COMMAND
                     */

                    if (cmd_valid) begin

                        tft_cs_reg <= 0;
                        tft_dc_reg <= 0;

                        spi_data <= cmd_data;
                        spi_start <= 1;

                        current_cmd <= cmd_data;

                        state <= STATE_CPU_CMD;
                    end


                    /*
                     * CPU gửi DATA
                     */

                    else if (data_valid) begin

                        tft_cs_reg <= 0;
                        tft_dc_reg <= 1;

                        spi_data <= data_in;
                        spi_start <= 1;

                        state <= STATE_CPU_DATA;
                    end
                end


                /*
                 * ==================================================
                 * CPU COMMAND
                 * ==================================================
                 */

                STATE_CPU_CMD: begin

                    if (spi_done) begin

                        /*
                         * Nếu command = RAMWR
                         * thì bắt đầu stream pixel.
                         */

                        if (current_cmd == 8'h2C) begin

                            tft_cs_reg <= 0;
                            tft_dc_reg <= 1;

                            state <= STATE_STREAM;
                        end

                        else begin

                            tft_cs_reg <= 1;
                            tft_dc_reg <= 0;

                            state <= STATE_READY;
                        end
                    end
                end


                /*
                 * ==================================================
                 * CPU DATA
                 *
                 * Data bình thường:
                 * gửi xong thì CS HIGH.
                 * ==================================================
                 */

                STATE_CPU_DATA: begin

                    if (spi_done) begin

                        tft_cs_reg <= 1;
                        tft_dc_reg <= 0;

                        state <= STATE_READY;
                    end
                end


                /*
                 * ==================================================
                 * STREAM
                 *
                 * Đây là phần quan trọng.
                 *
                 * Sau 0x2C:
                 *
                 * CS GIỮ LOW.
                 * DC = HIGH.
                 *
                 * Mỗi DATA tiếp theo được gửi liên tục.
                 * ==================================================
                 */

                STATE_STREAM: begin

                    tft_cs_reg <= 0;
                    tft_dc_reg <= 1;


                    /*
                     * DATA:
                     * tiếp tục stream.
                     */

                    if (data_valid) begin

                        spi_data  <= data_in;
                        spi_start <= 1;

                        state <= STATE_STREAM;
                    end


                    /*
                     * COMMAND:
                     *
                     * Cho phép command mới kết thúc stream.
                     */

                    else if (cmd_valid) begin

                        tft_cs_reg <= 0;
                        tft_dc_reg <= 0;

                        spi_data <= cmd_data;
                        spi_start <= 1;

                        current_cmd <= cmd_data;

                        state <= STATE_CPU_CMD;
                    end
                end


                /*
                 * ==================================================
                 * DEFAULT
                 * ==================================================
                 */

                default: begin

                    state <= STATE_RESET;

                    delay_cnt <= 0;

                    tft_cs_reg  <= 1;
                    tft_dc_reg  <= 0;
                    tft_rst_reg <= 0;
                end

            endcase
        end
    end

endmodule