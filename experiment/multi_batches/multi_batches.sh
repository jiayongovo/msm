#!/bin/bash
# rm experiment/multi_batches/result/msm17-23_1.txt
# rm experiment/multi_batches/result/msm17-23_2.txt
# rm experiment/multi_batches/result/msm17-23_4.txt
# rm experiment/multi_batches/result/msm17-23_8.txt
# rm experiment/multi_batches/result/msm17-23_16.txt
for m in $(seq 1 2)
do 
    for i in $(seq 17 23)
    do
        for j in 1 2 4 8 16; do
            BENCH_NPOW=$i  BENCHES=$j cargo bench | grep time: >> experiment/multi_batches/result/msm17-23_${j}.txt
        done
    done
done


