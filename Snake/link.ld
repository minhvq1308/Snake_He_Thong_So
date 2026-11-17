/* RAM/ROM chung 16 KB tại 0x0000_0000 (khớp soc_memory.v ADDR_BITS=12 và STACK_TOP=0x4000 trong top.v) */
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 16K
}

SECTIONS
{
    .text : {
        *(.init)
        *(.text*)
        . = ALIGN(4);
    } > RAM

    .rodata : {
        *(.rodata*)
        *(.srodata*)
        . = ALIGN(4);
    } > RAM

    .data : {
        *(.data*)
        *(.sdata*)
        . = ALIGN(4);
    } > RAM

    .bss (NOLOAD) : {
        . = ALIGN(4);
        _bss_start = .;
        *(.sbss*)
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
    } > RAM

    _stack_top = ORIGIN(RAM) + LENGTH(RAM);

    /* chừa >= 2 KB cho stack (game dùng < 300 byte stack) */
    ASSERT(_bss_end <= 0x3800, "Firmware qua lon: con duoi 2KB cho stack")
}
