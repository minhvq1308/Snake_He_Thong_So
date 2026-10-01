#include "food.h"

static uint32_t random_seed = 0x12345678u;


static uint32_t random_next(void)
{
    random_seed =
        random_seed * 1664525u +
        1013904223u;

    return random_seed;
}


void food_init(void)
{
    random_seed = 0x12345678u;
}


void food_spawn(Point *food, const Snake *snake)
{
    uint32_t value;
    int16_t x;
    int16_t y;

    do
    {
        value = random_next();

        x = value % BOARD_WIDTH;
        y = (value >> 8) % BOARD_HEIGHT;

    } while (snake_contains(snake, x, y));

    food->x = x;
    food->y = y;
}


int food_is_eaten(const Point *food, const Snake *snake)
{
    return (food->x == snake->body[0].x &&
            food->y == snake->body[0].y);
}
