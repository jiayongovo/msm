#!/bin/bash
rm experiment/test/result/test.log
for i in $(seq 15 25)
do
    for j in 1 2 4 8 12 16; do
        TEST_NPOW=$i  BENCHES=$j cargo test --release -- --nocapture >> experiment/test/result/test.log
    done
done


