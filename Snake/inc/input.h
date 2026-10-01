#ifndef INPUT_H
#define INPUT_H

#include "snake.h"
#include "game.h"

int input_get_uart_direction(Direction *direction);

int input_get_button_direction(Direction *direction);

int input_get_pause(void);

int input_get_restart(void);

int input_get_difficulty(Difficulty *difficulty);

#endif
