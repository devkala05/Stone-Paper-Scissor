### 📄 `README.md`

# 🧠 GPU vs GPU: Rock-Paper-Scissors

This project simulates a 1000-round game of Rock-Paper-Scissors between two GPUs using CUDA.

- **GPU 0** plays randomly (Rock, Paper, Scissors chosen equally).
- **GPU 1** uses a pattern-based strategy: it tries to counter the most frequent move from GPU 0 so far.
- All 1000 rounds are played in parallel on the GPU.
- The host gathers the results and logs them for analysis.

### 🛠️ Build & Run

```
make        # Compile
make run    # Run the simulation
make clean  # Remove binary and logs
```

### 📁 Output

The results are saved in:

```
logs/game_log.txt
```

Each line contains the round number, moves from both GPUs, and the winner.

---
