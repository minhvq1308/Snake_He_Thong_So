#include "snake.h"

static int is_opposite(Direction a, Direction b)
{
    if (a == DIR_UP    && b == DIR_DOWN)  return 1;
    if (a == DIR_DOWN  && b == DIR_UP)    return 1;
    if (a == DIR_LEFT  && b == DIR_RIGHT) return 1;
    if (a == DIR_RIGHT && b == DIR_LEFT)  return 1;

    return 0;
}


void snake_init(Snake *snake)
{
    snake->length = 3;

    snake->body[0].x = BOARD_WIDTH / 2;
    snake->body[0].y = BOARD_HEIGHT / 2;

    snake->body[1].x = snake->body[0].x - 1;
    snake->body[1].y = snake->body[0].y;

    snake->body[2].x = snake->body[1].x - 1;
    snake->body[2].y = snake->body[1].y;

    snake->direction = DIR_RIGHT;
    snake->next_direction = DIR_RIGHT;
}


void snake_set_direction(Snake *snake, Direction direction)
{
    if (!is_opposite(snake->direction, direction))
    {
        snake->next_direction = direction;
    }
}


void snake_move(Snake *snake)
{
    uint16_t i;

    snake->direction = snake->next_direction;

    for (i = snake->length - 1; i > 0; i--)
    {
        snake->body[i] = snake->body[i - 1];
    }

    switch (snake->direction)
    {
        case DIR_UP:
            snake->body[0].y--;
            break;

        case DIR_RIGHT:
            snake->body[0].x++;
            break;

        case DIR_DOWN:
            snake->body[0].y++;
            break;

        case DIR_LEFT:
            snake->body[0].x--;
            break;

        default:
            break;
    }
}


void snake_grow(Snake *snake)
{
    if (snake->length < SNAKE_MAX_LENGTH)
    {
        snake->body[snake->length] =
            snake->body[snake->length - 1];

        snake->length++;
    }
}


int snake_check_self_collision(const Snake *snake)
{
    uint16_t i;

    for (i = 1; i < snake->length; i++)
    {
        if (snake->body[0].x == snake->body[i].x &&
            snake->body[0].y == snake->body[i].y)
        {
            return 1;
        }
    }

    return 0;
}


int snake_contains(const Snake *snake, int16_t x, int16_t y)
{
    uint16_t i;

    for (i = 0; i < snake->length; i++)
    {
        if (snake->body[i].x == x &&
            snake->body[i].y == y)
        {
            return 1;
        }
    }

    return 0;
}
