/* Lớp truy cập phần cứng TFT */
#include "hw.h"

void rect(int x, int y, int w, int h, uint16_t c)
{
    if (w <= 0 || h <= 0) return;
    while (RD(TFT_CTRL) & 1u) { }
    WR(TFT_XY,    (uint32_t)x | ((uint32_t)y << 16));
    WR(TFT_WH,    (uint32_t)w | ((uint32_t)h << 16));
    WR(TFT_COLOR, c);
    WR(TFT_CTRL,  1u);
}
