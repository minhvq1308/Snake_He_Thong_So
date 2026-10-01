`timescale 1ns / 1ps

module top (
    // Clock
    input wire COICHIP,

    // Buttons
    input wire BTN_UP,
    input wire BTN_DOWN,
    input wire BTN_LEFT,
    input wire BTN_RIGHT,
    input wire BTN_RESET,

    // LEDs
    output wire LED_START,
    output wire LED_END,

    // TFT ST7735
    output wire CS_TFT,
    output wire RESET_TFT,
    output wire A0_TFT,
    output wire SDA_TFT,
    output wire SCK_TFT
);

    // =====================================================
    // RESET
    // BTN_RESET = 1 -> reset
    // =====================================================
    wire rst;
    assign rst = BTN_RESET;

    // =====================================================
    // BUTTON MAPPING
    //
    // buttons[0] = UP
    // buttons[1] = RIGHT
    // buttons[2] = DOWN
    // buttons[3] = LEFT
    // =====================================================
    wire [3:0] buttons;

    assign buttons[0] = BTN_UP;
    assign buttons[1] = BTN_RIGHT;
    assign buttons[2] = BTN_DOWN;
    assign buttons[3] = BTN_LEFT;

    // =====================================================
    // UART
    // Không sử dụng UART ở bản này.
    // UART RX ở trạng thái idle = 1
    // =====================================================
    wire uart_rx;
    assign uart_rx = 1'b1;

    // =====================================================
    // LED
    // =====================================================
    assign LED_START = ~rst;
    assign LED_END   = 1'b0;

    // =====================================================
    // SNAKE SOC
    // =====================================================
    snake_soc u_soc (
        .clk      (COICHIP),
        .rst      (rst),

        .buttons  (buttons),
        .uart_rx  (uart_rx),

        // TFT
        .tft_sck  (SCK_TFT),
        .tft_mosi (SDA_TFT),
        .tft_cs   (CS_TFT),
        .tft_dc   (A0_TFT),
        .tft_rst  (RESET_TFT)
    );

endmodule
