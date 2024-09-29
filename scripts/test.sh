#!/bin/bash

param1=${1:-17}
param2=${2:-1}
param3=${3:-true}

cargo build --release
TEST_NPOW=$param1 BENCHES=$param2 RANDOM_TEST=$param3 cargo test