module wasd_decoder(
    input  wire       clk,
    input  wire       rst,

    input  wire [7:0] uart_data,
    input  wire       uart_valid,

    input  wire [1:0] current_dir,

    output reg  [1:0] new_dir
);

    localparam UP    = 2'd0;
    localparam RIGHT = 2'd1;
    localparam DOWN  = 2'd2;
    localparam LEFT  = 2'd3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            new_dir <= RIGHT;
        end
        else if (uart_valid) begin

            case (uart_data)

                "W": begin
                    if (current_dir != DOWN)
                        new_dir <= UP;
                end

                "w": begin
                    if (current_dir != DOWN)
                        new_dir <= UP;
                end

                "D": begin
                    if (current_dir != LEFT)
                        new_dir <= RIGHT;
                end

                "d": begin
                    if (current_dir != LEFT)
                        new_dir <= RIGHT;
                end

                "S": begin
                    if (current_dir != UP)
                        new_dir <= DOWN;
                end

                "s": begin
                    if (current_dir != UP)
                        new_dir <= DOWN;
                end

                "A": begin
                    if (current_dir != RIGHT)
                        new_dir <= LEFT;
                end

                "a": begin
                    if (current_dir != RIGHT)
                        new_dir <= LEFT;
                end

                default:
                    new_dir <= current_dir;

            endcase
        end
    end

endmodule