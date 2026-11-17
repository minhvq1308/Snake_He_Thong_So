/* Logic trò chơi Snake: dữ liệu rắn, va chạm, ăn mồi, level, mồi thưởng, bắt đầu/kết thúc ván. */
#include "game.h"
#include "ui.h"
#include "hw.h"
#include "config.h"
#include "timebase.h"

const int8_t DX[4] = { 1, 0, -1, 0 };      /* 0=Phải 1=Xuống 2=Trái 3=Lên */
const int8_t DY[4] = { 0, 1, 0, -1 };
/* thời gian giữa 2 bước (ms) theo level 1..10 */
const uint16_t STEP_MS[MAX_LEVEL + 1] = { 0, 290, 255, 225, 198, 174, 152, 132, 114, 98, 84 };


/* ---- biến trạng thái ---- */
uint8_t  state;
uint8_t  body[256];          /* vòng đệm toạ độ ô: (y<<4)|x */
uint8_t  cellf[256];         /* cờ từng ô: rắn / táo / mồi thưởng */
uint8_t  head_i, tail_i;
uint8_t  dir;                /* hướng của bước vừa đi */
uint8_t  q[2], qn;           /* hàng đợi đổi hướng */
uint8_t  grow;               /* số ô còn phải dài thêm */
uint8_t  dead;

unsigned score, hi_score;
uint8_t  new_best;
uint8_t  level, lvl_cnt, streak;

uint8_t  food_x, food_y;
uint8_t  bonus_on, bonus_x, bonus_y, bonus_alt;
uint16_t bonus_left;
uint16_t die_left;
uint16_t step_acc;

uint32_t rng;

uint32_t rnd(void)
{
    rng ^= rng << 13;
    rng ^= rng >> 17;
    rng ^= rng << 5;
    return rng;
}

unsigned rnd_below(unsigned n)           /* n <= 16, không dùng chia */
{
    unsigned v;
    do { v = (unsigned)(rnd() >> 7) & 15u; } while (v >= n);
    return v;
}

int cell_free(int x, int y)
{
    return cellf[(y << 4) | x] == 0;
}

int spawn_food(void)
{
    int t, x, y;
    for (t = 0; t < 200; t++) {
        x = (int)rnd_below(GW);
        y = (int)rnd_below(GH);
        if (cell_free(x, y)) goto found;
    }
    for (y = 0; y < GH; y++)
        for (x = 0; x < GW; x++)
            if (cell_free(x, y)) goto found;
    return 0;
found:
    food_x = (uint8_t)x; food_y = (uint8_t)y;
    cellf[(y << 4) | x] |= F_FOOD;
    draw_food();
    return 1;
}

void bonus_cells(int on)
{
    int b = (bonus_y << 4) | bonus_x;
    if (on) { cellf[b] |= F_BONUS; cellf[b + 1] |= F_BONUS; cellf[b + 16] |= F_BONUS; cellf[b + 17] |= F_BONUS; }
    else    { cellf[b] &= ~F_BONUS; cellf[b + 1] &= ~F_BONUS; cellf[b + 16] &= ~F_BONUS; cellf[b + 17] &= ~F_BONUS; }
}

void bonus_off(void)
{
    if (!bonus_on) return;
    bonus_cells(0);
    bonus_on = 0;
    draw_bg_cell(bonus_x,     bonus_y);
    draw_bg_cell(bonus_x + 1, bonus_y);
    draw_bg_cell(bonus_x,     bonus_y + 1);
    draw_bg_cell(bonus_x + 1, bonus_y + 1);
    if (footer_mode == 2) footer_hint();
}

void spawn_bonus(void)
{
    int t, x, y;
    bonus_off();
    for (t = 0; t < 120; t++) {
        x = (int)rnd_below(GW - 1);
        y = (int)rnd_below(GH - 1);
        if (cell_free(x, y) && cell_free(x + 1, y) && cell_free(x, y + 1) && cell_free(x + 1, y + 1))
            goto found;
    }
    return;                                                  /* không còn chỗ trống: bỏ qua */
found:
    bonus_x = (uint8_t)x; bonus_y = (uint8_t)y;
    bonus_on = 1; bonus_left = BONUS_MS; bonus_alt = 0;
    bonus_cells(1);
    draw_gem();
    footer_bonus();
}

