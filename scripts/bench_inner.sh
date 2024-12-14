#!/bin/bash
s=1
n=23
times=1
# Function to run benchmarks
run_benchmarks() {
    for ((i = s; i <= n; i++)); do
        for ((j = 1; j <= times; j++)); do
            BENCH_NPOW=$i RANDOM_BENCH="random" cargo bench
        done
    done
}

run_sppark() {
    for ((i = s; i <= n; i++)); do
        for ((j = 1; j <= times; j++)); do
            BENCH_NPOW=$i cargo bench --features=bls12_381
        done
    done
}

cargo build --release
# Local test
# for ((i=s; i<=n; i++)); do
#     TEST_NPOW=$i cargo test
# done

# Local bench
run_benchmarks

# wlc_msm bench
cd exper/wlc_msm/381_xyzz_constant && cargo build --release
run_benchmarks

cd ../381_xyzz_bal && cargo build --release
run_benchmarks

cd ../../sppark/poc/msm-cuda && cargo build --release --features=bls12_381
run_sppark

cd ../../../../
