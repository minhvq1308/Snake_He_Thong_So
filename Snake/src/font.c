/* Hệ chữ: font 3x5 (chữ + số) và font tiêu đề 5x7. Chỉ dùng rect() để vẽ. */
#include "font.h"
#include "hw.h"
#include "config.h"

#define G(a, b, c, d, e) ((uint16_t)(((a) << 12) | ((b) << 9) | ((c) << 6) | ((d) << 3) | (e)))

static const uint16_t FONT_AZ[26] = {
    G(2,5,7,5,5), G(6,5,6,5,6), G(3,4,4,4,3), G(6,5,5,5,6), G(7,4,6,4,7), /* A-E */
    G(7,4,6,4,4), G(3,4,5,5,3), G(5,5,7,5,5), G(7,2,2,2,7), G(1,1,1,5,2), /* F-J */
    G(5,5,6,5,5), G(4,4,4,4,7), G(5,7,7,5,5), G(6,5,5,5,5), G(2,5,5,5,2), /* K-O */
    G(6,5,6,4,4), G(2,5,5,7,3), G(6,5,6,5,5), G(3,4,2,1,6), G(7,2,2,2,2), /* P-T */
    G(5,5,5,5,7), G(5,5,5,5,2), G(5,5,7,7,5), G(5,5,2,5,5), G(5,5,2,2,2), /* U-Y */
    G(7,1,2,4,7)                                                          /* Z   */
};

static const uint16_t FONT_09[10] = {
    G(7,5,5,5,7), G(2,6,2,2,7), G(6,1,2,4,7), G(6,1,2,1,6), G(5,5,7,1,1),
    G(7,4,6,1,6), G(3,4,7,5,7), G(7,1,2,2,2), G(7,5,7,5,7), G(7,5,7,1,6)
};

void draw_char(int x, int y, char ch, int sh, uint16_t col)
{
    uint16_t g;
    uint8_t  rw[5];
    int r, c, h, sft;

    if (ch >= 'A' && ch <= 'Z')      g = FONT_AZ[ch - 'A'];
    else if (ch >= '0' && ch <= '9') g = FONT_09[ch - '0'];
    else if (ch == '-')              g = G(0,0,7,0,0);
    else                             return;

    sft = 12;
    for (r = 0; r < 5; r++) { rw[r] = (uint8_t)((g >> sft) & 7); sft -= 3; }

    r = 0;
    while (r < 5) {
        uint8_t row = rw[r];
        h = 1;
        while (r + h < 5 && rw[r + h] == row) h++;
        c = 0;
        while (c < 3) {
            if (row & (4 >> c)) {
                int s0 = c;
                while (c < 3 && (row & (4 >> c))) c++;
                rect(x + (s0 << sh), y + (r << sh), (c - s0) << sh, h << sh, col);
            } else {
                c++;
            }
        }
        r += h;
    }
}

void draw_text(int x, int y, const char *s, int sh, uint16_t col)
{
    while (*s) { draw_char(x, y, *s, sh, col); x += 4 << sh; s++; }
}

int text_w(const char *s, int sh)
{
    int n = 0;
    while (*s++) n++;
    return (n << (sh + 2)) - (1 << sh);
}

void draw_text_c(int y, const char *s, int sh, uint16_t col)
{
    draw_text((SCR_W - text_w(s, sh)) >> 1, y, s, sh, col);
}

void draw_num(int x, int y, unsigned v, int nd, int sh, uint16_t col)
{
    static const unsigned p10[5] = { 1u, 10u, 100u, 1000u, 10000u };
    int i;
    for (i = nd - 1; i >= 0; i--) {
        unsigned d = 0;
        while (v >= p10[i]) { v -= p10[i]; d++; }
        draw_char(x, y, (char)('0' + d), sh, col);
        x += 4 << sh;
    }
}

/* font tiêu đề 5x7: S N A K E */
static const uint8_t BIG_GLYPH[5][7] = {
    { 0x0F, 0x10, 0x10, 0x0E, 0x01, 0x01, 0x1E },   /* S */
    { 0x11, 0x19, 0x15, 0x15, 0x13, 0x11, 0x11 },   /* N */
    { 0x0E, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11 },   /* A */
    { 0x11, 0x12, 0x14, 0x18, 0x14, 0x12, 0x11 },   /* K */
    { 0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x1F }    /* E */
};

#define X3(v) (((v) << 1) + (v))                     /* v*3 không cần phép nhân */

void draw_big(int x, int y, int gi, uint16_t col)   /* mỗi điểm ảnh = 3x3 px */
{
    int r, c;
    for (r = 0; r < 7; r++) {
        uint8_t row = BIG_GLYPH[gi][r];
        c = 0;
        while (c < 5) {
            if (row & (16 >> c)) {
                int s0 = c;
                while (c < 5 && (row & (16 >> c))) c++;
                rect(x + X3(s0), y + X3(r), X3(c - s0), 3, col);
            } else {
                c++;
            }
        }
    }
}

void draw_big_title(int x, int y, uint16_t col)
{
    int i;
    for (i = 0; i < 5; i++) { draw_big(x, y, i, col); x += 18; }
}
