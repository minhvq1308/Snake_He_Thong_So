#include <stdint.h>

/* =========================================================
 * MEMORY MAP
 * ========================================================= */

#define GPIO_BASE       0x10000000u
#define TIMER_BASE      0x10000004u
#define UART_BASE       0x10000008u
#define TFT_BASE        0x10000010u

#define GPIO_REG        (*(volatile uint32_t *)GPIO_BASE)
#define TIMER_REG       (*(volatile uint32_t *)TIMER_BASE)

#define UART_RX         (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_STATUS     (*(volatile uint32_t *)(UART_BASE + 0x04))

#define TFT_CMD         (*(volatile uint32_t *)(TFT_BASE + 0x00))
#define TFT_DATA        (*(volatile uint32_t *)(TFT_BASE + 0x04))


/* =========================================================
 * TFT COMMANDS
 * ========================================================= */

#define TFT_CMD_CLEAR   1u
#define TFT_CMD_RECT    3u


/* =========================================================
 * TFT COLORS - RGB565
 * ========================================================= */

#define COLOR_BLACK     0x0000u
#define COLOR_GREEN     0x07E0u
#define COLOR_RED       0xF800u


/* =========================================================
 * SNAKE
 * ========================================================= */

#define GRID_WIDTH      16u
#define GRID_HEIGHT     20u

#define CELL_SIZE       8u

#define MAX_SNAKE       64u

#define DIR_UP          0u
#define DIR_RIGHT       1u
#define DIR_DOWN        2u
#define DIR_LEFT        3u


static uint8_t snake_x[MAX_SNAKE];
static uint8_t snake_y[MAX_SNAKE];

static uint8_t snake_length;

static uint8_t food_x;
static uint8_t food_y;

static uint8_t direction;


/* =========================================================
 * RANDOM
 * ========================================================= */

static uint32_t random_seed = 0x12345678u;


/*
 * Xorshift32
 */
static uint32_t random_number(void)
{
    random_seed ^= random_seed << 13;
    random_seed ^= random_seed >> 17;
    random_seed ^= random_seed << 5;

    return random_seed;
}


/*
 * Tra ve 0..max-1
 *
 * Ham nay giu lai de cac phan khac cua chuong trinh
 * van co the su dung.
 */
static uint8_t random_range(uint8_t max)
{
    uint32_t value;

    if (max == 0u)
    {
        return 0u;
    }

    value = random_number();

    return (uint8_t)(value % max);
}


/* =========================================================
 * TFT
 * ========================================================= */

static void tft_clear(void)
{
    TFT_CMD = TFT_CMD_CLEAR;
}


static void tft_rect(
    uint8_t x,
    uint8_t y,
    uint8_t width,
    uint8_t height,
    uint16_t color
)
{
    TFT_CMD = TFT_CMD_RECT;

    TFT_DATA = x;
    TFT_DATA = y;
    TFT_DATA = width;
    TFT_DATA = height;
    TFT_DATA = color;
}


static void draw_cell(
    uint8_t x,
    uint8_t y,
    uint16_t color
)
{
    uint8_t px;
    uint8_t py;

    px = (uint8_t)(x * CELL_SIZE);
    py = (uint8_t)(y * CELL_SIZE);

    tft_rect(
        px,
        py,
        CELL_SIZE,
        CELL_SIZE,
        color
    );
}


/* =========================================================
 * DRAW SNAKE
 * ========================================================= */

static void draw_snake(void)
{
    uint8_t i;

    for (i = 0u; i < snake_length; i++)
    {
        draw_cell(
            snake_x[i],
            snake_y[i],
            COLOR_GREEN
        );
    }
}


/* =========================================================
 * DRAW FOOD
 * ========================================================= */

static void draw_food(void)
{
    draw_cell(
        food_x,
        food_y,
        COLOR_RED
    );
}


/* =========================================================
 * DRAW GAME
 * ========================================================= */

static void draw_game(void)
{
    tft_clear();

    draw_snake();

    draw_food();
}


/* =========================================================
 * SPAWN FOOD
 *
 * X: 0..15
 * Y: 0..19
 *
 * Khong dung phep chia/modulo tren so 32-bit lon
 * de tranh CPU bi ket trong vong lap dai.
 * ========================================================= */

static void spawn_food(void)
{
    uint32_t r;

    uint8_t x;
    uint8_t y;

    uint8_t i;

    uint8_t collision;


    while (1)
    {
        /*
         * Tao random
         */
        r = random_number();


        /*
         * X = 0..15
         *
         * Chi lay 4 bit thap
         */
        x = (uint8_t)(r & 0x0Fu);


        /*
         * Y = 0..255
         *
         * Lay 8 bit tiep theo
         */
        y = (uint8_t)((r >> 8) & 0xFFu);


        /*
         * Dua Y ve 0..19
         *
         * Moi lan chi tru 20.
         * Toi da 12 lan.
         */
        while (y >= 20u)
        {
            y = (uint8_t)(y - 20u);
        }


        /*
         * Kiem tra food co trung than ran hay khong
         */
        collision = 0u;


        for (i = 0u; i < snake_length; i++)
        {
            if ((snake_x[i] == x) &&
                (snake_y[i] == y))
            {
                collision = 1u;
                break;
            }
        }


        /*
         * Neu khong trung -> luu food
         */
        if (collision == 0u)
        {
            food_x = x;
            food_y = y;

            return;
        }
    }
}


