`timescale 1ns / 1ps

module snake_soc (
    input wire clk,
    input wire resetn,
    input wire uart_rx,

    output wire tft_cs,
    output wire tft_dc,
    output wire tft_rst,
    output wire tft_sck,
    output wire tft_mosi
);

    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;

    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;

    reg [31:0] mem_rdata;


    /*
     * ============================================================
     * MEMORY MAP
     * ============================================================
     */

    localparam ROM_BASE = 32'h00000000;
    localparam ROM_END  = 32'h00010000;

    localparam RAM_BASE = 32'h00010000;
    localparam RAM_END  = 32'h00014000;

    localparam UART_DATA_ADDR   = 32'h10000008;
    localparam UART_STATUS_ADDR = 32'h1000000C;

    localparam TFT_DATA_ADDR   = 32'h10000010;
    localparam TFT_CMD_ADDR    = 32'h10000014;
    localparam TFT_STATUS_ADDR = 32'h10000018;


    /*
     * ============================================================
     * ROM
     * ============================================================
     */

    reg [31:0] rom [0:16383];

    integer i;

    initial begin

        for (i = 0; i < 16384; i = i + 1)
            rom[i] = 32'h00000013;

        $readmemh(
            "Snake/build/snake_rom.hex",
            rom
        );

    end


    /*
     * ============================================================
     * RAM
     * ============================================================
     */

    reg [31:0] ram [0:4095];


    /*
     * ============================================================
     * UART
     * ============================================================
     */

    wire [7:0] uart_data;
    wire       uart_valid;

    uart_rx uart_rx_inst (
        .clk   (clk),
        .rst   (~resetn),
        .rx    (uart_rx),
        .data  (uart_data),
        .valid (uart_valid)
    );

    reg [7:0] uart_buffer;
    reg       uart_ready;


    always @(posedge clk or negedge resetn) begin

        if (!resetn) begin

            uart_buffer <= 8'h00;
            uart_ready  <= 1'b0;

        end

        else begin

            if (uart_valid) begin

                uart_buffer <= uart_data;
                uart_ready  <= 1'b1;

            end

            else if (
                mem_valid &&
                (mem_addr == UART_DATA_ADDR) &&
                (mem_wstrb == 4'b0000)
            ) begin

                uart_ready <= 1'b0;

            end
        end
    end


    /*
     * ============================================================
     * SELECT
     * ============================================================
     */

    wire rom_sel;
    wire ram_sel;

    wire uart_data_sel;
    wire uart_status_sel;

    wire tft_data_sel;
    wire tft_cmd_sel;
    wire tft_status_sel;


    assign rom_sel =
        mem_valid &&
        (mem_addr >= ROM_BASE) &&
        (mem_addr < ROM_END);


    assign ram_sel =
        mem_valid &&
        (mem_addr >= RAM_BASE) &&
        (mem_addr < RAM_END);


    assign uart_data_sel =
        mem_valid &&
        (mem_addr == UART_DATA_ADDR);


    assign uart_status_sel =
        mem_valid &&
        (mem_addr == UART_STATUS_ADDR);


    assign tft_data_sel =
        mem_valid &&
        (mem_addr == TFT_DATA_ADDR);


    assign tft_cmd_sel =
        mem_valid &&
        (mem_addr == TFT_CMD_ADDR);


    assign tft_status_sel =
        mem_valid &&
        (mem_addr == TFT_STATUS_ADDR);


    /*
     * ============================================================
     * ST7735
     * ============================================================
     */

    wire tft_busy;
    wire tft_ready;

    wire tft_cmd_valid;
    wire tft_data_valid;


    assign tft_cmd_valid =
        tft_cmd_sel &&
        (mem_wstrb != 4'b0000) &&
        tft_ready;


    assign tft_data_valid =
        tft_data_sel &&
        (mem_wstrb != 4'b0000) &&
        tft_ready;


    st7735 #(
        .CLK_FREQ(27_000_000),
        .SPI_DIV (4)
    ) st7735_inst (

        .clk        (clk),
        .rst        (~resetn),

        .cmd_valid  (tft_cmd_valid),
        .cmd_data   (mem_wdata[7:0]),

        .data_valid (tft_data_valid),
        .data_in    (mem_wdata[7:0]),

        .busy       (tft_busy),
        .ready      (tft_ready),

        .tft_cs     (tft_cs),
        .tft_dc     (tft_dc),
        .tft_rst    (tft_rst),
        .tft_sck    (tft_sck),
        .tft_mosi   (tft_mosi)
    );


    /*
     * ============================================================
     * CPU MEMORY READY
     * ============================================================
     */

    assign mem_ready =
        rom_sel |
        ram_sel |
        uart_data_sel |
        uart_status_sel |
        (tft_cmd_sel  && tft_ready) |
        (tft_data_sel && tft_ready) |
        tft_status_sel;


    /*
     * ============================================================
     * CPU READ DATA
     * ============================================================
     */

    always @(*) begin

        mem_rdata = 32'h00000000;


        if (rom_sel) begin

            mem_rdata =
                rom[mem_addr[15:2]];

        end

        else if (ram_sel) begin

            mem_rdata =
                ram[(mem_addr - RAM_BASE) >> 2];

        end

        else if (uart_data_sel) begin

            mem_rdata = {
                24'h000000,
                uart_buffer
            };

        end

        else if (uart_status_sel) begin

            mem_rdata = {
                31'h00000000,
                uart_ready
            };

        end

        else if (tft_status_sel) begin

            mem_rdata = {
                30'h00000000,
                tft_busy,
                tft_ready
            };

        end

    end


    /*
     * ============================================================
     * RAM WRITE
     * ============================================================
     */

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


    /*
     * ============================================================
     * PicoRV32
     * ============================================================
     */

    picorv32 #(
        .STACKADDR       (32'h00014000),
        .PROGADDR_RESET  (32'h00000000),

        .ENABLE_IRQ      (0),
        .ENABLE_MUL      (1),
        .ENABLE_DIV      (1),
        .BARREL_SHIFTER  (1),
        .COMPRESSED_ISA  (1),
        .ENABLE_COUNTERS (1)

    ) cpu (

        .clk       (clk),
        .resetn    (resetn),

        .mem_valid (mem_valid),
        .mem_instr (mem_instr),

        .mem_ready (mem_ready),

        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb (mem_wstrb),

        .mem_rdata (mem_rdata),

        .irq       (32'b0)

    );

endmodule