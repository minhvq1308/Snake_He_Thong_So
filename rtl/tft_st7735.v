`timescale 1ns / 1ps

module tft_st7735 (
    input wire        clk,
    input wire        rst,

    input wire        cmd_valid,
    input wire [31:0] cmd_data,

    input wire        data_valid,
    input wire [31:0] data_data,

    output wire        cmd_ready,
    output wire        data_ready,
    output wire [31:0] bus_rdata,

    output wire        spi_sck,
    output wire        spi_mosi,

    output reg         tft_cs,
    output reg         tft_dc,
    output reg         tft_rst
);

    // ============================================================
    // SPI MASTER
    // GIỮ NGUYÊN spi_master.v
    // ============================================================

    reg        spi_start;
    reg [7:0]  spi_data;

    wire       spi_busy;
    wire       spi_done;

    spi_master #(
        .CLK_DIV(2)
    ) u_spi (
        .clk      (clk),
        .rst      (rst),
        .start    (spi_start),
        .data_in  (spi_data),
        .busy     (spi_busy),
        .done     (spi_done),
        .spi_sck  (spi_sck),
        .spi_mosi (spi_mosi)
    );

    // ============================================================
    // STATE
    // ============================================================

    localparam ST_RESET         = 8'd0;
    localparam ST_RESET_WAIT    = 8'd1;

    localparam ST_SWRESET       = 8'd2;
    localparam ST_SWRESET_WAIT  = 8'd3;
    localparam ST_SWRESET_DLY   = 8'd4;

    localparam ST_SLPOUT        = 8'd5;
    localparam ST_SLPOUT_WAIT   = 8'd6;
    localparam ST_SLPOUT_DLY    = 8'd7;

    localparam ST_COLMOD        = 8'd8;
    localparam ST_COLMOD_WAIT   = 8'd9;

    localparam ST_MADCTL        = 8'd10;
    localparam ST_MADCTL_WAIT   = 8'd11;

    localparam ST_CASET         = 8'd12;
    localparam ST_CASET_WAIT    = 8'd13;
    localparam ST_CASET_B1      = 8'd14;
    localparam ST_CASET_B1_W    = 8'd15;
    localparam ST_CASET_B2      = 8'd16;
    localparam ST_CASET_B2_W    = 8'd17;
    localparam ST_CASET_B3      = 8'd18;
    localparam ST_CASET_B3_W    = 8'd19;
    localparam ST_CASET_B4      = 8'd20;
    localparam ST_CASET_B4_W    = 8'd21;

    localparam ST_RASET         = 8'd22;
    localparam ST_RASET_WAIT    = 8'd23;
    localparam ST_RASET_B1      = 8'd24;
    localparam ST_RASET_B1_W    = 8'd25;
    localparam ST_RASET_B2      = 8'd26;
    localparam ST_RASET_B2_W    = 8'd27;
    localparam ST_RASET_B3      = 8'd28;
    localparam ST_RASET_B3_W    = 8'd29;
    localparam ST_RASET_B4      = 8'd30;
    localparam ST_RASET_B4_W    = 8'd31;

    localparam ST_NORON         = 8'd32;
    localparam ST_NORON_WAIT    = 8'd33;

    localparam ST_DISPON        = 8'd34;
    localparam ST_DISPON_WAIT   = 8'd35;
    localparam ST_DISPON_DLY    = 8'd36;

    // ============================================================
    // CPU COMMAND / DATA
    // ============================================================

    localparam ST_IDLE          = 8'd37;

    localparam ST_PARAM_X       = 8'd38;
    localparam ST_PARAM_Y       = 8'd39;
    localparam ST_PARAM_W       = 8'd40;
    localparam ST_PARAM_H       = 8'd41;
    localparam ST_PARAM_COLOR   = 8'd42;

    // ============================================================
    // DRAW RECTANGLE
    // ============================================================

    localparam ST_DRAW_CASET        = 8'd43;
    localparam ST_DRAW_CASET_WAIT   = 8'd44;
    localparam ST_DRAW_CASET_X1H    = 8'd45;
    localparam ST_DRAW_CASET_X1H_W  = 8'd46;
    localparam ST_DRAW_CASET_X1L    = 8'd47;
    localparam ST_DRAW_CASET_X1L_W  = 8'd48;
    localparam ST_DRAW_CASET_X2H    = 8'd49;
    localparam ST_DRAW_CASET_X2H_W  = 8'd50;
    localparam ST_DRAW_CASET_X2L    = 8'd51;
    localparam ST_DRAW_CASET_X2L_W  = 8'd52;

    localparam ST_DRAW_RASET        = 8'd53;
    localparam ST_DRAW_RASET_WAIT   = 8'd54;
    localparam ST_DRAW_RASET_Y1H    = 8'd55;
    localparam ST_DRAW_RASET_Y1H_W  = 8'd56;
    localparam ST_DRAW_RASET_Y1L    = 8'd57;
    localparam ST_DRAW_RASET_Y1L_W  = 8'd58;
    localparam ST_DRAW_RASET_Y2H    = 8'd59;
    localparam ST_DRAW_RASET_Y2H_W  = 8'd60;
    localparam ST_DRAW_RASET_Y2L    = 8'd61;
    localparam ST_DRAW_RASET_Y2L_W  = 8'd62;

    localparam ST_DRAW_RAMWR        = 8'd63;
    localparam ST_DRAW_RAMWR_WAIT   = 8'd64;

    localparam ST_PIXEL_HIGH        = 8'd65;
    localparam ST_PIXEL_HIGH_WAIT   = 8'd66;

    localparam ST_PIXEL_LOW         = 8'd67;
    localparam ST_PIXEL_LOW_WAIT    = 8'd68;

    localparam ST_DONE              = 8'd69;

    reg [7:0] state;

    // ============================================================
    // DELAY
    // ============================================================

    reg [31:0] delay_count;

    // ============================================================
    // RECTANGLE PARAMETERS
    // ============================================================

    reg [15:0] rect_x;
    reg [15:0] rect_y;
    reg [15:0] rect_w;
    reg [15:0] rect_h;
    reg [15:0] rect_color;

    reg [15:0] rect_x_end;
    reg [15:0] rect_y_end;

    // ============================================================
    // PIXEL COUNTER
    // 128 x 160 = 20480 pixels
    // ============================================================

    reg [15:0] pixel_count;

    // ============================================================
    // CPU BUS
    // ============================================================

    assign cmd_ready =
        (state == ST_IDLE);

    assign data_ready =
        (state == ST_PARAM_X)     ||
        (state == ST_PARAM_Y)     ||
        (state == ST_PARAM_W)     ||
        (state == ST_PARAM_H)     ||
        (state == ST_PARAM_COLOR);

    assign bus_rdata = 32'h00000000;

    // ============================================================
    // FSM
    // ============================================================

    always @(posedge clk) begin

        if (rst) begin

            state <= ST_RESET;

            delay_count <= 32'd0;

            spi_start <= 1'b0;
            spi_data  <= 8'h00;

            tft_cs  <= 1'b1;
            tft_dc  <= 1'b0;
            tft_rst <= 1'b0;

            rect_x     <= 16'd0;
            rect_y     <= 16'd0;
            rect_w     <= 16'd0;
            rect_h     <= 16'd0;
            rect_color <= 16'h07E0;

            rect_x_end <= 16'd0;
            rect_y_end <= 16'd0;

            pixel_count <= 16'd0;

        end
        else begin

            // Mặc định không start SPI
            spi_start <= 1'b0;

            case (state)

                // ====================================================
                // HARDWARE RESET
                // ====================================================

                ST_RESET: begin

                    tft_cs  <= 1'b1;
                    tft_dc  <= 1'b0;
                    tft_rst <= 1'b0;

                    delay_count <= 32'd0;

                    state <= ST_RESET_WAIT;
                end


                ST_RESET_WAIT: begin

                    tft_cs  <= 1'b1;
                    tft_dc  <= 1'b0;
                    tft_rst <= 1'b0;

                    if (delay_count < 32'd270000) begin

                        delay_count <= delay_count + 1'b1;

                    end
                    else begin

                        delay_count <= 32'd0;

                        tft_rst <= 1'b1;

                        state <= ST_SWRESET;
                    end
                end


                // ====================================================
                // SWRESET = 01
                // ====================================================

                ST_SWRESET: begin

                    tft_cs <= 1'b0;
                    tft_dc <= 1'b0;

                    spi_data  <= 8'h01;
                    spi_start <= 1'b1;

                    state <= ST_SWRESET_WAIT;
                end


                ST_SWRESET_WAIT: begin

                    if (spi_done) begin

                        tft_cs <= 1'b1;

                        delay_count <= 32'd0;

                        state <= ST_SWRESET_DLY;
                    end
                end


                // 150 ms
                ST_SWRESET_DLY: begin

                    if (delay_count < 32'd4050000) begin

                        delay_count <= delay_count + 1'b1;

                    end
                    else begin

                        delay_count <= 32'd0;

                        state <= ST_SLPOUT;
                    end
                end


                // ====================================================
                // SLPOUT = 11
                // ====================================================

                ST_SLPOUT: begin

                    tft_cs <= 1'b0;
                    tft_dc <= 1'b0;

                    spi_data  <= 8'h11;
                    spi_start <= 1'b1;

                    state <= ST_SLPOUT_WAIT;
                end


                ST_SLPOUT_WAIT: begin

                    if (spi_done) begin

                        tft_cs <= 1'b1;

                        delay_count <= 32'd0;

                        state <= ST_SLPOUT_DLY;
                    end
                end


                // 120 ms
                ST_SLPOUT_DLY: begin

                    if (delay_count < 32'd3240000) begin

                        delay_count <= delay_count + 1'b1;

                    end
                    else begin

                        delay_count <= 32'd0;

                        state <= ST_COLMOD;
                    end
                end


                // ====================================================
                // COLMOD = 3A 05
                // RGB565
                // ====================================================

                ST_COLMOD: begin

                    tft_cs <= 1'b0;
                    tft_dc <= 1'b0;

                    spi_data  <= 8'h3A;
                    spi_start <= 1'b1;

                    state <= ST_COLMOD_WAIT;
                end


                ST_COLMOD_WAIT: begin

                    if (spi_done) begin

                        tft_dc <= 1'b1;

                        spi_data  <= 8'h05;
                        spi_start <= 1'b1;

                        state <= ST_MADCTL;
                    end
                end


                // ====================================================
                // MADCTL = 36 C8
                // ====================================================

                ST_MADCTL: begin

                    if (spi_done) begin

                        tft_dc <= 1'b0;

                        spi_data  <= 8'h36;
                        spi_start <= 1'b1;

                        state <= ST_MADCTL_WAIT;
                    end
                end


                ST_MADCTL_WAIT: begin

                    if (spi_done) begin

                        tft_dc <= 1'b1;

                        spi_data  <= 8'hC8;
                        spi_start <= 1'b1;

                        state <= ST_CASET;
                    end
                end


                // ====================================================
                // CASET INIT
                // 2A
                // 00 00 00 7F
                // ====================================================

                ST_CASET: begin

                    if (spi_done) begin

                        tft_dc <= 1'b0;

                        spi_data  <= 8'h2A;
                        spi_start <= 1'b1;

                        state <= ST_CASET_WAIT;
                    end
                end


                ST_CASET_WAIT: begin

                    if (spi_done) begin

                        tft_dc <= 1'b1;

                        spi_data  <= 8'h00;
                        spi_start <= 1'b1;

                        state <= ST_CASET_B1;
                    end
                end


                ST_CASET_B1: begin

                    if (spi_done) begin

                        spi_data  <= 8'h00;
                        spi_start <= 1'b1;

                        state <= ST_CASET_B2;
                    end
                end


                ST_CASET_B2: begin

                    if (spi_done) begin

                        spi_data  <= 8'h00;
                        spi_start <= 1'b1;

                        state <= ST_CASET_B3;
                    end
                end


                ST_CASET_B3: begin

                    if (spi_done) begin

                        spi_data  <= 8'h7F;
                        spi_start <= 1'b1;

                        state <= ST_CASET_B4;
                    end
                end


                ST_CASET_B4: begin

                    if (spi_done) begin

                        state <= ST_RASET;
                    end
                end


                // ====================================================
                // RASET INIT
                // 2B
                // 00 00 00 9F
                // ====================================================

                ST_RASET: begin

                    tft_dc <= 1'b0;

                    spi_data  <= 8'h2B;
                    spi_start <= 1'b1;

                    state <= ST_RASET_WAIT;
                end


                ST_RASET_WAIT: begin

                    if (spi_done) begin

                        tft_dc <= 1'b1;

                        spi_data  <= 8'h00;
                        spi_start <= 1'b1;

                        state <= ST_RASET_B1;
                    end
                end


                ST_RASET_B1: begin

                    if (spi_done) begin

                        spi_data  <= 8'h00;
                        spi_start <= 1'b1;

                        state <= ST_RASET_B2;
                    end
                end


                ST_RASET_B2: begin

                    if (spi_done) begin

                        spi_data  <= 8'h00;
                        spi_start <= 1'b1;

                        state <= ST_RASET_B3;
                    end
                end


                ST_RASET_B3: begin

                    if (spi_done) begin

                        spi_data  <= 8'h9F;
                        spi_start <= 1'b1;

                        state <= ST_RASET_B4;
                    end
                end


                ST_RASET_B4: begin

                    if (spi_done) begin

                        state <= ST_NORON;
                    end
                end


                // ====================================================
                // NORON = 13
                // ====================================================

                ST_NORON: begin

                    tft_dc <= 1'b0;

                    spi_data  <= 8'h13;
                    spi_start <= 1'b1;

                    state <= ST_NORON_WAIT;
                end


                ST_NORON_WAIT: begin

                    if (spi_done) begin

                        tft_cs <= 1'b1;

                        state <= ST_DISPON;
                    end
                end


                // ====================================================
                // DISPON = 29
                // ====================================================

                ST_DISPON: begin

                    tft_cs <= 1'b0;
                    tft_dc <= 1'b0;

                    spi_data  <= 8'h29;
                    spi_start <= 1'b1;

                    state <= ST_DISPON_WAIT;
                end


                ST_DISPON_WAIT: begin

                    if (spi_done) begin

                        tft_cs <= 1'b1;

                        delay_count <= 32'd0;

                        state <= ST_DISPON_DLY;
                    end
                end


                // ====================================================
                // DELAY SAU DISPON
                // ====================================================

                ST_DISPON_DLY: begin

                    if (delay_count < 32'd270000) begin

                        delay_count <= delay_count + 1'b1;

                    end
                    else begin

                        delay_count <= 32'd0;

                        state <= ST_IDLE;
                    end
                end


                // ====================================================
                // IDLE
                // CPU CÓ THỂ GỬI COMMAND
                // ====================================================

                ST_IDLE: begin

                    tft_cs  <= 1'b1;
                    tft_dc  <= 1'b0;
                    tft_rst <= 1'b1;

                    // CMD = 3 -> DRAW RECTANGLE
                    if (cmd_valid && cmd_data == 32'd3) begin

                        state <= ST_PARAM_X;
                    end
                end


                // ====================================================
                // NHẬN X
                // ====================================================

                ST_PARAM_X: begin

                    if (data_valid) begin

                        rect_x <= data_data[15:0];

                        state <= ST_PARAM_Y;
                    end
                end


                // ====================================================
                // NHẬN Y
                // ====================================================

                ST_PARAM_Y: begin

                    if (data_valid) begin

                        rect_y <= data_data[15:0];

                        state <= ST_PARAM_W;
                    end
                end


                // ====================================================
                // NHẬN WIDTH
                // ====================================================

                ST_PARAM_W: begin

                    if (data_valid) begin

                        rect_w <= data_data[15:0];

                        state <= ST_PARAM_H;
                    end
                end


                // ====================================================
                // NHẬN HEIGHT
                // ====================================================

                ST_PARAM_H: begin

                    if (data_valid) begin

                        rect_h <= data_data[15:0];

                        state <= ST_PARAM_COLOR;
                    end
                end


                // ====================================================
                // NHẬN COLOR
                // ====================================================

                ST_PARAM_COLOR: begin

                    if (data_valid) begin
                        // Tạm thời bỏ qua màu CPU gửi.
                        // Luôn vẽ màu xanh lá RGB565.
                        rect_color <= 16'h07E0;

                        state <= ST_DRAW_CASET;
                    end

                end

                // ====================================================
                // DRAW CASET
                //
                // 2A
                // X_START_H
                // X_START_L
                // X_END_H
                // X_END_L
                // ====================================================

                ST_DRAW_CASET: begin

                    tft_cs <= 1'b0;
                    tft_dc <= 1'b0;

                    // X_END = X + WIDTH - 1
                    rect_x_end <= rect_x + rect_w - 1'b1;

                    spi_data  <= 8'h2A;
                    spi_start <= 1'b1;

                    state <= ST_DRAW_CASET_WAIT;
                end


                ST_DRAW_CASET_WAIT: begin

                    if (spi_done) begin

                        tft_dc <= 1'b1;

                        spi_data  <= rect_x[15:8];
                        spi_start <= 1'b1;

                        state <= ST_DRAW_CASET_X1H;
                    end
                end


                ST_DRAW_CASET_X1H: begin

                    if (spi_done) begin

                        spi_data  <= rect_x[7:0];
                        spi_start <= 1'b1;

                        state <= ST_DRAW_CASET_X1H_W;
                    end
                end


                ST_DRAW_CASET_X1H_W: begin

                    if (spi_done) begin

                        spi_data  <= rect_x_end[15:8];
                        spi_start <= 1'b1;

                        state <= ST_DRAW_CASET_X1L;
                    end
                end


                ST_DRAW_CASET_X1L: begin

                    if (spi_done) begin

                        spi_data  <= rect_x_end[7:0];
                        spi_start <= 1'b1;

                        state <= ST_DRAW_CASET_X1L_W;
                    end
                end


                ST_DRAW_CASET_X1L_W: begin

                    if (spi_done) begin

                        state <= ST_DRAW_RASET;
                    end
                end


                // ====================================================
                // DRAW RASET
                //
                // 2B
                // Y_START_H
                // Y_START_L
                // Y_END_H
                // Y_END_L
                // ====================================================

                ST_DRAW_RASET: begin

                    tft_dc <= 1'b0;

                    // Y_END = Y + HEIGHT - 1
                    rect_y_end <= rect_y + rect_h - 1'b1;

                    spi_data  <= 8'h2B;
                    spi_start <= 1'b1;

                    state <= ST_DRAW_RASET_WAIT;
                end


                ST_DRAW_RASET_WAIT: begin

                    if (spi_done) begin

                        tft_dc <= 1'b1;

                        spi_data  <= rect_y[15:8];
                        spi_start <= 1'b1;

                        state <= ST_DRAW_RASET_Y1H;
                    end
                end


                ST_DRAW_RASET_Y1H: begin

                    if (spi_done) begin

                        spi_data  <= rect_y[7:0];
                        spi_start <= 1'b1;

                        state <= ST_DRAW_RASET_Y1H_W;
                    end
                end


                ST_DRAW_RASET_Y1H_W: begin

                    if (spi_done) begin

                        spi_data  <= rect_y_end[15:8];
                        spi_start <= 1'b1;

                        state <= ST_DRAW_RASET_Y1L;
                    end
                end


                ST_DRAW_RASET_Y1L: begin

                    if (spi_done) begin

                        spi_data  <= rect_y_end[7:0];
                        spi_start <= 1'b1;

                        state <= ST_DRAW_RASET_Y1L_W;
                    end
                end


                ST_DRAW_RASET_Y1L_W: begin

                    if (spi_done) begin

                        state <= ST_DRAW_RAMWR;
                    end
                end


                // ====================================================
                // RAMWR = 2C
                // ====================================================

                ST_DRAW_RAMWR: begin

                    tft_dc <= 1'b0;

                    spi_data  <= 8'h2C;
                    spi_start <= 1'b1;

                    pixel_count <= 16'd0;

                    state <= ST_DRAW_RAMWR_WAIT;
                end


                ST_DRAW_RAMWR_WAIT: begin

                    if (spi_done) begin

                        tft_dc <= 1'b1;

                        state <= ST_PIXEL_HIGH;
                    end
                end


                // ====================================================
                // PIXEL HIGH BYTE
                // ====================================================

                ST_PIXEL_HIGH: begin

                    /*
                     * LẦN TEST NÀY:
                     *
                     * CPU gửi màu qua rect_color.
                     *
                     * Nếu muốn ép màu xanh lá để test bus:
                     *
                     * spi_data <= 8'h07;
                     *
                     * Còn hiện tại dùng màu CPU gửi:
                     */

                    spi_data <= rect_color[15:8];

                    spi_start <= 1'b1;

                    state <= ST_PIXEL_HIGH_WAIT;
                end


                ST_PIXEL_HIGH_WAIT: begin

                    if (spi_done) begin

                        state <= ST_PIXEL_LOW;
                    end
                end


                // ====================================================
                // PIXEL LOW BYTE
                // ====================================================

                ST_PIXEL_LOW: begin

                    spi_data <= rect_color[7:0];

                    spi_start <= 1'b1;

                    state <= ST_PIXEL_LOW_WAIT;
                end


                ST_PIXEL_LOW_WAIT: begin

                    if (spi_done) begin

                        /*
                         * Với màn 128x160:
                         *
                         * 20480 pixel
                         * pixel cuối = 20479
                         */

                        if (pixel_count == 16'd20479) begin

                            tft_cs <= 1'b1;
                            tft_dc <= 1'b0;

                            state <= ST_DONE;

                        end
                        else begin

                            pixel_count <= pixel_count + 1'b1;

                            state <= ST_PIXEL_HIGH;
                        end
                    end
                end


                // ====================================================
                // DONE
                // Sau khi vẽ xong quay lại IDLE
                // để CPU có thể gửi lệnh tiếp theo.
                // ====================================================

                ST_DONE: begin

                    tft_cs  <= 1'b1;
                    tft_dc  <= 1'b0;
                    tft_rst <= 1'b1;

                    state <= ST_IDLE;
                end


                // ====================================================
                // DEFAULT
                // ====================================================

                default: begin

                    state <= ST_RESET;

                    delay_count <= 32'd0;

                    spi_start <= 1'b0;

                    tft_cs  <= 1'b1;
                    tft_dc  <= 1'b0;
                    tft_rst <= 1'b0;
                end

            endcase
        end
    end

endmodule
