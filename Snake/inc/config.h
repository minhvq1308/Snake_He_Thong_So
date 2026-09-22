#ifndef CONFIG_H
#define CONFIG_H

/* ============================================================
 * GAME BOARD
 * ============================================================ */

#define BOARD_WIDTH             30
#define BOARD_HEIGHT            15

#define INITIAL_SNAKE_LENGTH    3
#define MAX_SNAKE_LENGTH        (BOARD_WIDTH * BOARD_HEIGHT)

#define SCORE_PER_FOOD          10


/* ============================================================
 * GAME SPEED
 * ============================================================ */

#define EASY_SPEED              180
#define NORMAL_SPEED            120
#define HARD_SPEED              70


/* ============================================================
 * TFT ST7735 1.8"
 *
 * Display: 128 x 160
 *
 * Snake board:
 * 30 x 15 cells
 *
 * Cell:
 * 4 x 4 pixels
 *
 * Board:
 * 120 x 60 pixels
 * ============================================================ */

#define TFT_WIDTH               128
#define TFT_HEIGHT              160

#define CELL_SIZE               4

#define BOARD_PIXEL_WIDTH       (BOARD_WIDTH * CELL_SIZE)
#define BOARD_PIXEL_HEIGHT      (BOARD_HEIGHT * CELL_SIZE)

/*
 * Căn giữa board theo chiều ngang.
 */
#define BOARD_X                 ((TFT_WIDTH - BOARD_PIXEL_WIDTH) / 2)

/*
 * Đặt board ở phía trên màn hình.
 */
#define BOARD_Y                 20


/* ============================================================
 * RGB565 COLORS
 * ============================================================ */

#define COLOR_BLACK             0x0000
#define COLOR_WHITE             0xFFFF
#define COLOR_GREEN             0x07E0
#define COLOR_HEAD              0xFFE0
#define COLOR_RED               0xF800
#define COLOR_BLUE              0x001F
#define COLOR_GRAY              0x8410

#endif