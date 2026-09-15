#ifndef SNAKE_H
#define SNAKE_H

#include "types.h"
#include "config.h"

typedef struct
{
    Point body[MAX_SNAKE_LENGTH];
    int length;
    Direction direction;
} Snake;

void snake_init(Snake *snake);

void snake_move(Snake *snake);

void snake_grow(Snake *snake);

void snake_set_direction(
    Snake *snake,
    Direction direction
);

int snake_hits_self(
    const Snake *snake
);

#endif