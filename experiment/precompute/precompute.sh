#!/bin/bash
# 预计算实验脚本
# 需要修改的参数：m = 1,2,4,8,12,16
# rm experiment/precompute/result/precompute_result_msm17-24_1.txt
# rm experiment/precompute/result/precompute_result_msm17-24_2.txt
# rm experiment/precompute/result/precompute_result_msm17-24_4.txt
# rm experiment/precompute/result/precompute_result_msm17-24_8.txt
# rm experiment/precompute/result/precompute_result_msm17-24_12.txt
# rm experiment/precompute/result/precompute_result_msm17-24_16.txt
for i in $(seq 17 24)
do
   m=16
   BENCH_NPOW=$i cargo bench  | grep time: >> experiment/precompute/result/precompute_result_msm17-24_$m.txt
done


