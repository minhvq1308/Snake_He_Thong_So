/* Nhập liệu: hướng từ 4 nút / UART và hai nút onboard S1, S2 (qua peripheral hub) */
#include "input.h"
#include "game.h"
#include "hw.h"

uint8_t s1_flag, s2_flag;

void poll_input(void)
{
    uint32_t e = RD(HUB_EVENT);
    uint32_t b = RD(HUB_BTN);
    if ((e & 4u) && state == ST_PLAY) push_dir((int)(e & 3u));
    if (b & 1u) s1_flag = 1;
    if (b & 2u) s2_flag = 1;
}
