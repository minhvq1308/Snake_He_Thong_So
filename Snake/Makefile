# Biên dịch firmware snake cho PicoRV32 (RV32I, không nhân/chia, 16 KB RAM)
#   make            -> firmware.hex  (copy đè vào thư mục project Gowin rồi synthesize lại)
#   make size       -> xem dung lượng code
#   make check      -> kiểm tra không có phép nhân/chia lọt vào
#   make sim        -> chạy mô phỏng game trên PC (cần gcc), kiểm thử tự động
#
# Nếu toolchain của bạn có tiền tố khác:  make CROSS=riscv-none-elf-
# Nếu màu đỏ/xanh bị đảo trên màn hình :  make clean && make SWAP_RB=1

CROSS ?= $(firstword $(foreach p,riscv32-unknown-elf- riscv64-unknown-elf- riscv-none-elf- riscv64-linux-gnu- riscv32-esp-elf-,$(if $(shell which $(p)gcc 2>/dev/null),$(p))))

# ---- các module ----
SRCS = main.c app.c game.c ui.c font.c hw.c input.c timebase.c
HDRS = $(wildcard *.h)

CC      = $(CROSS)gcc
OBJCOPY = $(CROSS)objcopy
SIZE    = $(CROSS)size
OBJDUMP = $(CROSS)objdump

CFLAGS  = -march=rv32i -mabi=ilp32 -Os -g0 -ffreestanding -fno-builtin -nostdlib \
          -fno-tree-loop-distribute-patterns -fno-pic -mno-relax \
          -ffunction-sections -fdata-sections -Wall -Wextra
ifdef SWAP_RB
CFLAGS += -DSWAP_RB
endif
LDFLAGS = -nostdlib -nostartfiles -T link.ld -Wl,--gc-sections -Wl,--no-relax -Wl,-Map=firmware.map

all: firmware.hex

firmware.elf: start.S $(SRCS) $(HDRS) link.ld
	@test -n "$(CROSS)" || (echo "Khong tim thay riscv gcc. Dat CROSS=<tien-to->, vi du CROSS=riscv64-unknown-elf-"; exit 1)
	@# thử link kèm libgcc (phòng khi compiler tự gọi __mulsi3...), nếu thiếu multilib thì link không libgcc
	$(CC) $(CFLAGS) $(LDFLAGS) start.S $(SRCS) -o $@ -lgcc 2>/dev/null || $(CC) $(CFLAGS) $(LDFLAGS) start.S $(SRCS) -o $@

firmware.bin: firmware.elf
	$(OBJCOPY) -O binary $< $@

firmware.hex: firmware.bin makehex.py
	python3 makehex.py $< 4096 > $@
	@$(SIZE) firmware.elf

size: firmware.elf
	$(SIZE) $<

# kiểm tra không có phép nhân/chia nào lọt vào (PicoRV32 cấu hình không có M-extension)
check: firmware.elf
	@if $(OBJDUMP) -d firmware.elf | grep -E '__(mul|div|udiv|mod|umod)si3' >/dev/null; then \
	    echo "CANH BAO: co goi __mulsi3/__divsi3 (cham)"; else echo "OK: khong co phep nhan/chia"; fi

# mô phỏng trên PC: biên dịch NGUYÊN VĂN các module (trừ main.c) với phần cứng giả trong sim/sim.c
sim:
	gcc -O1 -Wall -Wextra -DHOST_SIM -I. -o sim/sim sim/sim.c $(filter-out main.c,$(SRCS))
	cd sim && ./sim

clean:
	rm -f firmware.elf firmware.bin firmware.hex firmware.map sim/sim

.PHONY: all size check sim clean
