#!/bin/bash
for i in $(seq 17 24)
do
   m=1
   echo "Running M = $m iteration $i"
   BENCH_NPOW=$i cargo bench >> results_$m.txt
done


