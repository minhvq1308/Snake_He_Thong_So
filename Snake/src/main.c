#define _DEFAULT_SOURCE

#include "game.h"
#include "input.h"
#include "display.h"

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

int main(void)
{
    srand((unsigned int)time(NULL));

    Game game;

    input_init();

    /*
     * Chọn độ khó lần đầu
     */
    display_start_screen();

    while (1)
    {
        char input = input_get();

        if (input == '1')
        {
            game_init(&game);
            game_set_difficulty(&game, EASY);
            break;
        }

        if (input == '2')
        {
            game_init(&game);
            game_set_difficulty(&game, NORMAL);
            break;
        }

        if (input == '3')
        {
            game_init(&game);
            game_set_difficulty(&game, HARD);
            break;
        }

        if (input == 'q' || input == 'Q')
        {
            input_shutdown();
            return 0;
        }

        usleep(10000);
    }

    game.state = GAME_PLAYING;
    display_draw(&game);

    while (1)
    {
        char input = input_get();

        /*
         * Quit
         */
        if (input == 'q' || input == 'Q')
        {
            break;
        }

        /*
         * Pause
         */
        if (input == 'p' || input == 'P')
        {
            game_toggle_pause(&game);

            if (game.state == GAME_PAUSED)
            {
                display_pause_screen(&game);
            }
            else
            {
                display_draw(&game);
            }
        }

        /*
         * Playing
         */
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

            usleep(game.speed_ms * 1000);
        }

        /*
         * Paused
         */
        else if (game.state == GAME_PAUSED)
        {
            usleep(50000);
        }

        /*
         * Game Over
         */
        else if (game.state == GAME_OVER)
        {
            display_game_over(&game);

            while (1)
            {
                char game_input = input_get();

                /*
                 * Quit
                 */
                if (game_input == 'q' ||
                    game_input == 'Q')
                {
                    input_shutdown();
                    return 0;
                }

                /*
                 * Restart - giữ độ khó
                 */
                if (game_input == 'r' ||
                    game_input == 'R')
                {
                    game_restart(&game);

                    display_draw(&game);

                    break;
                }

                /*
                 * Change Difficulty
                 */
                if (game_input == 'd' ||
                    game_input == 'D')
                {
                    display_start_screen();

                    while (1)
                    {
                        char difficulty_input =
                            input_get();

                        if (difficulty_input == '1')
                        {
                            game_init(&game);
                            game_set_difficulty(
                                &game,
                                EASY
                            );
                            break;
                        }

                        if (difficulty_input == '2')
                        {
                            game_init(&game);
                            game_set_difficulty(
                                &game,
                                NORMAL
                            );
                            break;
                        }

                        if (difficulty_input == '3')
                        {
                            game_init(&game);
                            game_set_difficulty(
                                &game,
                                HARD
                            );
                            break;
                        }

                        if (difficulty_input == 'q' ||
                            difficulty_input == 'Q')
                        {
                            input_shutdown();
                            return 0;
                        }

                        usleep(10000);
                    }

                    game.state = GAME_PLAYING;

                    display_draw(&game);

                    break;
                }

                usleep(10000);
            }
        }
    }

    input_shutdown();

    printf("\nGame exited.\n");

    return 0;
}