#include "display.h"
#include "config.h"

/*
 * Các hàm này hiện tại chỉ là khung.
 *
 * Sau này chúng sẽ điều khiển màn hình ILI9341
 * thông qua SPI của SoC RISC-V.
 */

static void display_clear(void)
{
    /*
     * Sau này:
     * Gửi lệnh cho ILI9341 để xóa màn hình.
     */
}

static void display_draw_cell(
    int x,
    int y,
    char cell
)
{
    /*
     * Sau này:
     * Vẽ một ô trên màn hình ILI9341.
     *
     * x, y  : tọa độ ô
     * cell  : ' ', 'O', '@', 'o'
     */
    (void)x;
    (void)y;
    (void)cell;
}

void display_start_screen(void)
{
    display_clear();

    /*
     * Sau này hiển thị:
     *
     *        SNAKE GAME
     *
     *       EASY
     *       NORMAL
     *       HARD
     */
}

void display_draw(
    const Game *game
)
{
    display_clear();

    /*
     * Vẽ toàn bộ bàn chơi.
     */

    for (int y = 0; y < BOARD_HEIGHT; y++)
    {
        for (int x = 0; x < BOARD_WIDTH; x++)
        {
            char cell = ' ';

            /*
             * Food
             */
            if (game->food.x == x &&
                game->food.y == y)
            {
                cell = 'O';
            }

            /*
             * Snake
             */
            for (int i = 0;
                 i < game->snake.length;
                 i++)
            {
                if (game->snake.body[i].x == x &&
                    game->snake.body[i].y == y)
                {
                    if (i == 0)
                    {
                        cell = '@';
                    }
                    else
                    {
                        cell = 'o';
                    }

                    break;
                }
            }

            display_draw_cell(x, y, cell);
        }
    }
}

void display_pause_screen(
    const Game *game
)
{
    display_draw(game);

    /*
     * Sau này hiển thị "PAUSED"
     * trên ILI9341.
     */
}

void display_game_over(
    const Game *game
)
{
    display_draw(game);

    /*
     * Sau này hiển thị:
     *
     * GAME OVER
     * Score
     * High Score
     * R - Restart
     * D - Difficulty
     */
}