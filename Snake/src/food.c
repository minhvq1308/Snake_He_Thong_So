#include "food.h"
#include "config.h"

/*
 * Bộ sinh số giả ngẫu nhiên đơn giản.
 *
 * Không sử dụng rand() của thư viện C.
 * Phù hợp với chương trình bare-metal RISC-V.
 */
static unsigned int random_seed = 123456789;

/*
 * Tạo một số giả ngẫu nhiên.
 */
static unsigned int random_next(void)
{
    random_seed =
        random_seed * 1103515245u + 12345u;

    return random_seed;
}

/*
 * Tạo vị trí mới cho thức ăn.
 *
 * Thức ăn không được nằm trên thân Snake.
 */
void food_spawn(
    Point *food,
    const Snake *snake
)
{
    int valid;

    do
    {
        valid = 1;

        /*
         * Tạo tọa độ X trong khoảng:
         * 0 -> BOARD_WIDTH - 1
         */
        food->x =
            random_next() % BOARD_WIDTH;

        /*
         * Tạo tọa độ Y trong khoảng:
         * 0 -> BOARD_HEIGHT - 1
         */
        food->y =
            random_next() % BOARD_HEIGHT;

        /*
         * Kiểm tra thức ăn có nằm trên Snake không.
         */
        for (int i = 0;
             i < snake->length;
             i++)
        {
            if (food->x == snake->body[i].x &&
                food->y == snake->body[i].y)
            {
                valid = 0;
                break;
            }
        }

    } while (!valid);
}

/*
 * Kiểm tra Snake có ăn thức ăn hay chưa.
 *
 * Trả về:
 * 1 -> đã ăn
 * 0 -> chưa ăn
 */
int food_is_eaten(
    Point food,
    Point head
)
{
    return (
        food.x == head.x &&
        food.y == head.y
    );
}