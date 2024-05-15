#!/bin/bash

for i in 14 16 18 20 22 24 26;
do
   BENCH_NPOW=$i cargo bench >> experiment/baseline/result/V100/jy-msm.txt
done