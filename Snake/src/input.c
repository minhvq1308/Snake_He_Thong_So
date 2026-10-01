#include "input.h"
#include "config.h"


static Direction uart_to_direction(uint8_t c)
{
    switch (c)
    {
        case 'W':
        case 'w':
            return DIR_UP;

        case 'D':
        case 'd':
            return DIR_RIGHT;

        case 'S':
        case 's':
            return DIR_DOWN;

        case 'A':
        case 'a':
            return DIR_LEFT;

        default:
            return DIR_RIGHT;
    }
}


int input_get_uart_direction(Direction *direction)
{
    uint32_t status;
    uint8_t data;

    status = UART_STATUS;

    if ((status & 1u) == 0)
    {
        return 0;
    }

    data = (uint8_t)UART_RX;

    if (data == 'W' || data == 'w' ||
        data == 'A' || data == 'a' ||
        data == 'S' || data == 's' ||
        data == 'D' || data == 'd')
    {
        *direction = uart_to_direction(data);
        return 1;
    }

    return 0;
}


int input_get_button_direction(Direction *direction)
{
    uint32_t buttons;

    buttons = GPIO_REG;

    /*
     * Buttons are active-low because
     * external buttons use pull-up.
     */

    if ((buttons & BUTTON_UP) == 0)
    {
        *direction = DIR_UP;
        return 1;
    }

    if ((buttons & BUTTON_RIGHT) == 0)
    {
        *direction = DIR_RIGHT;
        return 1;
    }

    if ((buttons & BUTTON_DOWN) == 0)
    {
        *direction = DIR_DOWN;
        return 1;
    }

    if ((buttons & BUTTON_LEFT) == 0)
    {
        *direction = DIR_LEFT;
        return 1;
    }

    return 0;
}


int input_get_pause(void)
{
    uint32_t data;

    if ((UART_STATUS & 1u) == 0)
    {
        return 0;
    }

    data = UART_RX;

    return (data == 'P' || data == 'p');
}


int input_get_restart(void)
{
    uint32_t data;

    if ((UART_STATUS & 1u) == 0)
    {
        return 0;
    }

    data = UART_RX;

    return (data == 'R' || data == 'r');
}


int input_get_difficulty(Difficulty *difficulty)
{
    uint32_t data;

    if ((UART_STATUS & 1u) == 0)
    {
        return 0;
    }

    data = UART_RX;

    if (data == '1')
    {
        *difficulty = DIFFICULTY_EASY;
        return 1;
    }

    if (data == '2')
    {
        *difficulty = DIFFICULTY_NORMAL;
        return 1;
    }

    if (data == '3')
    {
        *difficulty = DIFFICULTY_HARD;
        return 1;
    }

    return 0;
}
