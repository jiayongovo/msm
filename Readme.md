### GPU Implemetation of MSM 
这份代码是哈尔滨工业大学学生的毕业设计，参考[zprize](https://github.com/z-prize/prize-gpu-fpga-msm), [wlc_msm](https://github.com/dunkirkturbo/wlc_msm), [cuzk](https://github.com/speakspeak/cuZK/tree/master) and [gzkp](https://dl.acm.org/doi/10.1145/3575693.3575711)
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

#### test

```shell

# cuzk
cd ../../cuZK/test
make msmb

# submission-msm-gpu Yrrid

# z-prize-msm-gpu   MatterLab

# wlc_msm (381-xyzz-bal、381-xyzz-con)

```
#### 实验复现
本仓库提供一些复现脚本用于辅助复现
##### 多批 MSM 实验 
在BLS12-381上跑规模在2^17-2^23的MSM计算，批次为 1，2，4，8，12，16
```shell
sh /experiment/multi_batches/multi_batches.sh   
# 结果在 /experiment/multi_batches/result 下

```

##### 预计算实验
在BLS12-381上跑规模在2^17-2^24的MSM计算，预计算间隔为 1，2，4，8，12，16
```shell
sh /experiment/precompute/precompute.sh
# 需要修改 sppark/msm/pippenger.cuh 的 FREQUENCY = 1,2,4,8,12,16
# 结果在 /experiment/precompute/result 下
# 论文绘图
python /experiment/precompute/plot.py 

```


##### 基线对比实验
和 cuzk、wlc-msm、GZKP、Yrrid、MatterLab 的对比实验



##### 负载平衡实验