void bonus_update(unsigned dt)
{
    uint8_t alt;

    if (!bonus_on) return;
    if (bonus_left <= dt) { bonus_off(); return; }

    bonus_left -= (uint16_t)dt;
    bonus_bar_tick(dt);                                  /* thanh vàng co 1 px mỗi 25 ms */
    alt = (bonus_left < 1000) ? (uint8_t)((bonus_left >> 7) & 1) : 0;
    if (alt != bonus_alt) { bonus_alt = alt; draw_gem(); }   /* nhấp nháy trong giây cuối */
}

void start_game(void)
{
    int i;
    uint32_t c = RD(HUB_CYCLES);

    rng = c ^ 0x9E3779B9u;
    if (!rng) rng = 1;

    for (i = 0; i < 256; i++) { cellf[i] = 0; body[i] = 0; }

    tail_i = 0; head_i = 2;
    body[0] = (uint8_t)((7 << 4) | 5);
    body[1] = (uint8_t)((7 << 4) | 6);
    body[2] = (uint8_t)((7 << 4) | 7);
    cellf[body[0]] = F_SNAKE; cellf[body[1]] = F_SNAKE; cellf[body[2]] = F_SNAKE;
    dir = 0; qn = 0; grow = 0; dead = 0;

    score = 0; level = 1; lvl_cnt = 0; streak = 0; new_best = 0;
    bonus_on = 0; bonus_alt = 0; step_acc = 0; footer_mode = 0; msg_left = 0;

    draw_frame();
    hud_all();
    footer_hint();
    redraw_field();            /* vẽ nền + rắn */
    spawn_food();
    resync_clock();
    state = ST_PLAY;
}

void begin_death(void)
{
    dead = 1;
    if (score > hi_score) { hi_score = score; new_best = 1; }
    bonus_off();                                             /* tắt mồi thưởng + thanh đếm giờ */
    footer_clear();
    footer_mode = 0;
    draw_snake_all();                                        /* nhuộm rắn sang màu "chết" */
    die_left = 700;
    state = ST_DYING;
}

void add_score(unsigned p)
{
    score += p;
    if (score > 9999u) score = 9999u;
    hud_score();
}

void eat_food(void)
{
    add_score(PTS_FOOD);
    streak++;
    lvl_cnt++;
    if (lvl_cnt >= FOODS_PER_LEVEL && level < MAX_LEVEL) {
        lvl_cnt = 0;
        level++;
        hud_level();
        if (!bonus_on) footer_levelup();
    }
    if (!spawn_food()) { begin_death(); return; }            /* kín sân = thắng */
    if (streak >= BONUS_EVERY) { streak = 0; spawn_bonus(); }
    hud_pips();
}

void eat_bonus(void)
{
    add_score(PTS_BONUS);
}

void game_step(void)
{
    uint8_t hc, nc, tc, fl, old_head;
    int nx, ny, ate_food, ate_bonus, tail_moves;

    if (qn) { dir = q[0]; q[0] = q[1]; qn--; }

    hc = body[head_i];
    nx = (hc & 15) + DX[dir];
    ny = (hc >> 4) + DY[dir];
    if (nx < 0 || nx >= GW || ny < 0 || ny >= GH) { begin_death(); return; }

    nc = (uint8_t)((ny << 4) | nx);
    fl = cellf[nc];
    ate_food  = (fl & F_FOOD)  != 0;
    ate_bonus = (fl & F_BONUS) != 0;
    if (ate_food)       grow += 1;
    else if (ate_bonus) grow += 2;

    tc = body[tail_i];
    tail_moves = (grow == 0);
    if ((fl & F_SNAKE) && !(tail_moves && nc == tc)) { begin_death(); return; }

    old_head = head_i;
    if (tail_moves) { cellf[tc] &= (uint8_t)~F_SNAKE; tail_i++; }
    else            { grow--; }
    head_i++;
    body[head_i] = nc;
    cellf[nc] = (uint8_t)((cellf[nc] & ~F_FOOD) | F_SNAKE);
    if (ate_bonus) bonus_off();

    if (tail_moves) { draw_bg_cell(tc & 15, tc >> 4); draw_gseg(tail_i); }
    draw_gseg(old_head);
    draw_gseg(head_i);

    if (ate_food)  eat_food();
    if (ate_bonus) eat_bonus();
}

void push_dir(int d)
{
    int last = qn ? q[qn - 1] : dir;
    if (d == last || d == (last ^ 2)) return;                /* trùng / quay đầu 180° */
    if (qn < 2) q[qn++] = (uint8_t)d;
}
