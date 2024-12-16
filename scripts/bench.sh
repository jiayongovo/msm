#!/bin/bash
s=${1:-1}
e=${2:-21}
times=${3:-2}
today=$(date +%y-%m-%d)
current_time=$(date +%H-%M)
output_dir="/home/jiayong/msm/reports/bench/$today"
output_file="$output_dir/$current_time""_mmsm.txt"
output_sys_file="$output_dir/$current_time""_mmsm_sys.txt"
output_avg_file="$output_dir/$current_time""_mmsm_avg.txt"
# Create directory for today's date if it doesn't exist
mkdir -p "$output_dir"

# Function to run benchmarks
run_benchmarks() {
    for ((i = s; i <= e; i++)); do
        for ((j = 1; j <= times; j++)); do
            BENCH_NPOW=$i RANDOM_BENCH="random" cargo bench >>"$output_file"
        done
    done
}

run_sppark() {
    for ((i = s; i <= e; i++)); do
        for ((j = 1; j <= times; j++)); do
            BENCH_NPOW=$i cargo bench --features=bls12_381 >>"$output_file"
        done
    done
}

cargo build --release && run_benchmarks

cat "$output_file" | grep "time:" >"$output_sys_file"

# 提取中间值
exper_times=($(grep -oP '\[\d+\.\d+ ms \K\d+\.\d+(?= ms \d+\.\d+ ms\])' "$output_sys_file"))

for ((j = 0; j <= e - s; j++)); do
    exper_time=0
    for ((k = 0; k < times; k++)); do
        exper_time=$(echo "scale=2; $exper_time + ${exper_times[j * times + k]}" | bc)
    done
    average_time=$(echo "scale=2;$exper_time / $times" | bc)
    echo "mmsm $((s + j)) $average_time" >>"$output_avg_file"
done
