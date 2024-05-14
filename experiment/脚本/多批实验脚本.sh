#!/bin/bash
for i in $(seq 20 24)
do
    for j in 1 2 4 8 16; do
        BENCH_NPOW=$i  BENCHES=$j cargo bench >> experiment/result/多批实验_${i}.txt
    done
done


