/* SNAKE - firmware cho SoC PicoRV32 (Tang Nano 20K + TFT ST7735 128x160)
 *
 *  Điều khiển : 4 nút ngoài / phím WASD qua UART -> đổi hướng
 *               S1 (nút onboard) -> START / chơi lại / tiếp tục
 *               S2 (nút onboard) -> PAUSE / tiếp tục
 *
 *  Cấu trúc module (mũi tên = "gọi tới"):
 *      main.c -> app.c -> game.c -> ui.c -> font.c -> hw.c
 *                      \-> input.c      \-> game.h (ui chỉ đọc trạng thái để vẽ)
 *                      \-> timebase.c
 *
 *  PicoRV32 cấu hình RV32I KHÔNG có nhân/chia => toàn bộ code tránh * / % với biến.
 */
#include "app.h"

#ifndef HOST_SIM
int main(void)
{
    game_init();
    for (;;) game_poll();
    return 0;
}
#endif
