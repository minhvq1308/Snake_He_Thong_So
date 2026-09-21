`timescale 1ns / 1ps

module tb_snake_soc;

    reg clk;
    reg resetn;
    reg uart_rx;

    reg last_uart_ready;
    reg got_uart_data;

    // ============================================================
    // CLOCK 27 MHz
    // ============================================================
    initial begin
        clk = 1'b0;
        forever #18.5185 clk = ~clk;
    end

    // ============================================================
    // RESET
    // ============================================================
    initial begin
        resetn = 1'b0;

        #200;

        resetn = 1'b1;
    end

    // ============================================================
    // DUT
    // ============================================================
    snake_soc uut (
        .clk     (clk),
        .resetn  (resetn),
        .uart_rx (uart_rx)
    );

    // ============================================================
    // INITIAL
    // ============================================================
    initial begin
        last_uart_ready = 1'b0;
        got_uart_data   = 1'b0;
    end

    // ============================================================
    // UART READY MONITOR
    // ============================================================
    always @(posedge clk) begin

        if (resetn) begin

            if (uut.uart_ready != last_uart_ready) begin

                $display(
                    "TIME=%0t  UART_READY CHANGED: %b -> %b  BUFFER=%02h",
                    $time,
                    last_uart_ready,
                    uut.uart_ready,
                    uut.uart_buffer
                );

                last_uart_ready <= uut.uart_ready;

            end

        end

    end

    // ============================================================
    // UART RX MONITOR
    // ============================================================
    always @(posedge clk) begin

        if (resetn && uut.uart_valid) begin

            $display(
                "TIME=%0t  UART RX RECEIVED  DATA=%02h  CHAR=%c",
                $time,
                uut.uart_data,
                uut.uart_data
            );

        end

    end

    // ============================================================
    // CPU ENTER input_get()
    //
    // input_get() = 0x00000CC8
    // ============================================================
    always @(posedge clk) begin

        if (resetn) begin

            if (uut.cpu.reg_pc == 32'h00000CC8) begin

                $display(
                    "TIME=%0t  CPU ENTERED input_get()  PC=%08h",
                    $time,
                    uut.cpu.reg_pc
                );

            end

        end

    end

    // ============================================================
    // CPU READ UART STATUS
    //
    // UART STATUS = 0x1000000C
    // ============================================================
    always @(posedge clk) begin

        if (resetn && uut.mem_valid) begin

            if (uut.mem_addr == 32'h1000000C) begin

                $display(
                    "TIME=%0t  CPU READ UART STATUS  RDATA=%08h  READY=%b  PC=%08h",
                    $time,
                    uut.mem_rdata,
                    uut.uart_ready,
                    uut.cpu.reg_pc
                );

            end

        end

    end

    // ============================================================
    // CPU READ UART DATA
    //
    // UART DATA = 0x10000008
    // ============================================================
    always @(posedge clk) begin

        if (resetn && uut.mem_valid) begin

            if (uut.mem_addr == 32'h10000008) begin

                $display(
                    "TIME=%0t  CPU READ UART DATA  RDATA=%08h  BUFFER=%02h  READY=%b  PC=%08h",
                    $time,
                    uut.mem_rdata,
                    uut.uart_buffer,
                    uut.uart_ready,
                    uut.cpu.reg_pc
                );

                got_uart_data <= 1'b1;

            end

        end

    end

    // ============================================================
    // CPU FUNCTION MONITOR
    // ============================================================
    always @(posedge clk) begin

        if (resetn) begin

            // game_update()
            if (uut.cpu.reg_pc == 32'h00000970) begin

                $display(
                    "TIME=%0t  CPU ENTERED game_update()  PC=%08h",
                    $time,
                    uut.cpu.reg_pc
                );

            end

            // display_draw()
            if (uut.cpu.reg_pc == 32'h00000DF0) begin

                $display(
                    "TIME=%0t  CPU ENTERED display_draw()  PC=%08h",
                    $time,
                    uut.cpu.reg_pc
                );

            end

        end

    end

    // ============================================================
    // UART SEND 1 BIT
    //
    // 27 MHz / 115200 ≈ 234 clock cycles / bit
    // ============================================================
    task uart_send_bit;

        input bit_value;

        integer i;

        begin

            uart_rx = bit_value;

            for (i = 0; i < 234; i = i + 1)
                @(posedge clk);

        end

    endtask

    // ============================================================
    // UART SEND 1 BYTE
    //
    // 1 start bit
    // 8 data bits, LSB first
    // 1 stop bit
    // ============================================================
    task uart_send_byte;

        input [7:0] data;

        integer i;

        begin

            // START BIT
            uart_send_bit(1'b0);

            // DATA BITS
            for (i = 0; i < 8; i = i + 1)
                uart_send_bit(data[i]);

            // STOP BIT
            uart_send_bit(1'b1);

            // IDLE
            uart_rx = 1'b1;

        end

    endtask

    // ============================================================
    // MAIN TEST
    // ============================================================
    initial begin

        // UART idle = HIGH
        uart_rx = 1'b1;

        $display("");
        $display("============================================");
        $display("       SNAKE SOC UART SIMULATION");
        $display("============================================");
        $display("");

        $display("CPU STARTUP...");
        $display("");

        // ========================================================
        // Chờ CPU đi vào input_get()
        // ========================================================
        wait (uut.cpu.reg_pc == 32'h00000CC8);

        $display("");
        $display("============================================");
        $display("CPU READY FOR UART INPUT");
        $display("============================================");
        $display("");

        repeat (10)
            @(posedge clk);

        // ========================================================
        // SEND W
        // ========================================================
        $display("");
        $display("============================================");
        $display("SEND UART: 'w' = 0x77");
        $display("============================================");
        $display("");

        uart_send_byte(8'h77);

        // ========================================================
        // CHỜ CPU ĐỌC UART DATA
        // ========================================================
        wait (got_uart_data == 1'b1);

        #1000;

        // ========================================================
        // PASS
        // ========================================================
        $display("");
        $display("============================================");
        $display("       UART CPU READ TEST PASSED");
        $display("============================================");
        $display("");
        $display("CPU da doc duoc byte 'w' = 0x77");
        $display("");

        $finish;

    end

    // ============================================================
    // TIMEOUT
    // ============================================================
    initial begin

        #20000000000;

        if (!got_uart_data) begin

            $display("");
            $display("============================================");
            $display("       UART CPU READ TEST FAILED");
            $display("============================================");
            $display("");
            $display("CPU chua doc duoc UART DATA.");
            $display("");

            $finish;

        end

    end

endmodule