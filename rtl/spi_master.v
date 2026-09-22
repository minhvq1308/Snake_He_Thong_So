module spi_master #(
    parameter CLK_DIV = 4
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

    reg [7:0] shift_reg;
    reg [15:0] div_cnt;
    reg [3:0] bit_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            busy      <= 0;
            done      <= 0;
            spi_sck   <= 0;
            spi_mosi  <= 0;
            shift_reg <= 0;
            div_cnt   <= 0;
            bit_cnt   <= 0;
        end
        else begin
            done <= 0;

            if (start && !busy) begin
                busy      <= 1;
                shift_reg <= data_in;
                bit_cnt   <= 0;
                div_cnt   <= 0;
                spi_sck   <= 0;
                spi_mosi  <= data_in[7];
            end

            else if (busy) begin

                if (div_cnt == CLK_DIV-1) begin
                    div_cnt <= 0;

                    if (!spi_sck) begin
                        spi_sck <= 1;
                    end
                    else begin
                        spi_sck <= 0;

                        if (bit_cnt == 7) begin
                            busy     <= 0;
                            done     <= 1;
                            spi_mosi <= 0;
                        end
                        else begin
                            bit_cnt   <= bit_cnt + 1;
                            shift_reg <= {shift_reg[6:0],1'b0};
                            spi_mosi  <= shift_reg[6];
                        end
                    end
                end
                else begin
                    div_cnt <= div_cnt + 1;
                end
            end
        end
    end

endmodule