#include "food.h"
#include "config.h"

#include <stdlib.h>

void food_spawn(
    Point *food,
    const Snake *snake
)
{
    int valid;

    do
    {
        valid = 1;

        food->x = rand() % BOARD_WIDTH;
        food->y = rand() % BOARD_HEIGHT;

        for (int i = 0; i < snake->length; i++)
        {
            if (food->x == snake->body[i].x &&
                food->y == snake->body[i].y)
            {
                valid = 0;
                break;
            }
        }

    } while (!valid);
}

int food_is_eaten(
    Point food,
    Point head
)
{
    return (
        food.x == head.x &&
        food.y == head.y
    );
}