`timescale 1ns / 1ps

module tb_snake_soc;

    reg clk;
    reg resetn;
    reg uart_rx;

    wire tft_cs;
    wire tft_dc;
    wire tft_rst;
    wire tft_sck;
    wire tft_mosi;


    snake_soc uut (
        .clk      (clk),
        .resetn   (resetn),
        .uart_rx  (uart_rx),

        .tft_cs   (tft_cs),
        .tft_dc   (tft_dc),
        .tft_rst  (tft_rst),
        .tft_sck  (tft_sck),
        .tft_mosi (tft_mosi)
    );


    /*
     * ============================================================
     * 27 MHz clock
     * ============================================================
     */

    initial begin

        clk = 1'b0;

        forever
            #18.5 clk = ~clk;

    end


    /*
     * ============================================================
     * RESET
     * ============================================================
     */

    initial begin

        uart_rx = 1'b1;

        resetn = 1'b0;

        #1000;

        resetn = 1'b1;

    end


    /*
     * ============================================================
     * TFT RESET MONITOR
     * ============================================================
     */

    reg old_tft_rst;

    initial begin

        old_tft_rst = 1'bx;

        forever begin

            @(posedge clk);

            if (tft_rst !== old_tft_rst) begin

                $display(
                    "TIME=%0t TFT_RST = %b",
                    $time,
                    tft_rst
                );

                old_tft_rst = tft_rst;

            end

        end

    end


    /*
     * ============================================================
     * SPI BYTE MONITOR
     * ============================================================
     */

    reg [7:0] spi_shift;
    integer spi_bit;


    initial begin

        spi_shift = 8'h00;
        spi_bit   = 0;

    end


    always @(posedge tft_sck) begin

        if (!tft_cs) begin

            spi_shift[7-spi_bit] = tft_mosi;

            spi_bit = spi_bit + 1;


            if (spi_bit == 8) begin

                /*
                 * Chỉ in COMMAND.
                 *
                 * DATA pixel không in ra terminal.
                 */

                if (tft_dc == 1'b0) begin

                    $display(
                        "TIME=%0t TFT COMMAND = %02X",
                        $time,
                        spi_shift
                    );

                end

                spi_bit   = 0;
                spi_shift = 8'h00;

            end

        end

        else begin

            spi_bit = 0;
        end

    end


    /*
     * ============================================================
     * VCD
     * ============================================================
     */

    initial begin

        $dumpfile("build/snake_soc.vcd");

        $dumpvars(
            0,
            tb_snake_soc
        );


        /*
         * 500 ms simulation.
         */

        #500_000_000;


        $display("");
        $display("============================================");
        $display("       TFT ST7735 SIMULATION FINISHED");
        $display("============================================");

        $finish;

    end

endmodule