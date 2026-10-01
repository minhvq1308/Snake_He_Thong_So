CROSS = riscv64-unknown-elf-

CC = $(CROSS)gcc
OBJCOPY = $(CROSS)objcopy

CFLAGS = -march=rv32i \
         -mabi=ilp32 \
         -ffreestanding \
         -fno-builtin \
         -nostdlib \
         -O2

LDFLAGS = -T linker.ld \
          -nostdlib

TARGET = firmware

all: $(TARGET).elf $(TARGET).bin $(TARGET).hex $(TARGET)_words.hex


# =========================================================
# LINK
# =========================================================

$(TARGET).elf: main.o start.o linker.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ main.o start.o


# =========================================================
# COMPILE MAIN
# =========================================================

main.o: main.c
	$(CC) $(CFLAGS) -c main.c -o main.o


# =========================================================
# COMPILE STARTUP
# =========================================================

start.o: start.S
	$(CC) $(CFLAGS) -c start.S -o start.o


# =========================================================
# BINARY
# =========================================================

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@


# =========================================================
# INTEL HEX
# =========================================================

$(TARGET).hex: $(TARGET).elf
	$(OBJCOPY) -O ihex $< $@


# =========================================================
# ROM WORD HEX
#
# Chuyen firmware.bin thanh cac word 32-bit
# theo little-endian de $readmemh() trong Verilog doc.
# =========================================================

$(TARGET)_words.hex: $(TARGET).bin
	python3 -c "data=open('$<','rb').read(); f=open('$@','w'); [f.write(f'{int.from_bytes(data[i:i+4].ljust(4,b\"\\x00\"),\"little\"):08x}\n') for i in range(0,len(data),4)]; f.close()"


# =========================================================
# CLEAN
# =========================================================

clean:
	rm -f *.o *.elf *.bin *.hex
