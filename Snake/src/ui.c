/* Giao diện: vẽ rắn, táo, mồi thưởng, HUD, chân trang và các màn hình (tiêu đề / tạm dừng / Game Over).
 *
 *  Bố cục màn hình 128x160 (dọc)
 *     y   0..20  : HUD (điểm, level, chuỗi 5 táo, đồng hồ tốc độ)
 *     y  21      : đường kẻ
 *     y  22..145 : khung + sân chơi 15x15 ô (mỗi ô 8px) bắt đầu (4,24)
 *     y 146..159 : footer (gợi ý / LEVEL UP / thanh thời gian mồi thưởng)
 *
 *  Module này chỉ VẼ: không thay đổi trạng thái trò chơi (state do game.c / app.c quản lý).
 */
#include "ui.h"
#include "game.h"
#include "hw.h"
#include "font.h"
#include "config.h"
#include "colors.h"

static const uint16_t BODY_COL[2][2] = {
    { RGB( 40,200, 90), RGB( 28,150, 72) },     /* sống: dải A, dải B */
    { RGB(150, 60, 60), RGB(110, 42, 42) }      /* chết  */
};
static const uint16_t BODY_HI[2][2] = {
    { RGB(150,250,170), RGB(110,225,140) },
    { RGB(210,120,120), RGB(170, 90, 90) }
};

static const uint16_t LV_COL[10] = {
    RGB( 60,220, 90), RGB(100,225, 80), RGB(140,225, 70), RGB(180,225, 60), RGB(215,215, 50),
    RGB(240,190, 45), RGB(245,150, 45), RGB(245,110, 45), RGB(240, 80, 50), RGB(235, 55, 60)
};


/* ---- trạng thái riêng của giao diện ---- */
uint8_t  footer_mode;        /* 0 gợi ý, 1 LEVEL UP, 2 thanh mồi thưởng */
uint16_t msg_left;
static uint8_t  bar_px;
static uint16_t bar_acc;
static uint8_t  blink;
static uint16_t blink_acc;

uint16_t cell_bg(int cx, int cy)
{
    return ((cx ^ cy) & 1) ? C_CELL_B : C_CELL_A;
}

void draw_bg_cell(int cx, int cy)
{
    rect(FX + (cx << 3), FY + (cy << 3), 8, 8, cell_bg(cx, cy));
}

void draw_seg(int x, int y, uint16_t bg, int kind, int mask, int d, unsigned idx)
{
    rect(x, y, 8, 8, bg);

    if (kind == 1) {                                         /* đầu */
        static const uint8_t EYE[4][4] = {                   /* ax,ay,bx,by */
            { 4, 1, 4, 5 }, { 1, 4, 5, 4 }, { 2, 1, 2, 5 }, { 1, 2, 5, 2 }
        };
        static const uint8_t PUP[4][4] = {
            { 5, 2, 5, 5 }, { 2, 5, 5, 5 }, { 2, 2, 2, 5 }, { 2, 2, 5, 2 }
        };
        uint16_t hc = dead ? C_HEAD_DEAD : C_HEAD;
        rect(x,     y + 1, 8, 6, hc);
        rect(x + 1, y,     6, 8, hc);
        rect(x + EYE[d][0], y + EYE[d][1], 2, 2, C_WHITE);
        rect(x + EYE[d][2], y + EYE[d][3], 2, 2, C_WHITE);
        rect(x + PUP[d][0], y + PUP[d][1], 1, 1, C_BLACK);
        rect(x + PUP[d][2], y + PUP[d][3], 1, 1, C_BLACK);
        return;
    }

    {
        int      band = (idx >> 1) & 1;                      /* dải sọc 2 đốt */
        uint16_t c0   = BODY_COL[dead][band];
        uint16_t hl   = BODY_HI[dead][band];

        if (kind == 2) {                                     /* đuôi */
            rect(x + 2, y + 2, 4, 4, c0);
            if (mask & M_R) rect(x + 6, y + 2, 2, 4, c0);
            if (mask & M_L) rect(x,     y + 2, 2, 4, c0);
            if (mask & M_D) rect(x + 2, y + 6, 4, 2, c0);
            if (mask & M_U) rect(x + 2, y,     4, 2, c0);
            return;
        }

        rect(x + 1, y + 2, 6, 4, c0);                        /* thân bo góc */
        rect(x + 2, y + 1, 4, 6, c0);
        rect(x + 2, y + 2, 2, 1, hl);                        /* vệt sáng */
        if (mask & M_R) rect(x + 6, y + 1, 2, 6, c0);        /* cầu nối: ống thẳng 6px */
        if (mask & M_L) rect(x,     y + 1, 2, 6, c0);
        if (mask & M_D) rect(x + 1, y + 6, 6, 2, c0);
        if (mask & M_U) rect(x + 1, y,     6, 2, c0);
    }
}

