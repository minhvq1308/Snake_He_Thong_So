#ifndef FONT_H
#define FONT_H

#include <stdint.h>

/* sh = hệ số phóng đại dạng dịch bit: 0 -> x1, 1 -> x2, 2 -> x4 */
void draw_char(int x, int y, char ch, int sh, uint16_t col);
void draw_text(int x, int y, const char *s, int sh, uint16_t col);
int  text_w(const char *s, int sh);
void draw_text_c(int y, const char *s, int sh, uint16_t col);          /* căn giữa theo chiều ngang */
void draw_num(int x, int y, unsigned v, int nd, int sh, uint16_t col); /* nd chữ số, có số 0 đứng đầu */

/* chữ SNAKE cỡ lớn ở màn hình tiêu đề (mỗi điểm ảnh gốc = 3x3 px) */
void draw_big(int x, int y, int gi, uint16_t col);
void draw_big_title(int x, int y, uint16_t col);

#endif
