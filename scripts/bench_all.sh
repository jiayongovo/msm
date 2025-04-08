#!/bin/bash
s=${1:-20}
e=${2:-25}
times=${3:-1}
today=$(date +%y-%m-%d)
current_time=$(date +%H-%M)
output_dir="/home/user/hpc/zk_msm/msm/reports/bench/25-03-28"
output_file="$output_dir/output_sppark.txt"
# output_sys_file="$output_dir/$current_time""_mmsm_sys.txt"
# output_avg_file="$output_dir/$current_time""_mmsm_avg.txt"
# Create directory for today's date if it doesn't exist
mkdir -p "$output_dir"

# Function to run benchmarks
run_benchmarks() {
    for ((i = s; i <= e; i++)); do
        for ((j = 1; j <= times; j++)); do
            BENCH_NPOW=$i  cargo bench >>"$output_file"
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

# cargo build --release && run_benchmarks
# cd exper/wlc_msm/381_xyzz_constant && cargo build --release && run_benchmarks
# cd ../381_xyzz_bal && run_benchmarks
# cd ../../

cd exper/sppark && run_sppark
cd ../../

# cat "$output_file" | grep "time:" >"$output_sys_file"

# # 提取中间值
# exper_times=($(grep -oP '\[\d+\.\d+ ms \K\d+\.\d+(?= ms \d+\.\d+ ms\])' "$output_sys_file"))

# # 计算每个实验的平均时间
# for ((i = 0; i < 3; i++)); do

#     for ((j = 0; j <= e - s; j++)); do
#         exper_time=0
#         for ((k = 0; k < times; k++)); do
#             exper_time=$(echo "scale=2; $exper_time + ${exper_times[i * (e - s + 1) * times + j * times + k]}" | bc)
#         done
#         average_time=$(echo "scale=2;$exper_time / $times" | bc)
#         if [ $i -eq 0 ]; then
#         echo "mmsm $((s + j)) $average_time" >> "$output_avg_file"
#         elif [ $i -eq 1 ]; then
#             echo "wlc_msm_con $((s + j)) $average_time" >> "$output_avg_file"
#         else
#             echo "wlc_msm_bal $((s + j)) $average_time" >> "$output_avg_file"
#         fi
#     done
# done
