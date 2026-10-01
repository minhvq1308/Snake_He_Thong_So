#ifndef FOOD_H
#define FOOD_H

#include <stdint.h>
#include "snake.h"

void food_init(void);

void food_spawn(Point *food, const Snake *snake);

int food_is_eaten(const Point *food, const Snake *snake);

#endif
