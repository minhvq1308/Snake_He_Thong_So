module spi_master #(
    parameter integer CLK_DIV = 2
)(
    input  wire       clk,
    input  wire       rst,

    input  wire       start,
    input  wire [7:0] data_in,

    output reg        busy,
    output reg        done,

    output reg        spi_sck,
    output reg        spi_mosi
);

    reg [7:0]  shift_reg;
    reg [3:0]  bit_count;
    reg [15:0] clk_count;

    always @(posedge clk) begin

        if (rst) begin

            shift_reg <= 8'd0;
            bit_count <= 4'd0;
            clk_count <= 16'd0;

            busy <= 1'b0;
            done <= 1'b0;

            spi_sck  <= 1'b0;
            spi_mosi <= 1'b0;

        end

        else begin

            // done chỉ tồn tại 1 clock
            done <= 1'b0;

            // =====================================================
            // IDLE
            // =====================================================

            if (!busy) begin

                spi_sck <= 1'b0;

                if (start) begin


                    busy      <= 1'b1;
                    shift_reg <= data_in;
                    bit_count <= 4'd0;
                    clk_count <= 16'd0;

                    // Gửi MSB trước
                    spi_mosi <= data_in[7];

                end

            end

            // =====================================================
            // SPI BUSY
            // =====================================================

            else begin

                if (clk_count == CLK_DIV - 1) begin

                    clk_count <= 16'd0;

                    // -------------------------------------------------
                    // SCK LOW -> HIGH
                    // -------------------------------------------------

                    if (!spi_sck) begin

                        spi_sck <= 1'b1;

                    end

                    // -------------------------------------------------
                    // SCK HIGH -> LOW
                    // -------------------------------------------------

                    else begin

                        spi_sck <= 1'b0;

                        // Đã truyền đủ 8 bit
                        if (bit_count == 4'd7) begin

                            busy     <= 1'b0;
                            done     <= 1'b1;
                            spi_mosi <= 1'b0;

                        end

                        // Chuyển sang bit tiếp theo
                        else begin

                            bit_count <= bit_count + 1'b1;

                            shift_reg <= {
                                shift_reg[6:0],
                                1'b0
                            };

                            // MSB tiếp theo
                            spi_mosi <= shift_reg[6];

                        end

                    end

                end

                else begin

                    clk_count <= clk_count + 1'b1;

                end

            end

        end

    end

endmodule
