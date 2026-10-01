#ifndef GAME_H
#define GAME_H

#include <stdint.h>
#include "snake.h"
#include "food.h"

typedef enum
{
    GAME_START = 0,
    GAME_PLAYING,
    GAME_PAUSED,
    GAME_OVER,
    GAME_WIN
} GameState;


typedef enum
{
    DIFFICULTY_EASY = 0,
    DIFFICULTY_NORMAL,
    DIFFICULTY_HARD
} Difficulty;


typedef struct
{
    Snake snake;
    Point food;

    GameState state;
    Difficulty difficulty;

    uint32_t score;
    uint32_t high_score;

    uint32_t speed_ticks;
    uint32_t tick_count;

} Game;


void game_init(Game *game);

void game_start(Game *game);

void game_restart(Game *game);

void game_pause(Game *game);

void game_resume(Game *game);

void game_set_difficulty(Game *game, Difficulty difficulty);

void game_set_direction(Game *game, Direction direction);

void game_update(Game *game);

int game_is_over(const Game *game);

#endif
