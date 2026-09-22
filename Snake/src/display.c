#include "display.h"
#include "config.h"

/*
 * ============================================================
 * TFT ST7735 MMIO
 * ============================================================
 */

#define TFT_DATA    (*(volatile unsigned int *)0x10000010)
#define TFT_CMD     (*(volatile unsigned int *)0x10000014)
#define TFT_STATUS  (*(volatile unsigned int *)0x10000018)


/*
 * ============================================================
 * Chờ TFT sẵn sàng
 * ============================================================
 */

static void tft_wait_ready(void)
{
    while ((TFT_STATUS & 1u) == 0u)
    {
    }
}


/*
 * ============================================================
 * Gửi command
 * ============================================================
 */

static void tft_write_cmd(unsigned char cmd)
{
    tft_wait_ready();

    TFT_CMD = cmd;
}


/*
 * ============================================================
 * Gửi data
 * ============================================================
 */

static void tft_write_data(unsigned char data)
{
    tft_wait_ready();

    TFT_DATA = data;
}


/*
 * ============================================================
 * Gửi màu RGB565
 * ============================================================
 */

static void tft_write_color(unsigned int color)
{
    tft_write_data((unsigned char)(color >> 8));
    tft_write_data((unsigned char)(color & 0xFF));
}


/*
 * ============================================================
 * Thiết lập vùng vẽ
 *
 * CASET = 0x2A
 * RASET = 0x2B
 * RAMWR = 0x2C
 * ============================================================
 */

static void tft_set_addr_window(
    unsigned int x0,
    unsigned int y0,
    unsigned int x1,
    unsigned int y1
)
{
    /*
     * Column Address Set
     */

    tft_write_cmd(0x2A);

    tft_write_data((unsigned char)(x0 >> 8));
    tft_write_data((unsigned char)(x0 & 0xFF));

    tft_write_data((unsigned char)(x1 >> 8));
    tft_write_data((unsigned char)(x1 & 0xFF));


    /*
     * Row Address Set
     */

    tft_write_cmd(0x2B);

    tft_write_data((unsigned char)(y0 >> 8));
    tft_write_data((unsigned char)(y0 & 0xFF));

    tft_write_data((unsigned char)(y1 >> 8));
    tft_write_data((unsigned char)(y1 & 0xFF));


    /*
     * Memory Write
     *
     * Sau lệnh này ST7735 sẽ nhận liên tục
     * các byte pixel.
     */

    tft_write_cmd(0x2C);
}


/*
 * ============================================================
 * Kiểm tra một cell có phải Snake hay không
 * ============================================================
 */

static int cell_is_snake(
    const Game *game,
    int x,
    int y
)
{
    int i;

    for (i = 0; i < game->snake.length; i++)
    {
        if (game->snake.body[i].x == x &&
            game->snake.body[i].y == y)
        {
            return i;
        }
    }

    return -1;
}


/*
 * ============================================================
 * Vẽ toàn bộ board
 *
 * Mỗi cell = 4 x 4 pixel.
 *
 * Toàn bộ board được gửi trong MỘT vùng RAMWR.
 *
 * CS sẽ được giữ LOW bởi st7735.v trong suốt
 * quá trình truyền pixel.
 * ============================================================
 */

static void display_draw_board(
    const Game *game
)
{
    int cell_y;
    int cell_x;
    int pixel_y;
    int pixel_x;

    /*
     * Vùng board:
     *
     * X = BOARD_X -> BOARD_X + 119
     * Y = BOARD_Y -> BOARD_Y + 59
     */

    tft_set_addr_window(
        BOARD_X,
        BOARD_Y,
        BOARD_X + BOARD_PIXEL_WIDTH - 1,
        BOARD_Y + BOARD_PIXEL_HEIGHT - 1
    );


    /*
     * Duyệt từng cell.
     */

    for (cell_y = 0;
         cell_y < BOARD_HEIGHT;
         cell_y++)
    {
        for (cell_x = 0;
             cell_x < BOARD_WIDTH;
             cell_x++)
        {
            unsigned int color;
            int snake_index;

            snake_index =
                cell_is_snake(
                    game,
                    cell_x,
                    cell_y
                );


            /*
             * Food
             */

            if (game->food.x == cell_x &&
                game->food.y == cell_y)
            {
                color = COLOR_RED;
            }

            /*
             * Snake head
             */

            else if (snake_index == 0)
            {
                color = COLOR_HEAD;
            }

            /*
             * Snake body
             */

            else if (snake_index > 0)
            {
                color = COLOR_GREEN;
            }

            /*
             * Empty
             */

            else
            {
                color = COLOR_BLACK;
            }


            /*
             * Vẽ 4 x 4 pixel cho cell.
             */

            for (pixel_y = 0;
                 pixel_y < CELL_SIZE;
                 pixel_y++)
            {
                for (pixel_x = 0;
                     pixel_x < CELL_SIZE;
                     pixel_x++)
                {
                    tft_write_color(color);
                }
            }
        }
    }
}


/*
 * ============================================================
 * Vẽ viền board
 * ============================================================
 */

static void display_draw_border(void)
{
    int i;

    /*
     * Viền trên
     */

    tft_set_addr_window(
        BOARD_X,
        BOARD_Y,
        BOARD_X + BOARD_PIXEL_WIDTH - 1,
        BOARD_Y
    );

    for (i = 0; i < BOARD_PIXEL_WIDTH; i++)
    {
        tft_write_color(COLOR_WHITE);
    }


    /*
     * Viền dưới
     */

    tft_set_addr_window(
        BOARD_X,
        BOARD_Y + BOARD_PIXEL_HEIGHT - 1,
        BOARD_X + BOARD_PIXEL_WIDTH - 1,
        BOARD_Y + BOARD_PIXEL_HEIGHT - 1
    );

    for (i = 0; i < BOARD_PIXEL_WIDTH; i++)
    {
        tft_write_color(COLOR_WHITE);
    }
}


/*
 * ============================================================
 * Display Start
 * ============================================================
 */

void display_start_screen(void)
{
    /*
     * Màn hình khởi đầu sẽ được vẽ bởi display_draw()
     * khi Game đã được khởi tạo.
     */
}


/*
 * ============================================================
 * Display Game
 * ============================================================
 */

void display_draw(
    const Game *game
)
{
    display_draw_board(game);
    display_draw_border();
}


/*
 * ============================================================
 * Pause
 * ============================================================
 */

void display_pause_screen(
    const Game *game
)
{
    /*
     * Vẫn giữ nguyên board.
     *
     * Việc pause được xử lý trong main.c.
     */

    display_draw(game);
}


/*
 * ============================================================
 * Game Over
 * ============================================================
 */

void display_game_over(
    const Game *game
)
{
    /*
     * Giữ lại board để người chơi nhìn thấy
     * trạng thái cuối cùng.
     */

    display_draw(game);
}