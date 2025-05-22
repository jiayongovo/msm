#!/bin/bash
# filepath: /home/user/hpc/zk_msm/msm/scripts/baseline.sh

s=${1:-20}
e=${2:-24}
times=${3:-3}

output_dir="reports/bench/$(date +%d)"
mkdir -p "$output_dir"
mkdir -p "$output_dir/raw"


base_dir="/home/user/hpc/zk_msm/msm"
results_file="$base_dir/$output_dir/baseline_$(date +%H-%M).csv"
echo "impl,pow,time(ms),mem(MB)" > "$results_file"


bench_msm() {
    local name=$1
    local path=$2
    local features=$3
    local extra_env=$4

    pushd "$base_dir/$path" >/dev/null

    cd "$base_dir/$path" || exit 1
    cargo build --release >/dev/null 2>&1

    for ((i = s; i <= e; i++)); do
        total_time=0
        max_mem=0
        for ((j = 1; j <= times; j++)); do
            out_file="$base_dir/$output_dir/raw/${name}_output.txt"
            mem_file="$base_dir/$output_dir/raw/${name}_memory.csv"
            
            # 启动GPU监控
            nvidia-smi --query-compute-apps=pid,used_memory --format=csv -l 1 >> "$mem_file" &
            monitor_pid=$!
            sleep 1
            
            # 运行测试
            if [ -n "$features" ]; then
                BENCH_NPOW=$i $extra_env cargo bench --features=$features >> "$out_file" 2>&1
            else
                BENCH_NPOW=$i $extra_env cargo bench >> "$out_file" 2>&1
            fi
            
            # 停止监控
            kill $monitor_pid 2>/dev/null
            wait $monitor_pid 2>/dev/null

            # 提取执行时间
            curr_time=$(grep -oP '\[\d+\.\d+ ms \K\d+\.\d+(?= ms)' "$out_file" | tail -1)
            if [ -n "$curr_time" ]; then
                total_time=$(echo "$total_time + $curr_time" | bc)
            fi
            
            curr_mem=$(awk -F', ' 'NR>1 {gsub(/ MiB/, "", $2); if(+$2>max) max=$2} END {print max+0}' "$mem_file")
            if [ -n "$curr_mem" ] && [ $(echo "$curr_mem > $max_mem" | bc) -eq 1 ]; then
                max_mem=$curr_mem
            fi
        done
        avg_time=$(echo "scale=2; $total_time / $times" | bc)
        echo "$name,$i,$avg_time,$max_mem" >> "$results_file"
    done

    popd >/dev/null
}

# 运行所有实现的基准测试
bench_msm "sppark" "exper/sppark/poc/msm-cuda" "bls12_381" ""
bench_msm "wlc_msm_constant" "exper/wlc_msm/381_xyzz_constant" ""
bench_msm "wlc_msm_bal" "exper/wlc_msm/381_xyzz_bal" ""
bench_msm "mmsm" "." ""

# 输出结果
echo "========================================"
column -t -s ',' "$results_file"
echo "========================================"
