#include "game.h"
#include "food.h"
#include "config.h"

void game_init(Game *game)
{
    snake_init(&game->snake);

    game->score = 0;
    game->high_score = 0;

    game->difficulty = NORMAL;

    game->speed_ms = NORMAL_SPEED;

    game->state = GAME_START;

    food_spawn(
        &game->food,
        &game->snake
    );
}

void game_set_difficulty(
    Game *game,
    Difficulty difficulty
)
{
    game->difficulty = difficulty;

    switch (difficulty)
    {
        case EASY:
            game->speed_ms = EASY_SPEED;
            break;

        case NORMAL:
            game->speed_ms = NORMAL_SPEED;
            break;

        case HARD:
            game->speed_ms = HARD_SPEED;
            break;

        default:
            game->difficulty = NORMAL;
            game->speed_ms = NORMAL_SPEED;
            break;
    }
}

void game_update(Game *game)
{
    if (game->state != GAME_PLAYING)
        return;

    snake_move(&game->snake);

    /*
     * Check wall collision
     */
    if (game_check_wall_collision(&game->snake))
    {
        game->state = GAME_OVER;
        return;
    }

    /*
     * Check self collision
     */
    if (snake_hits_self(&game->snake))
    {
        game->state = GAME_OVER;
        return;
    }

    /*
     * Check food
     */
    if (food_is_eaten(
            game->food,
            game->snake.body[0]))
    {
        snake_grow(&game->snake);

        game->score += SCORE_PER_FOOD;

        /*
         * Update high score
         */
        if (game->score > game->high_score)
        {
            game->high_score = game->score;
        }

        /*
         * Spawn new food
         */
        food_spawn(
            &game->food,
            &game->snake
        );
    }
}

void game_restart(Game *game)
{
    int old_high_score = game->high_score;
    Difficulty old_difficulty = game->difficulty;

    snake_init(&game->snake);

    game->score = 0;

    /*
     * Keep high score
     */
    game->high_score = old_high_score;

    /*
     * Keep selected difficulty
     */
    game->difficulty = old_difficulty;

    game_set_difficulty(
        game,
        old_difficulty
    );

    game->state = GAME_PLAYING;

    food_spawn(
        &game->food,
        &game->snake
    );
}

void game_toggle_pause(Game *game)
{
    if (game->state == GAME_PLAYING)
    {
        game->state = GAME_PAUSED;
    }
    else if (game->state == GAME_PAUSED)
    {
        game->state = GAME_PLAYING;
    }
}

int game_check_wall_collision(
    const Snake *snake
)
{
    Point head = snake->body[0];

    if (head.x < 0 ||
        head.x >= BOARD_WIDTH ||
        head.y < 0 ||
        head.y >= BOARD_HEIGHT)
    {
        return 1;
    }

    return 0;
}