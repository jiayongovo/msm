#!/bin/bash
s=${1:-1}
e=${2:-23}
today=$(date +%y-%m-%d)
current_time=$(date +%H-%M)
output_dir="/home/jiayong/msm/reports/test/$today"
output_file="$output_dir/$s to $e $current_time.txt"
# Create directory for today's date if it doesn't exist
mkdir -p "$output_dir"
cargo build --release
for ((i = s; i <= e; i++)); do
    TEST_NPOW=$i cargo test --release>>"$output_file"
done
