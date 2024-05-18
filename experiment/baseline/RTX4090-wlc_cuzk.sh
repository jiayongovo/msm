#!/bin/bash

# jy-msm测量
rm experiment/baseline/result/RTX4090/jy-msm20-25.txt
rm experiment/baseline/result/RTX4090/wlc-bal20-25.txt
rm experiment/baseline/result/RTX4090/wlc-con20-25.txt
rm experiment/baseline/result/RTX4090/cuZK20-25.txt
for m in $(seq 1 3)
do 
   for i in $(seq 20 25)
   do
      BENCH_NPOW=$i cargo bench | grep time: >> experiment/baseline/result/RTX4090/jy-msm20-25.txt
   done
done 

# wlc-bal 测量 (todo 注意直接clone batches是16 需要修改)
# git clone https://github.com/dunkirkturbo/wlc_msm.git experiment/baseline/wlc_msm
cd experiment/baseline/wlc_msm/381_xyzz_bal
cargo build --release
# 跑到 25 跑不了了
for m in $(seq 1 3)
do 
   for i in $(seq 20 25)
   do
      BENCH_NPOW=$i cargo bench  | grep time: >> ../../result/RTX4090/wlc-bal20-25.txt
   done
done 

# wlc-con 测量
cd ../381_xyzz_constant
cargo build --release
for m in $(seq 1 3)
do
   for i in $(seq 20 25)
   do
      BENCH_NPOW=$i cargo bench | grep time:>> ../../result/RTX4090/wlc-con20-25.txt
   done
done

# git clone https://github.com/speakspeak/cuZK.git experiment/baseline/cuZK
cd ../../cuZK/test
make msmb

for m in $(seq 1 3)
do 
   for i in $(seq 20 24)
   do
      ./msmtestb $i >> ../../result/RTX4090/cuZK20-25.txt
   done
done

