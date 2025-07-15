#include <cuda_runtime.h>
#include <curand_kernel.h>
#include <iostream>
#include <fstream>

#define NUM_ROUNDS 1000
#define ROCK 0
#define PAPER 1
#define SCISSORS 2

const char *moveName(int move) {
    switch (move) {
        case ROCK: return "Rock";
        case PAPER: return "Paper";
        case SCISSORS: return "Scissors";
        default: return "Invalid";
    }
}

__device__ int counterMostFrequent(int *opponentMoves, int round) {
    int rock = 0, paper = 0, scissors = 0;
    for (int i = 0; i < round; ++i) {
        if (opponentMoves[i] == ROCK) rock++;
        else if (opponentMoves[i] == PAPER) paper++;
        else if (opponentMoves[i] == SCISSORS) scissors++;
    }

    if (rock >= paper && rock >= scissors) return PAPER;
    else if (paper >= scissors) return SCISSORS;
    else return ROCK;
}

__global__ void playGame(int *gpu0Moves, int *gpu1Moves, int *results, unsigned long seed) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= NUM_ROUNDS) return;

    // GPU 0: random
    curandState state;
    curand_init(seed, idx, 0, &state);
    gpu0Moves[idx] = curand(&state) % 3;

    __syncthreads();

    // GPU 1: pattern-based
    if (idx == 0)
        gpu1Moves[idx] = curand(&state) % 3;
    else
        gpu1Moves[idx] = counterMostFrequent(gpu0Moves, idx);

    // Result: -1 = GPU 0 wins, 0 = tie, 1 = GPU 1 wins
    int p0 = gpu0Moves[idx];
    int p1 = gpu1Moves[idx];
    if (p0 == p1) results[idx] = 0; // Ties
    else if ((p0 == ROCK && p1 == SCISSORS) || (p0 == PAPER && p1 == ROCK) || (p0 == SCISSORS && p1 == PAPER))
        results[idx] = -1; // GPU 0 wins
    else
        results[idx] = 1; // GPU 1 wins
}

int main() {
    // Initailise GPUs
    int *gpu0Moves = new int[NUM_ROUNDS];
    int *gpu1Moves = new int[NUM_ROUNDS];
    int *results = new int[NUM_ROUNDS];

    //Cuda
    int *d_gpu0Moves, *d_gpu1Moves, *d_results;
    cudaMalloc(&d_gpu0Moves, NUM_ROUNDS * sizeof(int));
    cudaMalloc(&d_gpu1Moves, NUM_ROUNDS * sizeof(int));
    cudaMalloc(&d_results, NUM_ROUNDS * sizeof(int));

    //Plating games
    playGame<<<(NUM_ROUNDS + 255) / 256, 256>>>(d_gpu0Moves, d_gpu1Moves, d_results, time(NULL));
    cudaDeviceSynchronize();

    //Copy memory
    cudaMemcpy(gpu0Moves, d_gpu0Moves, NUM_ROUNDS * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(gpu1Moves, d_gpu1Moves, NUM_ROUNDS * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(results,   d_results,   NUM_ROUNDS * sizeof(int), cudaMemcpyDeviceToHost);

    // Calculating GPU1 and GPU2 wins and ties
    int win0 = 0, win1 = 0, tie = 0;

    std::ofstream logfile("logs/game_log.txt"); // logs file entry per game
    logfile << "Round, GPU0, GPU1, Result\n";

    for (int i = 0; i < NUM_ROUNDS; ++i) {
        const char *p0 = moveName(gpu0Moves[i]); // GPU0 move
        const char *p1 = moveName(gpu1Moves[i]); // GPU1 move
        const char *resultStr; // final result

        // assiging Result in string
        if (results[i] == -1) {
            resultStr = "GPU 0 Wins";
            win0++;
        } else if (results[i] == 1) {
            resultStr = "GPU 1 Wins";
            win1++;
        } else {
            resultStr = "Tie";
            tie++;
        }

        logfile << i + 1 << ", " << p0 << ", " << p1 << ", " << resultStr << "\n"; // writing in log file
    }

    // Overall summary of the games played
    logfile << "\nSummary:\n";
    logfile << "GPU 0 Wins: " << win0 << "\n";
    logfile << "GPU 1 Wins: " << win1 << "\n";
    logfile << "Ties: " << tie << "\n";
    logfile.close();

    std::cout << "Game complete. Results written to logs/game_log.txt\n";

    // Free the memory
    cudaFree(d_gpu0Moves);
    cudaFree(d_gpu1Moves);
    cudaFree(d_results);
    delete[] gpu0Moves;
    delete[] gpu1Moves;
    delete[] results;

    return 0;
}
