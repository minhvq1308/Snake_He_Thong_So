.section .text.init
.global _start

_start:
    la sp, _stack_top

    # -------------------------------------------------
    # Copy .data từ ROM -> RAM
    # -------------------------------------------------

    la t0, _sidata
    la t1, _sdata
    la t2, _edata

copy_data:
    bgeu t1, t2, clear_bss
    lw t3, 0(t0)
    sw t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    j copy_data

    # -------------------------------------------------
    # Clear .bss
    # -------------------------------------------------

clear_bss:
    la t1, _sbss
    la t2, _ebss
    li t3, 0

clear_bss_loop:
    bgeu t1, t2, start_main
    sw t3, 0(t1)
    addi t1, t1, 4
    j clear_bss_loop

    # -------------------------------------------------
    # main()
    # -------------------------------------------------

start_main:
    call main

hang:
    j hang
