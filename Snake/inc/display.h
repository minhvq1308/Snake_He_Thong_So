#ifndef DISPLAY_H
#define DISPLAY_H

#include "game.h"

void display_init(void);

void display_clear(uint16_t color);

void display_draw_board(const Game *game);

void display_draw_score(const Game *game);

void display_draw_state(const Game *game);

void display_update(const Game *game);

#endif
