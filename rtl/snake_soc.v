`timescale 1ns / 1ps

// ============================================================
// Snake SoC
// PicoRV32 + ROM + RAM + UART RX
//
// Memory map:
//
// 0x00000000 - 0x0000FFFF : ROM 64 KB
// 0x00010000 - 0x00013FFF : RAM 16 KB
//
// 0x10000008 : UART DATA
// 0x1000000C : UART STATUS
//
// UART STATUS:
// bit 0 = 1 : co du lieu RX
// bit 0 = 0 : khong co du lieu
//
// CPU reset PC : 0x00000000
// Stack top    : 0x00014000
// ============================================================

module snake_soc (
    input wire clk,
    input wire resetn,
    input wire uart_rx
);

    // ========================================================
    // PicoRV32 memory interface
    // ========================================================

    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;

    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;

    reg [31:0] mem_rdata;


    // ========================================================
    // Memory map
    // ========================================================

    localparam ROM_BASE = 32'h00000000;
    localparam ROM_END  = 32'h00010000;

    localparam RAM_BASE = 32'h00010000;
    localparam RAM_END  = 32'h00014000;

    localparam UART_DATA_ADDR   = 32'h10000008;
    localparam UART_STATUS_ADDR = 32'h1000000C;


    // ========================================================
    // ROM
    //
    // 64 KB / 4 bytes = 16384 words
    // ========================================================

    reg [31:0] rom [0:16383];

    integer i;

    initial begin

        for (i = 0; i < 16384; i = i + 1)
            rom[i] = 32'h00000013;

        $readmemh(
            "Snake/build/snake_rom.hex",
            rom,
            0,
            1053
        );

    end


    // ========================================================
    // RAM
    //
    // 16 KB / 4 bytes = 4096 words
    // ========================================================

    reg [31:0] ram [0:4095];


    // ========================================================
    // UART RX
    // ========================================================

    wire [7:0] uart_data;
    wire       uart_valid;

    uart_rx uart_rx_inst (
        .clk   (clk),
        .rst   (~resetn),
        .rx    (uart_rx),
        .data  (uart_data),
        .valid (uart_valid)
    );


    // ========================================================
    // UART RX BUFFER
    // ========================================================

    reg [7:0] uart_buffer;
    reg       uart_ready;


    // ========================================================
    // UART BUFFER CONTROL
    //
    // uart_valid = 1:
    //     UART RX vua nhan xong 1 byte
    //
    //     uart_buffer <= uart_data
    //     uart_ready  <= 1
    //
    // CPU doc UART_DATA:
    //     uart_ready <= 0
    //
    // Dung else if de tranh 2 lenh cung ghi uart_ready
    // trong cung mot clock.
    // ========================================================

    always @(posedge clk or negedge resetn) begin

        if (!resetn) begin

            uart_buffer <= 8'h00;
            uart_ready  <= 1'b0;

        end

        else begin

            // ------------------------------------------------
            // UART vua nhan duoc ky tu moi
            // ------------------------------------------------

            if (uart_valid) begin

                uart_buffer <= uart_data;
                uart_ready  <= 1'b1;

            end

            // ------------------------------------------------
            // CPU doc UART DATA
            // ------------------------------------------------

            else if (
                mem_valid &&
                (mem_addr == UART_DATA_ADDR) &&
                (mem_wstrb == 4'b0000)
            ) begin

                uart_ready <= 1'b0;

            end

        end

    end


    // ========================================================
    // ROM SELECT
    // ========================================================

    wire rom_sel;

    assign rom_sel =
        mem_valid &&
        (mem_addr >= ROM_BASE) &&
        (mem_addr < ROM_END);


    // ========================================================
    // RAM SELECT
    // ========================================================

    wire ram_sel;

    assign ram_sel =
        mem_valid &&
        (mem_addr >= RAM_BASE) &&
        (mem_addr < RAM_END);


    // ========================================================
    // UART SELECT
    // ========================================================

    wire uart_data_sel;
    wire uart_status_sel;

    assign uart_data_sel =
        mem_valid &&
        (mem_addr == UART_DATA_ADDR);

    assign uart_status_sel =
        mem_valid &&
        (mem_addr == UART_STATUS_ADDR);


    // ========================================================
    // MEMORY READY
    // ========================================================

    assign mem_ready =
        rom_sel |
        ram_sel |
        uart_data_sel |
        uart_status_sel;


    // ========================================================
    // READ DATA
    // ========================================================

    always @(*) begin

        mem_rdata = 32'h00000000;

        // ----------------------------------------------------
        // ROM
        // ----------------------------------------------------

        if (rom_sel) begin

            mem_rdata = rom[mem_addr[15:2]];

        end

        // ----------------------------------------------------
        // RAM
        // ----------------------------------------------------

        else if (ram_sel) begin

            mem_rdata =
                ram[(mem_addr - RAM_BASE) >> 2];

        end

        // ----------------------------------------------------
        // UART DATA
        // ----------------------------------------------------

        else if (uart_data_sel) begin

            mem_rdata = {
                24'h000000,
                uart_buffer
            };

        end

        // ----------------------------------------------------
        // UART STATUS
        // ----------------------------------------------------

        else if (uart_status_sel) begin

            mem_rdata = {
                31'h00000000,
                uart_ready
            };

        end

    end


    // ========================================================
    // RAM WRITE
    // ========================================================

    always @(posedge clk) begin

        if (resetn && ram_sel) begin

            if (mem_wstrb[0])
                ram[(mem_addr - RAM_BASE) >> 2][7:0]
                    <= mem_wdata[7:0];

            if (mem_wstrb[1])
                ram[(mem_addr - RAM_BASE) >> 2][15:8]
                    <= mem_wdata[15:8];

            if (mem_wstrb[2])
                ram[(mem_addr - RAM_BASE) >> 2][23:16]
                    <= mem_wdata[23:16];

            if (mem_wstrb[3])
                ram[(mem_addr - RAM_BASE) >> 2][31:24]
                    <= mem_wdata[31:24];

        end

    end


    // ========================================================
    // PicoRV32
    // ========================================================

    picorv32 #(

        .STACKADDR(32'h00014000),

        .PROGADDR_RESET(32'h00000000),

        .ENABLE_IRQ(0),

        .ENABLE_MUL(1),

        .ENABLE_DIV(1),

        .BARREL_SHIFTER(1),

        .COMPRESSED_ISA(1),

        .ENABLE_COUNTERS(1)

    ) cpu (

        .clk(clk),

        .resetn(resetn),

        .mem_valid(mem_valid),

        .mem_instr(mem_instr),

        .mem_ready(mem_ready),

        .mem_addr(mem_addr),

        .mem_wdata(mem_wdata),

        .mem_wstrb(mem_wstrb),

        .mem_rdata(mem_rdata),

        .irq(32'b0)

    );

endmodule