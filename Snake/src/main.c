#include "game.h"
#include "input.h"
#include "display.h"


/*
 * ============================================================
 * CPU clock
 *
 * Tang Nano SoC hiện tại:
 * 27 MHz
 * ============================================================
 */

#define CPU_FREQ_HZ 27000000u


/*
 * ============================================================
 * Đọc cycle counter của RISC-V
 * ============================================================
 */

static unsigned int read_cycle(void)
{
    unsigned int value;

    __asm__ volatile (
        "rdcycle %0"
        : "=r"(value)
    );

    return value;
}


/*
 * ============================================================
 * Delay milliseconds
 *
 * Dùng RISC-V cycle counter.
 * ============================================================
 */

static void delay_ms(unsigned int ms)
{
    unsigned int start;
    unsigned int cycles;

    start = read_cycle();

    cycles =
        (CPU_FREQ_HZ / 1000u) * ms;

    while ((unsigned int)(read_cycle() - start) < cycles)
    {
    }
}


/*
 * ============================================================
 * Kiểm tra phím điều khiển
 * ============================================================
 */

static int is_direction_key(char key)
{
    if (key == 'w' || key == 'W')
        return 1;

    if (key == 'a' || key == 'A')
        return 1;

    if (key == 's' || key == 'S')
        return 1;

    if (key == 'd' || key == 'D')
        return 1;

    return 0;
}


/*
 * ============================================================
 * MAIN
 * ============================================================
 */

int main(void)
{
    Game game;


    /*
     * --------------------------------------------------------
     * Khởi tạo input
     * --------------------------------------------------------
     */

    input_init();


    /*
     * --------------------------------------------------------
     * Khởi tạo game
     * --------------------------------------------------------
     */

    game_init(&game);

    game_set_difficulty(
        &game,
        NORMAL
    );

    game.state = GAME_PLAYING;


    /*
     * --------------------------------------------------------
     * Vẽ game lần đầu
     * --------------------------------------------------------
     */

    display_draw(&game);


    /*
     * --------------------------------------------------------
     * GAME LOOP
     * --------------------------------------------------------
     */

    while (1)
    {
        char key;


        /*
         * Đọc UART.
         *
         * Nếu không có dữ liệu:
         * input_get() trả về '\0'.
         */

        key = input_get();


        /*
         * ====================================================
         * GAME PLAYING
         * ====================================================
         */

        if (game.state == GAME_PLAYING)
        {
            /*
             * W/A/S/D:
             * đổi hướng Snake.
             */

            if (is_direction_key(key))
            {
                Direction direction;

                direction =
                    input_to_direction(key);

                snake_set_direction(
                    &game.snake,
                    direction
                );
            }


            /*
             * P:
             * Pause.
             */

            if (key == 'p' || key == 'P')
            {
                game_toggle_pause(&game);

                display_pause_screen(&game);

                continue;
            }


            /*
             * Chờ theo difficulty.
             */

            delay_ms(
                (unsigned int)game.speed_ms
            );


            /*
             * Update Snake.
             */

            game_update(&game);


            /*
             * Vẽ lại màn hình.
             */

            display_draw(&game);


            /*
             * Nếu Game Over thì vòng sau
             * sẽ xử lý trạng thái đó.
             */
        }


        /*
         * ====================================================
         * GAME PAUSED
         * ====================================================
         */

        else if (game.state == GAME_PAUSED)
        {
            /*
             * P:
             * tiếp tục game.
             */

            if (key == 'p' || key == 'P')
            {
                game_toggle_pause(&game);

                display_draw(&game);
            }

            /*
             * R:
             * restart.
             */

            else if (key == 'r' || key == 'R')
            {
                game_restart(&game);

                display_draw(&game);
            }

            /*
             * Không cần chạy game.
             */

            delay_ms(20);
        }


        /*
         * ====================================================
         * GAME OVER
         * ====================================================
         */

        else if (game.state == GAME_OVER)
        {
            /*
             * R:
             * chơi lại.
             */

            if (key == 'r' || key == 'R')
            {
                game_restart(&game);

                display_draw(&game);
            }

            /*
             * Không cho Snake tiếp tục chạy.
             */

            delay_ms(20);
        }


        /*
         * ====================================================
         * GAME START
         * ====================================================
         */

        else
        {
            game.state = GAME_PLAYING;

            display_draw(&game);
        }
    }


    return 0;
}