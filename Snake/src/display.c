#include "display.h"
#include "config.h"

#include <stdio.h>

static void clear_screen(void)
{
    system("clear");
}

static void display_border(void)
{
    for (int i = 0; i < BOARD_WIDTH + 2; i++)
    {
        printf("#");
    }

    printf("\n");
}

void display_start_screen(void)
{
    clear_screen();

    printf("\n");
    printf("================================\n");
    printf("           SNAKE GAME            \n");
    printf("================================\n\n");

    printf("SELECT DIFFICULTY\n\n");

    printf("[1] EASY\n");
    printf("[2] NORMAL\n");
    printf("[3] HARD\n\n");

    printf("Press 1, 2 or 3\n");
}

void display_draw(
    const Game *game
)
{
    clear_screen();

    const char *difficulty_name;

    switch (game->difficulty)
    {
        case EASY:
            difficulty_name = "EASY";
            break;

        case NORMAL:
            difficulty_name = "NORMAL";
            break;

        case HARD:
            difficulty_name = "HARD";
            break;

        default:
            difficulty_name = "NORMAL";
            break;
    }

    printf("================================\n");
    printf("           SNAKE GAME            \n");
    printf("================================\n");

    printf(
        "Score: %d    High Score: %d\n",
        game->score,
        game->high_score
    );

    printf(
        "Difficulty: %s\n",
        difficulty_name
    );

    printf(
        "Speed: %d ms\n\n",
        game->speed_ms
    );

    display_border();

    for (int y = 0; y < BOARD_HEIGHT; y++)
    {
        printf("#");

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

            printf("%c", cell);
        }

        printf("#\n");
    }

    display_border();

    printf("\n");
    printf("WASD: Move | P: Pause | Q: Quit\n");
}

void display_pause_screen(
    const Game *game
)
{
    display_draw(game);

    printf("\n");
    printf("========== PAUSED ==========\n");
    printf("Press P to continue.\n");
}

void display_game_over(
    const Game *game
)
{
    display_draw(game);

    printf("\n");
    printf("========= GAME OVER =========\n");

    printf(
        "Final Score: %d\n",
        game->score
    );

    printf(
        "High Score:  %d\n",
        game->high_score
    );

    printf("\n");
    printf("[R] Restart\n");
    printf("[D] Change Difficulty\n");
    printf("[Q] Quit\n");
}