#!/bin/bash
s=17
n=19
times=2
# Function to run benchmarks
run_benchmarks() {
    for ((i=s; i<=n; i++)); do
        for ((j=1; j<=times; j++)); do
            BENCH_NPOW=$i RANDOM_BENCH="true" cargo bench
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

# Previous scheme bench
cd exper/msm && cargo build --release
run_benchmarks

# wlc_msm bench
cd ../wlc_msm/381_xyzz_constant && cargo build --release
run_benchmarks

cd ../.. 
