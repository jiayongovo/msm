#!/bin/bash
s=${1:-1}
e=${2:-24}
times=${3:-3}
output_dir="reports/test/"
output_file="$output_dir/test.txt"

if [ -f "$output_file" ]; then
    rm "$output_file"
fi
mkdir -p "$output_dir"

# Function to run benchmarks
run_test() {
    for ((i = s; i <= e; i++)); do
        for ((j = 1; j <= times; j++)); do
            BENCH_NPOW=$i RANDOM_BENCH="random" cargo bench >>"$output_file"
        done
    done
}


cargo build --release && run_test
