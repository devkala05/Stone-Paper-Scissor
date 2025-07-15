TARGET = rps_game
SRC = rps_game.cu
NVCC = nvcc
CFLAGS = -std=c++11

LOG_DIR = logs
LOG_FILE = $(LOG_DIR)/game_log.txt

.PHONY: all run clean

all: $(TARGET)

$(TARGET): $(SRC)
	@mkdir -p $(LOG_DIR)
	$(NVCC) $(CFLAGS) $(SRC) -o $(TARGET)
	@echo "Compiled successfully."

run: $(TARGET)
	./$(TARGET)
	@echo "Log saved to $(LOG_FILE)"

clean:
	rm -f $(TARGET)
	rm -rf $(LOG_DIR)
	@echo "Cleaned up build and logs."
