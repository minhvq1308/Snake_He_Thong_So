/* Mã khởi động cho PicoRV32 (reset tại 0x0, RAM 16 KB dùng chung code+data+stack) */
    .section .init
    .globl _start
_start:
    la   sp, _stack_top          /* PicoRV32 cũng tự đặt sp = STACKADDR, đặt lại cho chắc */

    la   a0, _bss_start          /* xoá .bss */
    la   a1, _bss_end
1:  bgeu a0, a1, 2f
    sw   zero, 0(a0)
    addi a0, a0, 4
    j    1b

2:  call main
3:  j    3b
