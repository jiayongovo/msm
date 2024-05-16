#!/bin/bash
# 预计算实验脚本
# 需要修改的参数：m = 1,2,4,8,12,16
for i in $(seq 17 24)
do
   m=16
   echo "Precompute M = $m MSM scale $i"
   BENCH_NPOW=$i TEST_TRUE="true" cargo bench >> experiment/precompute/result/precompute_result_msm17-24_$m.txt
done


