module top(
    input  wire       clk,
    input  wire       rst,

    input  wire [3:0] btn,
    input  wire       uart_rx,

    output wire       spi_sck,
    output wire       spi_mosi,
    output wire       tft_cs,
    output wire       tft_dc,
    output wire       tft_rst
);

    // ========================================
    // GPIO
    // ========================================

    wire [3:0] btn_press;

    gpio_buttons gpio (
        .clk   (clk),
        .rst   (rst),
        .btn   (btn),
        .press (btn_press)
    );


    // ========================================
    // TIMER
    // ========================================

    wire game_tick;

    game_timer timer (
        .clk       (clk),
        .rst       (rst),
        .game_tick (game_tick)
    );


    // ========================================
    // UART
    // ========================================

    wire [7:0] uart_data;
    wire       uart_valid;

    uart_rx uart (
        .clk       (clk),
        .rst       (rst),
        .rx        (uart_rx),
        .data      (uart_data),
        .valid     (uart_valid)
    );


    // ========================================
    // DIRECTION
    // ========================================

    localparam UP    = 2'd0;
    localparam RIGHT = 2'd1;
    localparam DOWN  = 2'd2;
    localparam LEFT  = 2'd3;

    reg [1:0] direction;

    wire [1:0] uart_direction;

    wasd_decoder decoder (
        .clk         (clk),
        .rst         (rst),
        .uart_data   (uart_data),
        .uart_valid  (uart_valid),
        .current_dir (direction),
        .new_dir     (uart_direction)
    );


    // ========================================
    // BUTTON + UART CONTROL
    // ========================================

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            direction <= RIGHT;
        end
        else begin

            // Button priority
            if (btn_press[0])
                direction <= UP;

            else if (btn_press[1])
                direction <= RIGHT;

            else if (btn_press[2])
                direction <= DOWN;

            else if (btn_press[3])
                direction <= LEFT;

            // UART
            else if (uart_valid)
                direction <= uart_direction;

        end
    end


    // ========================================
    // TFT
    // ========================================

    tft_st7789 tft (
        .clk       (clk),
        .rst       (rst),

        .direction (direction),
        .game_tick (game_tick),

        .tft_cs    (tft_cs),
        .tft_dc    (tft_dc),
        .tft_rst   (tft_rst),

        .tft_sck   (spi_sck),
        .tft_mosi  (spi_mosi)
    );

endmodule
