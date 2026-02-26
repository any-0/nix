CC := gcc
CPPFLAGS := -Iinclude
CFLAGS := -std=c17 -Wall -Wextra -Wpedantic -O2
SRC_DIR := src
BUILD_DIR := build
TARGET := $(BUILD_DIR)/main
SRC := $(wildcard $(SRC_DIR)/*.c)
OBJ := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SRC))

.PHONY: all run clean build

all: $(TARGET)

build:
	@mkdir -p $(BUILD_DIR)

$(TARGET): $(OBJ) | build
	@$(CC) $(CFLAGS) -o $@ $^ -lm
	@chmod +x $@

run: $(TARGET)
	@test -x $(TARGET) || chmod +x $(TARGET)
	@./$(TARGET)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | build
	@$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

clean:
	@rm -f $(TARGET) $(OBJ)
