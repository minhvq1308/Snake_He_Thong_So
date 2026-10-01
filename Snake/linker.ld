ENTRY(_start)

MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 16K
    RAM (rwx) : ORIGIN = 0x00004000, LENGTH = 16K
}

SECTIONS
{
    .text :
    {
        KEEP(*(.text.init))
        *(.text*)
        *(.rodata*)
    } > ROM

    .data :
    {
        _sdata = .;
        *(.data*)
        *(.sdata*)
        _edata = .;
    } > RAM AT > ROM

    _sidata = LOADADDR(.data);

    .bss :
    {
        _sbss = .;
        *(.bss*)
        *(COMMON)
        *(.sbss*)
        _ebss = .;
    } > RAM

    . = ALIGN(4);

    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