/* =========================================================
 * SNAKE INIT
 * ========================================================= */

static void snake_init(void)
{
    snake_length = 3u;

    snake_x[0] = 5u;
    snake_y[0] = 10u;

    snake_x[1] = 4u;
    snake_y[1] = 10u;

    snake_x[2] = 3u;
    snake_y[2] = 10u;

    direction = DIR_RIGHT;

    spawn_food();
}


/* =========================================================
 * BUTTON
 *
 * GPIO:
 *
 * bit 0 = UP
 * bit 1 = RIGHT
 * bit 2 = DOWN
 * bit 3 = LEFT
 * ========================================================= */

static void read_buttons(void)
{
    uint32_t buttons;

    buttons = GPIO_REG;


    if (buttons & (1u << 0))
    {
        if (direction != DIR_DOWN)
        {
            direction = DIR_UP;
        }
    }


    if (buttons & (1u << 1))
    {
        if (direction != DIR_LEFT)
        {
            direction = DIR_RIGHT;
        }
    }


    if (buttons & (1u << 2))
    {
        if (direction != DIR_UP)
        {
            direction = DIR_DOWN;
        }
    }


    if (buttons & (1u << 3))
    {
        if (direction != DIR_RIGHT)
        {
            direction = DIR_LEFT;
        }
    }
}


/* =========================================================
 * UART
 *
 * W = UP
 * D = RIGHT
 * S = DOWN
 * A = LEFT
 * ========================================================= */

static void read_uart(void)
{
    uint32_t status;
    uint8_t data;

    status = UART_STATUS;


    if (status & 1u)
    {
        data = (uint8_t)UART_RX;


        if ((data == 'w') || (data == 'W'))
        {
            if (direction != DIR_DOWN)
            {
                direction = DIR_UP;
            }
        }


        if ((data == 'd') || (data == 'D'))
        {
            if (direction != DIR_LEFT)
            {
                direction = DIR_RIGHT;
            }
        }


        if ((data == 's') || (data == 'S'))
        {
            if (direction != DIR_UP)
            {
                direction = DIR_DOWN;
            }
        }


        if ((data == 'a') || (data == 'A'))
        {
            if (direction != DIR_RIGHT)
            {
                direction = DIR_LEFT;
            }
        }
    }
}


/* =========================================================
 * TIMER
 * ========================================================= */

static uint8_t timer_tick(void)
{
    return (uint8_t)(TIMER_REG & 1u);
}


/* =========================================================
 * MOVE SNAKE
 * ========================================================= */

static void move_snake(void)
{
    uint8_t new_x;
    uint8_t new_y;

    uint8_t i;


    new_x = snake_x[0];
    new_y = snake_y[0];


    /*
     * Xac dinh dau moi
     */
    if (direction == DIR_UP)
    {
        if (new_y > 0u)
        {
            new_y--;
        }
        else
        {
            new_y = GRID_HEIGHT - 1u;
        }
    }


    if (direction == DIR_RIGHT)
    {
        if (new_x < (GRID_WIDTH - 1u))
        {
            new_x++;
        }
        else
        {
            new_x = 0u;
        }
    }


    if (direction == DIR_DOWN)
    {
        if (new_y < (GRID_HEIGHT - 1u))
        {
            new_y++;
        }
        else
        {
            new_y = 0u;
        }
    }


    if (direction == DIR_LEFT)
    {
        if (new_x > 0u)
        {
            new_x--;
        }
        else
        {
            new_x = GRID_WIDTH - 1u;
        }
    }


    /*
     * Dich than ran tu duoi len
     */
    for (i = snake_length; i > 0u; i--)
    {
        snake_x[i] = snake_x[i - 1u];
        snake_y[i] = snake_y[i - 1u];
    }


    /*
     * Gan dau moi
     */
    snake_x[0] = new_x;
    snake_y[0] = new_y;


    /*
     * Kiem tra an moi
     */
    if ((new_x == food_x) &&
        (new_y == food_y))
    {
        if (snake_length < MAX_SNAKE)
        {
            snake_length++;
        }

        spawn_food();
    }
}


/* =========================================================
 * MAIN
 * ========================================================= */

int main(void)
{
    snake_init();

    draw_game();


    while (1)
    {
        /*
         * Doc phim UART
         */
        read_uart();


        /*
         * Doc nut nhan
         */
        read_buttons();


        /*
         * Timer tao nhip di chuyen
         */
        if (timer_tick())
        {
            move_snake();

            draw_game();
        }
    }


    return 0;
}
