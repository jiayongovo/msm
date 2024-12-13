#ifndef ED_BLS12_381_HPP
#define ED_BLS12_381_HPP

#ifdef __NVCC__
#include <cstdint>

namespace device {
#define TO_CUDA_T(limb64) (uint32_t)((limb64) & 0xFFFFFFFF), (uint32_t)((limb64) >> 32)

// Twisted Edwards 曲线参数
// q = 52435875175126190479447740508185965837690552500527637822603658699938581184513
// r = 6554484396890773809930967563523245729705921265872317281365359162392183254199

// 基域素数 q
static __device__ __constant__ const uint32_t TW_EDWARDS_BLS12_381_P[12] = {
    TO_CUDA_T(0xFFFFFFFF), TO_CUDA_T(0x00000001),
    TO_CUDA_T(0x00000000), TO_CUDA_T(0x00000000),
    TO_CUDA_T(0x00000000), TO_CUDA_T(0x00000000),
    TO_CUDA_T(0x00000000), TO_CUDA_T(0x00000000),
    TO_CUDA_T(0x00000000), TO_CUDA_T(0x00000000),
    TO_CUDA_T(0x00000000), TO_CUDA_T(0x00000000)
};

// 模数 RR = (1 << 768) % q
static __device__ __constant__ const uint32_t TW_EDWARDS_BLS12_381_RR[12] = {
    TO_CUDA_T(0x...), // 请根据实际计算结果填入
    TO_CUDA_T(0x...),
    // ...
    TO_CUDA_T(0x...)
};

// 单位元 ONE = (1 << 384) % q
static __device__ __constant__ const uint32_t TW_EDWARDS_BLS12_381_one[12] = {
    TO_CUDA_T(0x...), // 请根据实际计算结果填入
    TO_CUDA_T(0x...),
    // ...
    TO_CUDA_T(0x...)
};

// 蒙哥马利乘法常量 M0 = -q^{-1} mod 2^32
static __device__ __constant__ const uint32_t TW_EDWARDS_BLS12_381_M0 = 0xfffcfffd; // 根据 q 重新计算

// 子群阶 r
static __device__ __constant__ const uint32_t TW_EDWARDS_BLS12_381_r[8] = {
    TO_CUDA_T(0xffffffff00000001), TO_CUDA_T(0x53bda402fffe5bfe),
    TO_CUDA_T(0x3339d80809a1d805), TO_CUDA_T(0x73eda753299d7d48)
};

// 子群阶 r 的蒙哥马利常数 (1 << 512) % r
static __device__ __constant__ const uint32_t TW_EDWARDS_BLS12_381_rRR[8] = {
    TO_CUDA_T(0xc999e990f3f29c6d), TO_CUDA_T(0x2b6cedcb87925c23),
    TO_CUDA_T(0x05d314967254398f), TO_CUDA_T(0x0748d9d99f59ff11)
};

// 子群阶 r 的单位元 (1 << 256) % r
static __device__ __constant__ const uint32_t TW_EDWARDS_BLS12_381_rone[8] = {
    TO_CUDA_T(0x00000001fffffffe), TO_CUDA_T(0x5884b7fa00034802),
    TO_CUDA_T(0x998c4fefecbc4ff5), TO_CUDA_T(0x1824b159acc5056f)
};

// 子群阶的蒙哥马利乘法常数
static __device__ __constant__ const uint32_t TW_EDWARDS_BLS12_381_m0 = 0xffffffff;
}

#ifdef __CUDA_ARCH__   // device-side field types
#include "mont_t.cuh"
// 基于蒙哥马利乘法的字段类型
typedef mont_t<384, device::TW_EDWARDS_BLS12_381_P, device::TW_EDWARDS_BLS12_381_M0,
              device::TW_EDWARDS_BLS12_381_RR, device::TW_EDWARDS_BLS12_381_one> fp_t;

typedef mont_t<256, device::TW_EDWARDS_BLS12_381_r, device::TW_EDWARDS_BLS12_381_m0,
              device::TW_EDWARDS_BLS12_381_rRR, device::TW_EDWARDS_BLS12_381_rone> fr_t;
#endif // __CUDA_ARCH__

#endif // ED_BLS12_381_HPP