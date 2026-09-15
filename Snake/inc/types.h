#ifndef TYPES_H
#define TYPES_H

typedef struct
{
    int x;
    int y;
} Point;

typedef enum
{
    UP,
    DOWN,
    LEFT,
    RIGHT
} Direction;

typedef enum
{
    GAME_START,
    GAME_PLAYING,
    GAME_PAUSED,
    GAME_OVER
} GameState;

#endif