#ifndef GAME_H
#define GAME_H

#include <stdint.h>

/* ---- Trạng thái chương trình ---- */
enum { ST_TITLE = 0, ST_PLAY, ST_PAUSE, ST_DYING, ST_OVER };

/* ---- Cờ của từng ô trong cellf[] ---- */
#define F_SNAKE 1
#define F_FOOD  2
#define F_BONUS 4

/* ---- Luật chơi ---- */
#define FOODS_PER_LEVEL 4
#define MAX_LEVEL       10
#define BONUS_EVERY     5
#define BONUS_MS        3000
#define BONUS_BAR_PX    120          /* 3000 ms / 25 ms = 120 px */
#define PTS_FOOD        10
#define PTS_BONUS       50


extern const int8_t   DX[4];                 /* 0=Phải 1=Xuống 2=Trái 3=Lên */
extern const int8_t   DY[4];
extern const uint16_t STEP_MS[MAX_LEVEL + 1]; /* chu kỳ bước (ms) theo level */

/* ---- Trạng thái trò chơi (định nghĩa trong game.c) ---- */
extern uint8_t  state;
extern uint8_t  body[256];       /* bộ đệm vòng toạ độ rắn: (y<<4)|x */
extern uint8_t  cellf[256];      /* cờ từng ô: F_SNAKE / F_FOOD / F_BONUS */
extern uint8_t  head_i, tail_i;
extern uint8_t  dir;             /* hướng của bước vừa đi */
extern uint8_t  q[2], qn;        /* hàng đợi đổi hướng */
extern uint8_t  grow;            /* số ô còn phải dài thêm */
extern uint8_t  dead;
extern unsigned score, hi_score;
extern uint8_t  new_best;
extern uint8_t  level, lvl_cnt, streak;
extern uint8_t  food_x, food_y;
extern uint8_t  bonus_on, bonus_x, bonus_y, bonus_alt;
extern uint16_t bonus_left;
extern uint16_t die_left;
extern uint16_t step_acc;
extern uint32_t rng;

/* ---- Hàm ---- */
uint32_t rnd(void);
unsigned rnd_below(unsigned n);
int      cell_free(int x, int y);
int      spawn_food(void);
void     bonus_cells(int on);
void     bonus_off(void);
void     spawn_bonus(void);
void     bonus_update(unsigned dt);   /* đếm ngược mồi thưởng (gọi mỗi nhịp khi đang chơi) */
void     start_game(void);
void     begin_death(void);
void     add_score(unsigned p);
void     eat_food(void);
void     eat_bonus(void);
void     game_step(void);             /* một bước di chuyển của rắn */
void     push_dir(int d);             /* nhận lệnh đổi hướng vào hàng đợi */

#endif
