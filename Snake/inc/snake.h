#ifndef SNAKE_H
#define SNAKE_H

#include <stdint.h>
#include "config.h"

typedef enum
{
    DIR_UP = 0,
    DIR_RIGHT,
    DIR_DOWN,
    DIR_LEFT
} Direction;

typedef struct
{
    int16_t x;
    int16_t y;
} Point;

typedef struct
{
    Point body[SNAKE_MAX_LENGTH];
    uint16_t length;

    Direction direction;
    Direction next_direction;
} Snake;

void snake_init(Snake *snake);

void snake_set_direction(Snake *snake, Direction direction);

void snake_move(Snake *snake);

void snake_grow(Snake *snake);

int snake_check_self_collision(const Snake *snake);

int snake_contains(const Snake *snake, int16_t x, int16_t y);

#endif
