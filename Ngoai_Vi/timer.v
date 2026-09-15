module game_timer #(
    parameter CLK_FREQ = 27_000_000,
    parameter GAME_HZ  = 8
)(
    input  wire clk,
    input  wire rst,

    output reg game_tick
);

    localparam integer MAX_COUNT = CLK_FREQ / GAME_HZ - 1;

    reg [31:0] count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count     <= 0;
            game_tick <= 0;
        end
        else begin
            game_tick <= 0;

            if (count >= MAX_COUNT) begin
                count     <= 0;
                game_tick <= 1;
            end
            else begin
                count <= count + 1;
            end
        end
    end

endmodule