#ifndef FOOD_H
#define FOOD_H

#include "types.h"
#include "snake.h"

void food_spawn(
    Point *food,
    const Snake *snake
);

int food_is_eaten(
    Point food,
    Point head
);

#endif