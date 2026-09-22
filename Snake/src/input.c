#include "input.h"

/*
 * ============================================================
 * UART MMIO
 * ============================================================
 *
 * UART_DATA:
 *     0x10000008
 *
 * UART_STATUS:
 *     0x1000000C
 *
 * Bit 0 của UART_STATUS:
 *     1 -> có dữ liệu
 *     0 -> không có dữ liệu
 * ============================================================
 */

#define UART_BASE   0x10000008

#define UART_RX     (*(volatile unsigned int *)(UART_BASE + 0))
#define UART_STATUS (*(volatile unsigned int *)(UART_BASE + 4))


void input_init(void)
{
    /*
     * UART được phần cứng SoC xử lý.
     * Firmware không cần cấu hình UART.
     */
}


void input_shutdown(void)
{
    /*
     * Không cần làm gì với UART.
     */
}


char input_get(void)
{
    /*
     * Kiểm tra UART có dữ liệu hay không.
     */
    if (UART_STATUS & 1)
    {
        return (char)UART_RX;
    }

    return '\0';
}


Direction input_to_direction(char input)
{
    switch (input)
    {
        case 'w':
        case 'W':
            return UP;

        case 's':
        case 'S':
            return DOWN;

        case 'a':
        case 'A':
            return LEFT;

        case 'd':
        case 'D':
            return RIGHT;

        default:
            /*
             * Không trả về RIGHT nữa.
             *
             * Hàm này chỉ được gọi với W/A/S/D
             * từ main.c.
             */
            return RIGHT;
    }
}