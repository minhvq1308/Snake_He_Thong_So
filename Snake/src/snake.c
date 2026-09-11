#include "snake.h"

void snake_init(Snake *snake)
{
    snake->length = INITIAL_SNAKE_LENGTH;

    snake->direction = RIGHT;

    int start_x = BOARD_WIDTH / 2;
    int start_y = BOARD_HEIGHT / 2;

    for (int i = 0; i < snake->length; i++)
    {
        snake->body[i].x = start_x - i;
        snake->body[i].y = start_y;
    }
}

void snake_move(Snake *snake)
{
    for (int i = snake->length - 1; i > 0; i--)
    {
        snake->body[i] = snake->body[i - 1];
    }

    switch (snake->direction)
    {
        case UP:
            snake->body[0].y--;
            break;

        case DOWN:
            snake->body[0].y++;
            break;

        case LEFT:
            snake->body[0].x--;
            break;

        case RIGHT:
            snake->body[0].x++;
            break;
    }
}

void snake_grow(Snake *snake)
{
    if (snake->length < MAX_SNAKE_LENGTH)
    {
        snake->body[snake->length] =
            snake->body[snake->length - 1];

        snake->length++;
    }
}

void snake_set_direction(
    Snake *snake,
    Direction direction
)
{
    if (snake->direction == UP && direction == DOWN)
        return;

    if (snake->direction == DOWN && direction == UP)
        return;

    if (snake->direction == LEFT && direction == RIGHT)
        return;

    if (snake->direction == RIGHT && direction == LEFT)
        return;

    snake->direction = direction;
}

int snake_hits_self(
    const Snake *snake
)
{
    Point head = snake->body[0];

    for (int i = 1; i < snake->length; i++)
    {
        if (head.x == snake->body[i].x &&
            head.y == snake->body[i].y)
        {
            return 1;
        }
    }

    return 0;
}