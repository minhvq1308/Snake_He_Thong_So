.section .text
.global _start

_start:

    # ========================================================
    # Copy .data từ ROM sang RAM
    #
    # _sidata = địa chỉ dữ liệu .data trong ROM
    # _sdata  = địa chỉ bắt đầu .data trong RAM
    # _edata  = địa chỉ kết thúc .data trong RAM
    # ========================================================

    la t0, _sidata
    la t1, _sdata
    la t2, _edata

copy_data:

    bge t1, t2, clear_bss

    lw t3, 0(t0)
    sw t3, 0(t1)

    addi t0, t0, 4
    addi t1, t1, 4

    j copy_data


    # ========================================================
    # Xóa .bss về 0
    # ========================================================

clear_bss:

    la t0, _sbss
    la t1, _ebss

zero_bss:

    bge t0, t1, start_main

    sw zero, 0(t0)

    addi t0, t0, 4

    j zero_bss


    # ========================================================
    # Chạy chương trình C
    # ========================================================

start_main:

    call main


    # ========================================================
    # Nếu main() kết thúc thì đứng yên
    # ========================================================

hang:

    j hang