CC = riscv64-unknown-elf-gcc
OBJCOPY = riscv64-unknown-elf-objcopy

CFLAGS = -Wall -Wextra -std=c11 -Iinc \
         -march=rv32im \
         -mabi=ilp32 \
         -ffreestanding \
         -O0

ASFLAGS = -march=rv32im \
          -mabi=ilp32

LDFLAGS = -nostdlib \
          -nostartfiles \
          -nodefaultlibs \
          -T linker.ld

SRC = src/main.c \
      src/snake.c \
      src/food.c \
      src/game.c \
      src/input.c \
      src/display.c

ASM = start.S

ELF = build/snake.elf
BIN = build/snake.bin

all: $(BIN)

$(ELF): $(SRC) $(ASM) linker.ld
	mkdir -p build
	$(CC) $(CFLAGS) $(ASFLAGS) $(LDFLAGS) \
	$(ASM) $(SRC) -o $(ELF)

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $(ELF) $(BIN)

clean:
	rm -rf build

.PHONY: all clean