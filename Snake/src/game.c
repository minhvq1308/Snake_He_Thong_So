#include "game.h"


static uint32_t difficulty_speed(Difficulty difficulty)
{
    switch (difficulty)
    {
        case DIFFICULTY_EASY:
            return SPEED_EASY;

        case DIFFICULTY_NORMAL:
            return SPEED_NORMAL;

        case DIFFICULTY_HARD:
            return SPEED_HARD;

        default:
            return SPEED_NORMAL;
    }
}


static int wall_collision(const Snake *snake)
{
    int16_t x = snake->body[0].x;
    int16_t y = snake->body[0].y;

    if (x < 0) return 1;
    if (x >= BOARD_WIDTH) return 1;

    if (y < 0) return 1;
    if (y >= BOARD_HEIGHT) return 1;

    return 0;
}


void game_init(Game *game)
{
    game->high_score = 0;

    game->difficulty = DIFFICULTY_NORMAL;

    game->score = 0;

    game->state = GAME_START;

    game->speed_ticks =
        difficulty_speed(game->difficulty);

    game->tick_count = 0;

    snake_init(&game->snake);

    food_init();

    food_spawn(&game->food, &game->snake);
}


void game_start(Game *game)
{
    game->score = 0;

    game->tick_count = 0;

    game->state = GAME_PLAYING;

    snake_init(&game->snake);

    food_spawn(&game->food, &game->snake);
}


void game_restart(Game *game)
{
    game_start(game);
}


void game_pause(Game *game)
{
    if (game->state == GAME_PLAYING)
    {
        game->state = GAME_PAUSED;
    }
}


void game_resume(Game *game)
{
    if (game->state == GAME_PAUSED)
    {
        game->state = GAME_PLAYING;
    }
}


void game_set_difficulty(Game *game,
                         Difficulty difficulty)
{
    game->difficulty = difficulty;

    game->speed_ticks =
        difficulty_speed(difficulty);
}


void game_set_direction(Game *game,
                        Direction direction)
{
    if (game->state == GAME_PLAYING)
    {
        snake_set_direction(&game->snake,
                            direction);
    }
}


void game_update(Game *game)
{
    if (game->state != GAME_PLAYING)
    {
        return;
    }

    game->tick_count++;

    if (game->tick_count < game->speed_ticks)
    {
        return;
    }

    game->tick_count = 0;

    snake_move(&game->snake);

    if (wall_collision(&game->snake))
    {
        game->state = GAME_OVER;
        return;
    }

    if (snake_check_self_collision(&game->snake))
    {
        game->state = GAME_OVER;
        return;
    }

    if (food_is_eaten(&game->food,
                      &game->snake))
    {
        snake_grow(&game->snake);

        game->score++;

        if (game->score > game->high_score)
        {
            game->high_score = game->score;
        }

        if (game->snake.length >=
            BOARD_WIDTH * BOARD_HEIGHT)
        {
            game->state = GAME_WIN;
            return;
        }

        food_spawn(&game->food,
                   &game->snake);
    }
}


int game_is_over(const Game *game)
{
    return (game->state == GAME_OVER ||
            game->state == GAME_WIN);
}
