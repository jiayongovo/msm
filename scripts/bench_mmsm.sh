#!/bin/bash
s=1
n=23
times=1
# Function to run benchmarks
run_benchmarks() {
    for ((i=s; i<=n; i++)); do
        for ((j=1; j<=times; j++)); do
            BENCH_NPOW=$i RANDOM_BENCH="random" cargo bench
        done
    done
}

cargo build --release && run_benchmarks > reports/mmsm_bench.txt