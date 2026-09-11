#ifndef DISPLAY_H
#define DISPLAY_H

#include "game.h"

void display_start_screen(void);

void display_draw(
    const Game *game
);

void display_pause_screen(
    const Game *game
);

void display_game_over(
    const Game *game
);

#endif 