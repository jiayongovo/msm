#!/bin/bash
s=${1:-1}
e=${2:-23}
# Create directory for today's date if it doesn't exist
cargo build --release
for ((i = s; i <= e; i++)); do
    MAIN_NPOW=$i cargo run --release
done
