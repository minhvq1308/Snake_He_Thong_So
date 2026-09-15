ENTRY(_start)

MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
    RAM (rwx) : ORIGIN = 0x00010000, LENGTH = 16K
}

SECTIONS
{
    /* ==============================
       Code chương trình
       ============================== */
    .text :
    {
        . = ALIGN(4);
        _stext = .;

        *(.text)
        *(.text.*)

        . = ALIGN(4);
        _etext = .;
    } > ROM


    /* ==============================
       Dữ liệu chỉ đọc
       ============================== */
    .rodata :
    {
        . = ALIGN(4);

        *(.rodata)
        *(.rodata.*)
        *(.srodata)
        *(.srodata.*)

        . = ALIGN(4);
        _erodata = .;
    } > ROM


    /* ==============================
       .data
       
       Chạy ở RAM nhưng dữ liệu ban đầu
       được lưu trong ROM.
       ============================== */
    .data :
    {
        . = ALIGN(4);

        _sdata = .;

        *(.data)
        *(.data.*)
        *(.sdata)
        *(.sdata.*)

        . = ALIGN(4);

        _edata = .;
    } > RAM AT > ROM

    _sidata = LOADADDR(.data);


    /* ==============================
       BSS
       
       Biến chưa khởi tạo.
       Khi startup chạy sẽ được
       xóa về 0.
       ============================== */
    .bss :
    {
        . = ALIGN(4);

        _sbss = .;

        *(.bss)
        *(.bss.*)
        *(.sbss)
        *(.sbss.*)
        *(COMMON)

        . = ALIGN(4);

        _ebss = .;
    } > RAM


    /* ==============================
       Stack
       
       Stack nằm ở cuối RAM.
       ============================== */

    . = ALIGN(4);

    _heap_start = .;

    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}