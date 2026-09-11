#define _DEFAULT_SOURCE

#include "input.h"

#include <stdio.h>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>

static struct termios old_terminal;

void input_init(void)
{
    struct termios new_terminal;

    tcgetattr(STDIN_FILENO, &old_terminal);

    new_terminal = old_terminal;

    new_terminal.c_lflag &=
        ~(ICANON | ECHO);

    tcsetattr(
        STDIN_FILENO,
        TCSANOW,
        &new_terminal
    );

    int flags = fcntl(
        STDIN_FILENO,
        F_GETFL,
        0
    );

    fcntl(
        STDIN_FILENO,
        F_SETFL,
        flags | O_NONBLOCK
    );
}

void input_shutdown(void)
{
    tcsetattr(
        STDIN_FILENO,
        TCSANOW,
        &old_terminal
    );
}

char input_get(void)
{
    char c;

    if (read(
            STDIN_FILENO,
            &c,
            1) == 1)
    {
        return c;
    }

    return '\0';
}

Direction input_to_direction(
    char input
)
{
    switch (input)
    {
        case 'w':
        case 'W':
            return UP;

        case 's':
        case 'S':
            return DOWN;

        case 'a':
        case 'A':
            return LEFT;

        case 'd':
        case 'D':
            return RIGHT;

        default:
            return RIGHT;
    }
}