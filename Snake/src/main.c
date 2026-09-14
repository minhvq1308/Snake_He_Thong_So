#include "game.h"
#include "input.h"
#include "display.h"

int main(void)
{
    Game game;

    input_init();

    /* Khởi tạo game */
    game_init(&game);

    /* Chọn độ khó mặc định */
    game_set_difficulty(&game, NORMAL);

    /* Bắt đầu chơi */
    game.state = GAME_PLAYING;

    display_draw(&game);

    while (1)
    {
        char input = input_get();

        /* Pause */
        if (input == 'p' || input == 'P')
        {
            game_toggle_pause(&game);
        }

        /* Đang chơi */
        if (game.state == GAME_PLAYING)
        {
            if (input != '\0')
            {
                Direction direction =
                    input_to_direction(input);

                snake_set_direction(
                    &game.snake,
                    direction
                );
            }

            game_update(&game);

            display_draw(&game);
        }

        /* Đang pause */
        else if (game.state == GAME_PAUSED)
        {
            /* Chờ input để tiếp tục */
        }

        /* Game Over */
        else if (game.state == GAME_OVER)
        {
            display_game_over(&game);

            input = input_get();

            /* R = chơi lại */
            if (input == 'r' || input == 'R')
            {
                game_restart(&game);
                display_draw(&game);
            }
        }
    }

    input_shutdown();

    return 0;
}