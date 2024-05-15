#!/bin/bash

# jy-msm测量
for i in $(seq 20 25)
do
   BENCH_NPOW=$i cargo bench >> experiment/baseline/result/RTX4090/jy-msm20-25.txt
done

# wlc-bal 测量 (todo 注意直接clone batches是16 需要修改)
# git clone https://github.com/dunkirkturbo/wlc_msm.git experiment/baseline/wlc_msm
cd experiment/baseline/wlc_msm/381_xyzz_bal
echo "wlc-bal 测量"
cargo build --release
# 跑到 25 跑不了了
for i in $(seq 20 25)
do
   BENCH_NPOW=$i cargo bench >> ../../result/RTX4090/wlc-bal20-25.txt
done

# wlc-con 测量
cd ../381_xyzz_constant
cargo build --release
for i in $(seq 20 25)
do
   BENCH_NPOW=$i cargo bench >> ../../result/RTX4090/wlc-con20-25.txt
done

# git clone https://github.com/speakspeak/cuZK.git experiment/baseline/cuZK
cd ../../cuZK/test
make msmb


for i in $(seq 20 25)
do
   ./msmtestb $i >> ../../result/RTX4090/cuZK20-25.txt
done

