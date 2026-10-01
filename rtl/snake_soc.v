`timescale 1ns / 1ps

module snake_soc (
    input  wire        clk,
    input  wire        rst,

    input  wire [3:0]  buttons,
    input  wire        uart_rx,

    output wire        tft_sck,
    output wire        tft_mosi,
    output wire        tft_cs,
    output wire        tft_dc,
    output wire        tft_rst
);

    // =========================================================
    // PicoRV32 BUS
    // =========================================================

    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;

    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;

    wire [3:0]  mem_wstrb;

    wire bus_write;

    assign bus_write = |mem_wstrb;


    // =========================================================
    // PERIPHERAL READ DATA
    // =========================================================

    wire [31:0] rom_rdata;
    wire [31:0] ram_rdata;
    wire [31:0] gpio_rdata;
    wire [31:0] timer_rdata;
    wire [31:0] uart_rdata;
    wire [31:0] tft_rdata;


    // =========================================================
    // ADDRESS DECODER
    // =========================================================

    // ROM:
    // 0x00000000 - 0x00003FFF
    wire sel_rom;

    // RAM:
    // 0x00004000 - 0x00007FFF
    wire sel_ram;

    // GPIO:
    // 0x10000000
    wire sel_gpio;

    // TIMER:
    // 0x10000004
    wire sel_timer;

    // UART:
    // 0x10000008 - 0x1000000F
    wire sel_uart;

    // TFT:
    // 0x10000010 - 0x1000001F
    wire sel_tft;

    assign sel_rom =
        (mem_addr[31:14] == 18'h00000);

    assign sel_ram =
        (mem_addr[31:14] == 18'h00001);

    assign sel_gpio =
        (mem_addr == 32'h10000000);

    assign sel_timer =
        (mem_addr == 32'h10000004);

    assign sel_uart =
        (mem_addr >= 32'h10000008) &&
        (mem_addr <  32'h10000010);

    assign sel_tft =
        (mem_addr >= 32'h10000010) &&
        (mem_addr <  32'h10000020);


    // =========================================================
    // PicoRV32 CPU
    // =========================================================

    picorv32 #(
        .ENABLE_COUNTERS   (0),
        .ENABLE_COUNTERS64 (0),
        .COMPRESSED_ISA    (0),
        .ENABLE_MUL        (1),
        .ENABLE_DIV        (1),
        .ENABLE_IRQ        (0)
    ) cpu (
        .clk       (clk),
        .resetn    (~rst),

        .mem_valid (mem_valid),
        .mem_instr (mem_instr),
        .mem_ready (mem_ready),

        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb (mem_wstrb),

        .mem_rdata (mem_rdata),

        .trap      ()
    );


    // =========================================================
    // ROM
    // =========================================================

    rom #(
        .ADDR_WIDTH(14)
    ) u_rom (
        .clk   (clk),
        .addr  (mem_addr),
        .rdata (rom_rdata)
    );


    // =========================================================
    // RAM
    // =========================================================

    // ram.v tự xử lý:
    // ram_addr = mem_addr - 0x4000
    //
    // Vì vậy ở đây truyền mem_addr nguyên vẹn.

    ram #(
        .ADDR_WIDTH(14)
    ) u_ram (
        .clk        (clk),

        .mem_valid  (mem_valid && sel_ram),
        .mem_instr  (mem_instr),

        .mem_write  (bus_write),
        .mem_wstrb  (mem_wstrb),

        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),

        .mem_rdata  (ram_rdata),

        .we         (bus_write)
    );


    // =========================================================
    // GPIO BUTTONS
    // =========================================================

    gpio_buttons u_gpio (
        .clk       (clk),
        .rst       (rst),

        .buttons   (buttons),

        .bus_valid (mem_valid && sel_gpio),
        .bus_write (bus_write),

        .bus_addr  (mem_addr),
        .bus_wdata (mem_wdata),

        .bus_rdata (gpio_rdata)
    );


    // =========================================================
    // TIMER
    // =========================================================

    timer #(
        .DIV(3_375_000)
    ) u_timer (
        .clk       (clk),
        .rst       (rst),

        .bus_valid (mem_valid && sel_timer),
        .bus_write (bus_write),

        .bus_addr  (mem_addr),
        .bus_wdata (mem_wdata),

        .bus_rdata (timer_rdata)
    );


    // =========================================================
    // UART RX
    // =========================================================

    wire [7:0] uart_data;
    wire       uart_valid;

    uart_rx #(
        .CLKS_PER_BIT(234)
    ) u_uart_rx (
        .clk        (clk),
        .rst        (rst),

        .rx         (uart_rx),

        .data_out   (uart_data),
        .data_valid (uart_valid)
    );


    // =========================================================
    // UART BUFFER
    //
    // uart_rx tạo data_valid chỉ 1 clock.
    // CPU polling có thể bỏ lỡ xung này.
    //
    // Vì vậy lưu byte UART lại cho đến khi CPU đọc.
    // =========================================================

    reg [7:0] uart_buffer;
    reg       uart_buffer_valid;

    wire uart_read_data;
    wire uart_read_status;

    assign uart_read_data =
        mem_valid &&
        sel_uart &&
        (mem_addr == 32'h10000008) &&
        !bus_write;

    assign uart_read_status =
        mem_valid &&
        sel_uart &&
        (mem_addr == 32'h1000000C) &&
        !bus_write;


    always @(posedge clk) begin

        if (rst) begin
            uart_buffer       <= 8'h00;
            uart_buffer_valid <= 1'b0;
        end

        else begin

            // Có byte UART mới
            if (uart_valid) begin
                uart_buffer       <= uart_data;
                uart_buffer_valid <= 1'b1;
            end

            // CPU đọc UART_DATA
            else if (uart_read_data) begin
                uart_buffer_valid <= 1'b0;
            end

        end
    end


    assign uart_rdata =
        (mem_addr == 32'h10000008) ?
            {24'h000000, uart_buffer} :

        (mem_addr == 32'h1000000C) ?
            {31'b0, uart_buffer_valid} :

        32'h00000000;


    // =========================================================
    // TFT ST7735
    // =========================================================

    wire        tft_cmd_valid;
    wire [31:0] tft_cmd_data;

    wire        tft_data_valid;
    wire [31:0] tft_data_data;

    wire        tft_cmd_ready;
    wire        tft_data_ready;


    // =========================================================
    // TFT ADDRESS MAP
    //
    // ĐÚNG THEO FIRMWARE:
    //
    // TFT_CMD    = 0x10000010
    // TFT_DATA   = 0x10000014
    // TFT_STATUS = 0x10000018
    // =========================================================

    wire tft_is_data;
    wire tft_is_cmd;
    wire tft_is_status;

    assign tft_is_cmd =
        (mem_addr == 32'h10000010);

    assign tft_is_data =
        (mem_addr == 32'h10000014);

    assign tft_is_status =
        (mem_addr == 32'h10000018);


    // =========================================================
    // TFT COMMAND WRITE
    // =========================================================

    assign tft_cmd_valid =
        mem_valid &&
        sel_tft &&
        tft_is_cmd &&
        bus_write &&
        tft_cmd_ready;

    assign tft_cmd_data =
        mem_wdata;


    // =========================================================
    // TFT DATA WRITE
    // =========================================================

    assign tft_data_valid =
        mem_valid &&
        sel_tft &&
        tft_is_data &&
        bus_write &&
        tft_data_ready;

    assign tft_data_data =
        mem_wdata;


    // =========================================================
    // TFT MODULE
    // =========================================================

    tft_st7735 u_tft (
        .clk        (clk),
        .rst        (rst),

        .cmd_valid  (tft_cmd_valid),
        .cmd_data   (tft_cmd_data),

        .data_valid (tft_data_valid),
        .data_data  (tft_data_data),

        .cmd_ready  (tft_cmd_ready),
        .data_ready (tft_data_ready),

        .bus_rdata  (tft_rdata),

        .spi_sck    (tft_sck),
        .spi_mosi   (tft_mosi),

        .tft_cs     (tft_cs),
        .tft_dc     (tft_dc),
        .tft_rst    (tft_rst)
    );


    // =========================================================
    // TFT STATUS READ DATA
    //
    // bit 0 = cmd_ready
    // bit 1 = data_ready
    // =========================================================

    wire [31:0] tft_status_rdata;

    assign tft_status_rdata =
        {30'b0, tft_data_ready, tft_cmd_ready};


    // =========================================================
    // READ DATA MUX
    // =========================================================

    reg [31:0] read_data;

    always @(*) begin

        read_data = 32'h00000000;

        if (sel_rom)
            read_data = rom_rdata;

        else if (sel_ram)
            read_data = ram_rdata;

        else if (sel_gpio)
            read_data = gpio_rdata;

        else if (sel_timer)
            read_data = timer_rdata;

        else if (sel_uart)
            read_data = uart_rdata;

        else if (sel_tft) begin

            if (tft_is_status)
                read_data = tft_status_rdata;

            else
                read_data = tft_rdata;

        end

        else
            read_data = 32'h00000000;

    end

    assign mem_rdata = read_data;


    // =========================================================
    // CPU MEMORY READY
    // =========================================================

    assign mem_ready =
        mem_valid &&
        (
            // ROM read
            sel_rom

            ||

            // RAM
            sel_ram

            ||

            // GPIO
            sel_gpio

            ||

            // TIMER
            sel_timer

            ||

            // UART
            sel_uart

            ||

            // TFT STATUS read
            (
                sel_tft &&
                tft_is_status
            )

            ||

            // TFT COMMAND write
            (
                sel_tft &&
                tft_is_cmd &&
                bus_write &&
                tft_cmd_ready
            )

            ||

            // TFT DATA write
            (
                sel_tft &&
                tft_is_data &&
                bus_write &&
                tft_data_ready
            )
        );


endmodule
