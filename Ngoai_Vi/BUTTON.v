module gpio_buttons #(
    parameter CLK_FREQ = 27_000_000
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] btn,

    output reg [3:0]  press
);

    localparam integer DEBOUNCE_MAX = CLK_FREQ / 100;

    reg [3:0] btn_ff1;
    reg [3:0] btn_ff2;
    reg [3:0] btn_last;
    reg [31:0] debounce_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_ff1      <= 4'b1111;
            btn_ff2      <= 4'b1111;
            btn_last     <= 4'b1111;
            debounce_cnt <= 0;
            press        <= 0;
        end
        else begin
            btn_ff1 <= btn;
            btn_ff2 <= btn_ff1;
            press  <= 0;

            if (debounce_cnt < DEBOUNCE_MAX)
                debounce_cnt <= debounce_cnt + 1;
            else begin
                debounce_cnt <= 0;

                // active-low: 1 -> 0 = nhấn
                press <= btn_last & ~btn_ff2;

                btn_last <= btn_ff2;
            end
        end
    end

endmodule