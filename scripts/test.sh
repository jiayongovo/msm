#!/bin/bash

echo >reports/test.txt
for ((i = 1; i <= 5; i++)); do
    TEST_NPOW=1 RANDOM_TEST=mixed cargo test >>reports/test.txt
done
