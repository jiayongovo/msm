### GPU Implemetation of MSM 
This is the senior graduation project of Harbin Institute of Technology, referring to the designs of [zprize](https://github.com/z-prize/prize-gpu-fpga-msm), [wlc_msm](https://github.com/dunkirkturbo/wlc_msm), [cuzk](https://github.com/speakspeak/cuZK/tree/master) and [gzkp](https://dl.acm.org/doi/10.1145/3575693.3575711)
#### build
```
cargo build --release # default for bls12_381
# change curve => find build.rs for bls12_377
# change bench/msm.rs | tests/msm.rs use bls12_377

# for bench
cargo bench
# for test
cargo test --release 
```

test

```shell

# cuzk
cd test
make
./msmtestb 20 

# submission-msm-gpu Yrrid

# z-prize-msm-gpu   MatterLab

# wlc_msm (381-xyzz-bal、381-xyzz-con)

```