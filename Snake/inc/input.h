#ifndef INPUT_H
#define INPUT_H

#include <stdint.h>

extern uint8_t s1_flag, s2_flag;   /* S1/S2 đã nhấn (app.c xử lý rồi xóa) */
void poll_input(void);             /* đọc EVENT (hướng) và SYSBTN (S1/S2) */

#endif
