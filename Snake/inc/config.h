#ifndef CONFIG_H
#define CONFIG_H

#include <stdint.h>

/* =========================
 * Hardware addresses
 * ========================= */

#define GPIO_BASE       0x10000000u
#define TIMER_BASE      0x10000004u
#define UART_BASE       0x10000008u
#define TFT_BASE        0x10000010u

#define GPIO_REG        (*(volatile uint32_t *)GPIO_BASE)

#define TIMER_REG       (*(volatile uint32_t *)TIMER_BASE)

#define UART_RX         (*(volatile uint32_t *)(UART_BASE + 0x00u))
#define UART_STATUS     (*(volatile uint32_t *)(UART_BASE + 0x04u))

#define TFT_DATA        (*(volatile uint32_t *)(TFT_BASE + 0x00u))
#define TFT_CMD         (*(volatile uint32_t *)(TFT_BASE + 0x04u))
#define TFT_STATUS      (*(volatile uint32_t *)(TFT_BASE + 0x08u))


/* =========================
 * GPIO buttons
 * ========================= */

#define BUTTON_UP       (1u << 0)
#define BUTTON_RIGHT    (1u << 1)
#define BUTTON_DOWN     (1u << 2)
#define BUTTON_LEFT     (1u << 3)


/* =========================
 * TFT ST7735
 * ========================= */

#define TFT_WIDTH       128
#define TFT_HEIGHT      160


/* =========================
 * Snake board
 *
 * 30 x 15 cells
 * each cell = 4 x 4 pixels
 * ========================= */

#define CELL_SIZE       4

#define BOARD_WIDTH     30
#define BOARD_HEIGHT    15

#define BOARD_X         4
#define BOARD_Y         42

#define BOARD_PIXEL_WIDTH   (BOARD_WIDTH * CELL_SIZE)
#define BOARD_PIXEL_HEIGHT  (BOARD_HEIGHT * CELL_SIZE)


/* =========================
 * Colors RGB565
 * ========================= */

#define COLOR_BLACK     0x0000
#define COLOR_WHITE     0xFFFF
#define COLOR_GREEN     0x07E0
#define COLOR_RED       0xF800
#define COLOR_BLUE      0x001F
#define COLOR_YELLOW    0xFFE0
#define COLOR_CYAN      0x07FF
#define COLOR_MAGENTA   0xF81F


/* =========================
 * Game
 * ========================= */

#define SNAKE_MAX_LENGTH   128

#define SPEED_EASY         3
#define SPEED_NORMAL       2
#define SPEED_HARD         1

#endif
