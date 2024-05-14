#!/bin/bash
for i in $(seq 17 23)
do
    for j in 1 2 4 8 16; do
        BENCH_NPOW=$i  BENCHES=$j cargo bench >> experiment/multi_batches/result/multi_batches_result_msm17-23_${j}.txt
    done
done


