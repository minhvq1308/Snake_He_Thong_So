CC = gcc

CFLAGS = -Wall -Wextra -std=c11 -Iinc

SRC = src/main.c \
      src/snake.c \
      src/food.c \
      src/game.c \
      src/input.c \
      src/display.c

TARGET = build/snake

all: $(TARGET)

$(TARGET): $(SRC)
	mkdir -p build
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET)

run: $(TARGET)
	./$(TARGET)

debug:
	mkdir -p build
	$(CC) $(CFLAGS) -g $(SRC) -o $(TARGET)

clean:
	rm -rf build

.PHONY: all run debug clean