int nbr_bit(uint8_t a, uint8_t b)
{
    int ax = a & 15, ay = a >> 4, bx = b & 15, by = b >> 4;
    if (bx > ax) return M_R;
    if (bx < ax) return M_L;
    if (by > ay) return M_D;
    return M_U;
}

int seg_mask(uint8_t i)
{
    int m = 0;
    if (i != tail_i) m |= nbr_bit(body[i], body[(uint8_t)(i - 1)]);
    if (i != head_i) m |= nbr_bit(body[i], body[(uint8_t)(i + 1)]);
    return m;
}

void draw_gseg(uint8_t i)
{
    uint8_t c  = body[i];
    int     cx = c & 15, cy = c >> 4;
    int     kind = (i == head_i) ? 1 : ((i == tail_i) ? 2 : 0);
    draw_seg(FX + (cx << 3), FY + (cy << 3), cell_bg(cx, cy), kind, seg_mask(i), dir, i);
}

void draw_snake_all(void)
{
    uint8_t i = tail_i;
    for (;;) {
        draw_gseg(i);
        if (i == head_i) break;
        i++;
    }
}

void draw_apple_px(int x, int y)
{
    rect(x + 1, y + 3, 6, 4, C_APPLE);
    rect(x + 2, y + 2, 4, 6, C_APPLE);
    rect(x + 5, y + 5, 2, 2, C_APPLE_SH);
    rect(x + 2, y + 3, 2, 1, C_APPLE_HI);
    rect(x + 4, y,     1, 2, C_STEM);
    rect(x + 5, y,     2, 1, C_LEAF);
}

void draw_food(void)
{
    int x = FX + (food_x << 3), y = FY + (food_y << 3);
    rect(x, y, 8, 8, cell_bg(food_x, food_y));
    draw_apple_px(x, y);
}

void draw_gem(void)
{
    int x = FX + (bonus_x << 3), y = FY + (bonus_y << 3);
    uint16_t ring = bonus_alt ? C_GEM_RING2 : C_GEM_RING;
    uint16_t gold = bonus_alt ? C_GEM_GOLD2 : C_GEM_GOLD;
    rect(x + 3, y,     10, 16, ring);
    rect(x,     y + 3, 16, 10, ring);
    rect(x + 1, y + 1, 14, 14, ring);
    rect(x + 4, y + 2,  8, 12, gold);
    rect(x + 2, y + 4, 12,  8, gold);
    rect(x + 3, y + 3, 10, 10, gold);
    rect(x + 4, y + 4,  4,  2, C_GEM_HI);
    rect(x + 4, y + 4,  2,  4, C_GEM_HI);
    rect(x + 9, y + 9,  2,  2, C_WHITE);
}

void hud_score(void)
{
    rect(48, 2, 32, 10, C_HUD);
    draw_num(48, 2, score, 4, 1, C_SCORE);
}

void hud_level(void)
{
    int i, x = 50;
    rect(108, 2, 16, 10, C_HUD);
    draw_num(108, 2, level, 2, 1, C_WHITE);
    for (i = 0; i < MAX_LEVEL; i++) {                        /* đồng hồ tốc độ */
        rect(x, 14, 6, 5, (i < level) ? LV_COL[i] : C_TRACK);
        x += 7;
    }
}

void hud_pips(void)
{
    int i, x = 4;
    for (i = 0; i < BONUS_EVERY; i++) {                      /* chuỗi táo -> mồi thưởng */
        rect(x, 13, 6, 6, (i < streak) ? C_GEM_GOLD : C_TRACK);
        if (i < streak) rect(x + 1, 14, 2, 1, C_GEM_HI);
        x += 8;
    }
}

void hud_static(void)
{
    rect(0, 0, SCR_W, 21, C_HUD);
    rect(0, 21, SCR_W, 1, C_HUDLINE);
    draw_text(4,  2, "SCORE", 1, C_LABEL);
    draw_text(92, 2, "LV",    1, C_LABEL);
}

void hud_all(void)
{
    hud_static();
    hud_score();
    hud_level();
    hud_pips();
}

void footer_clear(void) { rect(2, 146, 124, 14, C_BG0); }

void footer_hint(void)
{
    footer_clear();
    draw_text_c(149, "S2 PAUSE", 1, C_DIM);
    footer_mode = 0;
}

void footer_levelup(void)
{
    footer_clear();
    draw_text_c(149, "LEVEL UP", 1, C_ORANGE);
    footer_mode = 1;
    msg_left = 1000;
}

