# Firmware Snake – cấu trúc module

| File | Vai trò | Phụ thuộc |
|---|---|---|
| `main.c` | Điểm vào: `game_init()` rồi lặp `game_poll()` | app |
| `app.c/.h` | Vòng lặp chính + máy trạng thái (TITLE→PLAY↔PAUSE→DYING→OVER) | game, ui, input, timebase |
| `game.c/.h` | Logic: dữ liệu rắn, va chạm, ăn mồi, level, mồi thưởng, bắt đầu/kết thúc ván | ui, hw, timebase |
| `ui.c/.h` | Giao diện: rắn, táo, mồi thưởng, HUD, chân trang, các màn hình | game (chỉ đọc), font, hw |
| `font.c/.h` | Font 3x5 (chữ+số), font tiêu đề 5x7 | hw |
| `hw.c/.h` | Thanh ghi TFT/HUB, hàm `rect()` – hàm duy nhất chạm vào màn hình | – |
| `input.c/.h` | Đọc hướng + nút S1/S2 từ hub | game, hw |
| `timebase.c/.h` | Đổi chu kỳ 27 MHz → ms (không chia) | hw |
| `config.h` | SCR_W, SCR_H, GW, GH, FX, FY | – |
| `colors.h` | Macro RGB565 và bảng màu | – |
| `start.S`, `link.ld`, `makehex.py`, `Makefile` | Khởi động, bố trí bộ nhớ, tạo hex, build | – |
| `sim/sim.c` | Mô phỏng + kiểm thử tự động trên PC (`make sim`) | tất cả trừ main.c |

Build: `make` (tạo firmware.hex)   |   Kiểm thử trên PC: `make sim`
