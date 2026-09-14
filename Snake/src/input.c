#include "input.h"

/*
 * UART của SoC RISC-V
 *
 * Địa chỉ này chỉ là địa chỉ tạm thời.
 * Sau khi thiết kế Verilog SoC, địa chỉ UART
 * phải trùng với địa chỉ được khai báo trong SoC.
 */
#define UART_BASE   0x10000008

#define UART_RX     (*(volatile unsigned int *)(UART_BASE + 0))
#define UART_STATUS (*(volatile unsigned int *)(UART_BASE + 4))

void input_init(void)
{
    /*
     * UART được phần cứng SoC khởi tạo.
     * Không cần cấu hình terminal như trên Linux.
     */
}

void input_shutdown(void)
{
    /*
     * Không cần khôi phục terminal.
     */
}

char input_get(void)
{
    /*
     * Kiểm tra UART có dữ liệu hay chưa.
     *
     * Bit 0 = 1: có dữ liệu nhận được.
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
            return RIGHT;
    }
}