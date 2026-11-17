/* Vòng lặp chính và máy trạng thái: TITLE -> PLAY <-> PAUSE -> DYING -> OVER */
#include "app.h"
#include "game.h"
#include "ui.h"
#include "input.h"
#include "timebase.h"

void game_init(void)
{
    rng = 0x1234ABCDu;
    hi_score = 0;
    timebase_init();
    draw_title();
    state = ST_TITLE;
}

void game_poll(void)
{
    unsigned dt = timebase_poll();         /* ms trôi qua từ lần gọi trước */

    poll_input();

    switch (state) {

    case ST_TITLE:
        title_tick(dt);
        if (s1_flag) start_game();
        break;

    case ST_PLAY:
        if (s2_flag) { draw_pause(); state = ST_PAUSE; break; }

        bonus_update(dt);                  /* mồi thưởng: đếm ngược, thanh vàng, nhấp nháy */
        footer_tick(dt);                   /* dòng LEVEL UP */

        step_acc += (uint16_t)dt;
        if (step_acc >= STEP_MS[level]) {
            step_acc -= STEP_MS[level];
            if (step_acc >= STEP_MS[level]) step_acc = 0;
            game_step();
        }
        break;

    case ST_PAUSE:
        if (s2_flag || s1_flag) {
            redraw_field();
            resync_clock();
            state = ST_PLAY;
        }
        break;

    case ST_DYING:
        if (die_left <= dt) { draw_over(); state = ST_OVER; }
        else die_left -= (uint16_t)dt;
        break;

    case ST_OVER:
        if (s1_flag) start_game();
        else if (s2_flag) { draw_title(); state = ST_TITLE; }
        break;
    }

    s1_flag = 0;
    s2_flag = 0;
}