void footer_bonus(void)
{
    footer_clear();
    rect(4, 150, BONUS_BAR_PX, 6, C_GEM_GOLD);
    rect(4, 150, BONUS_BAR_PX, 1, C_GEM_HI);
    bar_px = BONUS_BAR_PX;
    bar_acc = 0;
    footer_mode = 2;
}

void footer_tick(unsigned dt)
{
    if (footer_mode == 1) {
        if (msg_left <= dt) footer_hint();
        else msg_left -= (uint16_t)dt;
    }
}

void bonus_bar_tick(unsigned dt)
{
    bar_acc += (uint16_t)dt;
    while (bar_acc >= 25 && bar_px) {
        bar_acc -= 25;
        bar_px--;
        rect(4 + bar_px, 150, 1, 6, C_BG0);
    }
    if (bar_acc >= 25) bar_acc = 24;
}

void draw_frame(void)
{
    rect(0, 0, SCR_W, SCR_H, C_BG0);
    rect(2, 22, 124, 124, C_FR_OUT);
    rect(3, 23, 122, 122, C_FR_IN);
}

void redraw_field(void)
{
    int x, y;
    for (y = 0; y < GH; y++)
        for (x = 0; x < GW; x++)
            draw_bg_cell(x, y);
    if (cellf[(food_y << 4) | food_x] & F_FOOD) draw_food();
    if (bonus_on) draw_gem();
    draw_snake_all();
}

void draw_panel(int x, int y, int w, int h)
{
    rect(x, y, w, h, C_FR_IN);
    rect(x + 1, y + 1, w - 2, h - 2, C_HUD);
}

void title_prompt(void)
{
    draw_text_c(112, "S1 START", 1, blink ? C_SCORE : C_BG0);
}

void title_tick(unsigned dt)
{
    blink_acc += (uint16_t)dt;
    if (blink_acc >= 500) { blink_acc -= 500; blink ^= 1; title_prompt(); }
}

void draw_title(void)
{
    static const uint8_t TP[13][2] = {
        { 1,2 }, { 2,2 }, { 3,2 }, { 3,1 }, { 4,1 }, { 5,1 }, { 5,2 },
        { 6,2 }, { 7,2 }, { 7,1 }, { 8,1 }, { 9,1 }, { 10,1 }
    };
    int i;

    rect(0, 0, SCR_W, SCR_H, C_BG0);
    rect(2, 2, 124, 156, C_FR_OUT);
    rect(3, 3, 122, 154, C_FR_IN);
    rect(4, 4, 120, 152, C_BG0);

    draw_big_title(22, 22, C_GREEN_SH);                      /* bóng đổ */
    draw_big_title(20, 20, C_GREEN);
    draw_text_c(52, "RISC-V FPGA", 1, C_LABEL);

    for (i = 0; i < 13; i++) {                               /* rắn trang trí */
        int mask = 0;
        int x = 8 + (TP[i][0] << 3), y = 78 + (TP[i][1] << 3);
        uint8_t me = (uint8_t)((TP[i][1] << 4) | TP[i][0]);
        if (i > 0)  mask |= nbr_bit(me, (uint8_t)((TP[i - 1][1] << 4) | TP[i - 1][0]));
        if (i < 12) mask |= nbr_bit(me, (uint8_t)((TP[i + 1][1] << 4) | TP[i + 1][0]));
        draw_seg(x, y, C_BG0, (i == 12) ? 1 : ((i == 0) ? 2 : 0), mask, 0, (unsigned)i);
    }
    draw_apple_px(8 + (12 << 3), 78 + (1 << 3));

    blink = 1;
    title_prompt();
    draw_text_c(128, "S2 PAUSE", 1, C_DIM);
    if (hi_score) {
        draw_text(34, 142, "BEST", 1, C_LABEL);
        draw_num(70, 142, hi_score, 4, 1, C_SCORE);
    }
    blink_acc = 0;
}

void draw_over(void)
{
    draw_panel(12, 44, 104, 72);
    draw_text_c(50, "GAME OVER", 1, C_RED);
    draw_text(24, 66, "SCORE", 1, C_LABEL);
    draw_num(72, 66, score, 4, 1, C_SCORE);
    if (new_best) draw_text_c(82, "NEW BEST", 1, C_GREEN);
    else { draw_text(24, 82, "BEST", 1, C_LABEL); draw_num(72, 82, hi_score, 4, 1, C_WHITE); }
    draw_text_c(98, "S1 RETRY", 1, C_SCORE);
}

void draw_pause(void)
{
    draw_panel(16, 52, 96, 56);
    rect(54, 58, 6, 14, C_WHITE);
    rect(68, 58, 6, 14, C_WHITE);
    draw_text_c(76, "PAUSED", 1, C_SCORE);
    draw_text_c(92, "S2 RESUME", 1, C_LABEL);
}
