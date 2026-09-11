#ifndef GAME_H
#define GAME_H

#include "types.h"
#include "snake.h"

typedef enum
{
    EASY = 1,
    NORMAL = 2,
    HARD = 3
} Difficulty;

typedef struct
{
    Snake snake;

    Point food;

    int score;
    int high_score;

    int speed_ms;

    Difficulty difficulty;

    GameState state;

} Game;

void game_init(Game *game);

void game_update(Game *game);

void game_restart(Game *game);

void game_toggle_pause(Game *game);

void game_set_difficulty(
    Game *game,
    Difficulty difficulty
);

int game_check_wall_collision(
    const Snake *snake
);

#endif