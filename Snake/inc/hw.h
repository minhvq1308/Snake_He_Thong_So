#ifndef HW_H
#define HW_H

#include <stdint.h>

/* ---- Truy cập thanh ghi: HOST_SIM = chạy thử trên máy tính với phần cứng giả ---- */
#ifdef HOST_SIM
extern uint32_t sim_rd(uint32_t a);
extern void     sim_wr(uint32_t a, uint32_t v);
#define RD(a)    sim_rd(a)
#define WR(a, v) sim_wr((a), (uint32_t)(v))
#else
#define RD(a)    (*(volatile uint32_t *)(a))
#define WR(a, v) (*(volatile uint32_t *)(a) = (uint32_t)(v))
#endif

/* ---- Bản đồ thanh ghi ---- */
#define TFT_XY     0x40000000u
#define TFT_WH     0x40000004u
#define TFT_COLOR  0x40000008u
#define TFT_CTRL   0x4000000Cu     /* ghi 1 = vẽ ; đọc bit0 = bận */

#define HUB_EVENT  0x40000010u     /* [1:0]=hướng [2]=valid (đọc là xóa) */
#define HUB_CYCLES 0x40000014u     /* bộ đếm chạy tự do @27MHz            */
#define HUB_BTN    0x4000001Cu     /* [0]=S1 [1]=S2 (đọc là xóa)          */

#define CLK_PER_MS 27000u

/* Hàm duy nhất chạm vào màn hình: tô hình chữ nhật đồng màu */
void rect(int x, int y, int w, int h, uint16_t c);

#endif
