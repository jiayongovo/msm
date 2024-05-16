#!/bin/bash
for i in $(seq 10 23)
do
    for j in 1 2 4 8 16; do
        TEST_NPOW=$i  BENCHES=$j cargo test --release
    done
done


