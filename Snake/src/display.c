#include "display.h"
#include "config.h"


static void tft_wait_ready(void)
{
    while ((TFT_STATUS & 1u) == 0u)
    {
    }
}


static void tft_cmd(uint8_t cmd)
{
    tft_wait_ready();

    TFT_CMD = cmd;
}


static void tft_data(uint8_t data)
{
    tft_wait_ready();

    TFT_DATA = data;
}


static void tft_set_window(uint8_t x0,
                           uint8_t y0,
                           uint8_t x1,
                           uint8_t y1)
{
    tft_cmd(0x2A);

    tft_data(0x00);
    tft_data(x0);

    tft_data(0x00);
    tft_data(x1);


    tft_cmd(0x2B);

    tft_data(0x00);
    tft_data(y0);

    tft_data(0x00);
    tft_data(y1);


    tft_cmd(0x2C);
}


static void tft_write_color(uint16_t color)
{
    tft_data((uint8_t)(color >> 8));
    tft_data((uint8_t)(color & 0xFF));
}


static void tft_fill_rect(uint8_t x,
                          uint8_t y,
                          uint8_t width,
                          uint8_t height,
                          uint16_t color)
{
    uint16_t i;
    uint16_t count;

    tft_set_window(
        x,
        y,
        x + width - 1,
        y + height - 1
    );

    count = (uint16_t)width * height;

    for (i = 0; i < count; i++)
    {
        tft_write_color(color);
    }
}


void display_init(void)
{
    /*
     * ST7735 initialization is performed
     * by tft_st7735.v.
     */

    tft_wait_ready();
}


void display_clear(uint16_t color)
{
    tft_fill_rect(
        0,
        0,
        TFT_WIDTH,
        TFT_HEIGHT,
        color
    );
}


void display_draw_board(const Game *game)
{
    uint8_t x;
    uint8_t y;
    uint16_t color;

    /*
     * Clear board area.
     */

    tft_fill_rect(
        BOARD_X,
        BOARD_Y,
        BOARD_PIXEL_WIDTH,
        BOARD_PIXEL_HEIGHT,
        COLOR_BLACK
    );


    /*
     * Draw food.
     */

    tft_fill_rect(
        BOARD_X +
        game->food.x * CELL_SIZE,

        BOARD_Y +
        game->food.y * CELL_SIZE,

        CELL_SIZE,
        CELL_SIZE,

        COLOR_RED
    );


    /*
     * Draw snake.
     */

    for (uint16_t i = 0;
         i < game->snake.length;
         i++)
    {
        if (i == 0)
        {
            color = COLOR_GREEN;
        }
        else
        {
            color = COLOR_CYAN;
        }

        x = game->snake.body[i].x;
        y = game->snake.body[i].y;

        tft_fill_rect(
            BOARD_X + x * CELL_SIZE,
            BOARD_Y + y * CELL_SIZE,
            CELL_SIZE,
            CELL_SIZE,
            color
        );
    }
}


void display_draw_score(const Game *game)
{
    /*
     * Simple score indicator.
     *
     * Number of small blocks represents score.
     */

    uint32_t score;
    uint32_t i;

    score = game->score;

    if (score > 20)
    {
        score = 20;
    }

    for (i = 0; i < 20; i++)
    {
        if (i < score)
        {
            tft_fill_rect(
                4 + i * 6,
                10,
                4,
                6,
                COLOR_YELLOW
            );
        }
        else
        {
            tft_fill_rect(
                4 + i * 6,
                10,
                4,
                6,
                COLOR_BLACK
            );
        }
    }
}


void display_draw_state(const Game *game)
{
    if (game->state == GAME_PAUSED)
    {
        tft_fill_rect(
            52,
            25,
            24,
            8,
            COLOR_YELLOW
        );
    }
    else if (game->state == GAME_OVER)
    {
        tft_fill_rect(
            40,
            25,
            48,
            8,
            COLOR_RED
        );
    }
    else if (game->state == GAME_WIN)
    {
        tft_fill_rect(
            40,
            25,
            48,
            8,
            COLOR_GREEN
        );
    }
    else
    {
        tft_fill_rect(
            40,
            25,
            48,
            8,
            COLOR_BLACK
        );
    }
}


void display_update(const Game *game)
{
    display_draw_board(game);

    display_draw_score(game);

    display_draw_state(game);
}
