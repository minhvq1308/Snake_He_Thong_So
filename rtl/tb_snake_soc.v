`timescale 1ns / 1ps

module tb_snake_soc;

    reg clk;
    reg resetn;

    // ========================================================
    // Clock
    // ========================================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    // ========================================================
    // Reset
    // ========================================================

    initial begin
        resetn = 0;

        #100;

        resetn = 1;
    end


    // ========================================================
    // SoC
    // ========================================================

    snake_soc uut (
        .clk    (clk),
        .resetn (resetn)
    );


    // ========================================================
    // Theo dõi hoạt động của CPU
    // ========================================================

    always @(posedge clk) begin

        if (resetn && uut.mem_valid) begin

            $display(
                "TIME=%0t  ADDR=%08h  VALID=%b  READY=%b",
                $time,
                uut.mem_addr,
                uut.mem_valid,
                uut.mem_ready
            );

        end

    end


    // ========================================================
    // Kết thúc simulation
    // ========================================================

    initial begin

        $display("======================================");
        $display("       SNAKE SOC SIMULATION");
        $display("======================================");

        #5000;

        $display("======================================");
        $display("Simulation finished.");
        $display("======================================");

        $finish;

    end

endmodule
