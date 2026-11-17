#ifndef UI_H
#define UI_H

#include <stdint.h>

/* Mặt nạ các hướng nối giữa hai đốt rắn */
#define M_R 1
#define M_D 2
#define M_L 4
#define M_U 8


/* Trạng thái chân trang (game.c cần đọc/ghi) */
extern uint8_t  footer_mode;     /* 0 gợi ý, 1 LEVEL UP, 2 thanh mồi thưởng */
extern uint16_t msg_left;

/* ---- ô nền ---- */
uint16_t cell_bg(int cx, int cy);
void     draw_bg_cell(int cx, int cy);

/* ---- rắn ---- */
void draw_seg(int x, int y, uint16_t bg, int kind, int mask, int d, unsigned idx);
int  nbr_bit(uint8_t a, uint8_t b);
int  seg_mask(uint8_t i);
void draw_gseg(uint8_t i);
void draw_snake_all(void);

/* ---- táo, mồi thưởng ---- */
void draw_apple_px(int x, int y);
void draw_food(void);
void draw_gem(void);

/* ---- HUD / chân trang ---- */
void hud_score(void);
void hud_level(void);
void hud_pips(void);
void hud_static(void);
void hud_all(void);
void footer_clear(void);
void footer_hint(void);
void footer_levelup(void);
void footer_bonus(void);
void footer_tick(unsigned dt);        /* tắt dòng LEVEL UP sau 1 giây */
void bonus_bar_tick(unsigned dt);     /* co thanh thời gian mồi thưởng */

/* ---- màn hình ---- */
void draw_frame(void);
void redraw_field(void);
void draw_panel(int x, int y, int w, int h);
void title_prompt(void);
void title_tick(unsigned dt);         /* nhấp nháy chữ S1 START */
void draw_title(void);
void draw_over(void);
void draw_pause(void);

#endif
