#!/bin/bash

# cargo build --release
# for m in $(seq 1 3)
# do 
#    for i in $(seq 21 26)
#    do
#       BENCH_NPOW=$i cargo bench | grep time: >> experiment/baseline/result/A40/cluster_jy-msm21-26.txt
#    done
# done 


cd experiment/baseline/z-prize-msm-gpu
cargo build --release
for m in $(seq 1 3)
do 
   for i in $(seq 21 26)
   do
      BENCH_NPOW=$i cargo bench | grep time: >> ../result/A40/cluster_matter_lab_21-26.txt
   done
done 