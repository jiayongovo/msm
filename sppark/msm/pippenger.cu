// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <cuda.h>


#ifndef WARP_SZ
# define WARP_SZ 32
#endif

#ifndef NTHREADS
# define NTHREADS 64
#endif
#if NTHREADS < 32 || (NTHREADS & (NTHREADS-1)) != 0
# error "bad NTHREADS value"
#endif

constexpr static int log2(int n)
{   int ret=0; while (n>>=1) ret++; return ret;   }

static const int NTHRBITS = log2(NTHREADS);

#ifndef NBITS
# define NBITS 253
#endif
#ifndef WBITS
# define WBITS 16
#endif
#define NWINS 16  // ((NBITS+WBITS-1)/WBITS)   // ceil(NBITS/WBITS)

#ifndef LARGE_L1_CODE_CACHE
# define LARGE_L1_CODE_CACHE 0
#endif

__global__
void pre_compute(affine_t* pre_points, size_t npoints);

__global__
void jy_pre_compute(affine_t* pre_points, size_t npoints);


__global__
void process_scalar_1(uint16_t* scalar, uint32_t* scalar_tuple,
                      uint32_t* d_scalar_map, uint32_t* point_idx, size_t npoints);
__global__
void jy_process_scalar_1(uint16_t* scalar, uint32_t* scalar_tuple,
                         uint32_t* point_idx, size_t npoints);

__global__
void process_scalar_2(uint32_t* scalar_tuple_out,
                      uint16_t* bucket_idx, size_t npoints);

__global__
void bucket_inf(bucket_t *buckets);

// v1.1
__global__
void bucket_acc(uint32_t* scalar_tuple_out, uint16_t* bucket_idx, uint32_t* point_idx_out,
                affine_t* pre_points, bucket_t *buckets_pre,
                uint16_t* bucket_idx_pre_vector, uint16_t* bucket_idx_pre_used,
                uint32_t* bucket_idx_pre_offset, size_t npoints);

__global__
void bucket_acc_2(bucket_t *buckets_pre, uint16_t* bucket_idx_pre_vector, uint16_t* bucket_idx_pre_used,
                  uint32_t* bucket_idx_pre_offset, bucket_t *buckets, uint32_t upper_tnum, size_t npoints);

__global__
void bucket_agg_1(bucket_t *buckets);

__global__
void bucket_agg_2(bucket_t *buckets);

__global__
void recursive_sum(bucket_t *buckets, bucket_t *res);


#ifdef __CUDA_ARCH__

#include <cooperative_groups.h>

static __shared__ bucket_t bucket_acc_smem[NTHREADS * 2];

// Transposed scalar_t
class scalar_T {
    uint32_t val[sizeof(scalar_t)/sizeof(uint32_t)][WARP_SZ];

public:
    __device__ uint32_t& operator[](size_t i)              { return val[i][0]; }
    __device__ const uint32_t& operator[](size_t i) const  { return val[i][0]; }
    __device__ scalar_T& operator=(const scalar_t& rhs)
    {
        for (size_t i = 0; i < sizeof(scalar_t)/sizeof(uint32_t); i++)
            val[i][0] = rhs[i];
        return *this;
    }
};

class scalars_T {
    scalar_T* ptr;

public:
    __device__ scalars_T(void* rhs) { ptr = (scalar_T*)rhs; }
    __device__ scalar_T& operator[](size_t i)
    {   return *(scalar_T*)&(&ptr[i/WARP_SZ][0])[i%WARP_SZ];   }
    __device__ const scalar_T& operator[](size_t i) const
    {   return *(const scalar_T*)&(&ptr[i/WARP_SZ][0])[i%WARP_SZ];   }
};

constexpr static __device__ int dlog2(int n)
{   int ret=0; while (n>>=1) ret++; return ret;   }


#if WBITS==16
template<class scalar_t>
static __device__ int get_wval(const scalar_t& d, uint32_t off, uint32_t bits)
{
    uint32_t ret = d[off/32];
    return (ret >> (off%32)) & ((1<<bits) - 1);
}
#else
template<class scalar_t>
static __device__ int get_wval(const scalar_t& d, uint32_t off, uint32_t bits)
{
    uint32_t top = off + bits - 1;
    uint64_t ret = ((uint64_t)d[top/32] << 32) | d[off/32];

    return (int)(ret >> (off%32)) & ((1<<bits) - 1);
}
#endif


static __device__ uint32_t max_bits(uint32_t scalar)
{
    uint32_t max = 32;
    return max;
}

static __device__ bool test_bit(uint32_t scalar, uint32_t bitno)
{
    if (bitno >= 32)
        return false;
    return ((scalar >> bitno) & 0x1);
}

template<class bucket_t>
static __device__ void mul(bucket_t& res, const bucket_t& base, uint32_t scalar)
{
    res.inf();

    bool found_one = false;
    uint32_t mb = max_bits(scalar);
    for (int32_t i = mb - 1; i >= 0; --i)
    {
        if (found_one)
        {
            res.add(res);
        }

        if (test_bit(scalar, i))
        {
            found_one = true;
            res.add(base);
        }
    }
}

__global__
void pre_compute(affine_t* pre_points, size_t npoints) {
    // NWINS * config.N  NTHREADS
    // blockDim.x 表示每个线程块中的线程数量
    // gridDim.x 表示网格中线程块的数量
    // blockIdx.x 表示当前线程块的索引，blockDim.x 表示每个线程块中的线程数量，threadIdx.x 表示当前线程在其线程块中的索引。
    const uint32_t tnum = blockDim.x * gridDim.x;
    const uint32_t tid = blockIdx.x * blockDim.x + threadIdx.x;

    bucket_t Pi_xyzz;
    for (uint32_t i = tid; i < npoints; i += tnum) {
        affine_t* Pi = pre_points + i;
        Pi_xyzz = *Pi;
        for (int j = 1; j < 7; j++) {
            Pi = Pi + npoints;
            Pi_xyzz.dbl();

            Pi_xyzz.xyzz_to_affine(*Pi);
        }
    }
}

// jy_msm 点预计算
__global__
void jy_pre_compute(affine_t* pre_points, size_t npoints) {
    const uint32_t tnum = blockDim.x * gridDim.x;
    const uint32_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    const uint32_t num = (NWINS % 2 ==0 ? NWINS - 2 : NWINS - 1) / 2 ;

    bucket_t Pi_xyzz;
    for (uint32_t i = tid; i < npoints; i += tnum) {
        affine_t* Pi = pre_points + i;
        Pi_xyzz = *Pi;
        for (int j = 1; j <= num; j++) {
            uint32_t pow = 2 * j * WBITS;
            Pi = Pi + npoints;
             for(uint32_t k=0;k<pow;k++)
                Pi_xyzz.dbl();
            Pi_xyzz.xyzz_to_affine(*Pi);
        }
    }
}

// 把输进来的scalar看作是u16
__global__
void process_scalar_1(uint16_t* scalar, uint32_t* scalar_tuple,
                      uint32_t* d_scalar_map, uint32_t* point_idx, size_t npoints) {

    const uint32_t tnum = blockDim.x * gridDim.x;
    const uint32_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    // 每个线程分配到一个标量的划分
    // 第 i 个标量
    for (int i = tid; i < npoints; i += tnum) {
        // 因为把他看作是u16 因此偏移需要加 2^16 * i
        // 当前线程处理的起始标量 ki0
        uint16_t* cur_scalar_ptr = scalar + (i << 4);
        // 获得标量值
        uint32_t cur_scalar = (uint32_t)(*cur_scalar_ptr);  // uint32_t instead of uint16_t, specifically for 0x10000
        // 根据 ki0 查找获得浮点形式 kij
        //
        scalar_tuple[i] = d_scalar_map[cur_scalar];

        point_idx[i] = i;
        // j 放进去
        for (int j = i + npoints; j < NWINS * npoints; j += npoints) {
            // 获取下一个呗
            cur_scalar_ptr += 1;
            cur_scalar = (uint32_t)(*(cur_scalar_ptr));
            // 获得之前处理的最低位
            cur_scalar += (scalar_tuple[j - npoints] & 1);
            scalar_tuple[j] = d_scalar_map[cur_scalar];

            point_idx[j] = i;
        }
    }

}
// 把输进来的scalar看作是u16
// 只支持窗口大小为 16 的...
__global__
void jy_process_scalar_1(uint16_t* scalar, uint32_t* scalar_tuple,
                      uint32_t* point_idx, size_t npoints) {

    const uint32_t tnum = blockDim.x * gridDim.x;
    const uint32_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    // 每个线程分配到一个标量的划分
    for (int i = tid; i < npoints; i += tnum) {
        // 因为把他看作是u16 因此偏移需要加 2^16 * i
        // 当前线程处理的起始标量 ki0
        uint16_t* cur_scalar_ptr = scalar + (i << 4);
        // 获得标量值
        uint16_t cur_scalar = *cur_scalar_ptr;  // uint32_t instead of uint16_t, specifically for 0x10000
        uint32_t cur_sign = (cur_scalar >> (WBITS - 1)) & 1;
        cur_scalar = cur_sign == 1 ? 1<<WBITS - cur_scalar : cur_scalar;
        scalar_tuple[i] = cur_scalar << 1 | cur_sign;

        point_idx[i] = i;
        // j 放进去
        for (int j = i + npoints; j < NWINS * npoints; j += npoints) {
            // 获取下一个呗
            cur_scalar_ptr += 1;
            uint16_t cur_scalar = *cur_scalar_ptr;
            // 获得之前处理的最低位
            cur_scalar += (scalar_tuple[j - npoints] & 1);
            uint32_t cur_sign = (cur_scalar >> (WBITS - 1)) & 1;
            cur_scalar = cur_sign == 1 ? 1<<WBITS - cur_scalar : cur_scalar;
            point_idx[j] = i;
            scalar_tuple[i] = cur_scalar << 1 | cur_sign;
        }
    }

}
// bucket_idx_ptr 第i个窗口第j个值对应的就是排序后scalar的值
__global__
void process_scalar_2(uint32_t* scalar_tuple_out,
                      uint16_t* bucket_idx, size_t npoints) {
    // dim3(NWINS, config.N), NTHREADS
    // 线程总数
    // blockDim.x 每个 block 中的线程数量 NTHREADS
    // gridDim.y  grid 在 y 维度上的大小 config.N
    // 每加一个 tnum  线程块处理的总数
    const uint32_t tnum = blockDim.x * gridDim.y;
    // 全局索引
    // blockIdx.y 当前线程所在线程块在 y 方向哪里
    // blockDim.x 每个 block 中的线程数量 NTHREADS
    // 当前窗口的第 tid 个线程
    const uint32_t tid = blockIdx.y * blockDim.x + threadIdx.x;
    // 当前线程在 block x 方向上哪里  其实就是第几个 windows
    const uint32_t bid = blockIdx.x;

    // 当前线程处理第几个 windows
    // 窗口内对应的桶 idx 和排序处理后的 scalars
    uint16_t* bucket_idx_ptr = bucket_idx + npoints * bid;
    uint32_t* scalar_tuple_out_ptr = scalar_tuple_out + npoints * bid;
    // 每个线程处理当前窗口内负责的任务
    for (uint32_t i = tid; i < npoints; i += tnum) {
        // 取前 16 位
        // 桶索引对应的值是相应的scalar的前16位
        // 反正就是
        bucket_idx_ptr[i] = scalar_tuple_out_ptr[i] >> 16;
    }
}

// total_bucket_num = NWINS * (1 << (WBITS - 2))
__global__
void bucket_inf(bucket_t *buckets) {
    const uint32_t tnum = blockDim.x * gridDim.y;
    const uint32_t tid = blockIdx.y * blockDim.x + threadIdx.x;
    const uint32_t bid = blockIdx.x;

    const uint32_t bucket_num =  1 << (WBITS - 2);
    bucket_t* buckets_ptr = buckets + bucket_num * bid;

    for (uint32_t i = tid; i < bucket_num; i += tnum) {
        buckets_ptr[i].inf();
    }
}

// v1.1
__global__
void bucket_acc(uint32_t* scalar_tuple_out, uint16_t* bucket_idx, uint32_t* point_idx_out,
                affine_t* pre_points, bucket_t *buckets_pre,
                uint16_t* bucket_idx_pre_vector, uint16_t* bucket_idx_pre_used,
                uint32_t* bucket_idx_pre_offset, size_t npoints) {
    // 线程总数
    // 每增加一个 tnum 线程负责的任务
    const uint32_t tnum = blockDim.x * gridDim.y;
    // 线程块内部的一个 idx
    const uint32_t tid_inner = threadIdx.x;
    // 当前窗口的第 tid 个线程
    const uint32_t tid = blockIdx.y * blockDim.x + tid_inner;
    // 第 bid 个窗口 0 to NWINS - 1
    const uint32_t bid = blockIdx.x;
    // tnum + 2 ^(WBITS-2)
    const uint32_t buffer_len = tnum + (1 << (WBITS - 2));
    // 第 bid 个窗口对应的scalar标量
    uint32_t* scalar_tuple_out_ptr = scalar_tuple_out + npoints * bid;
    // 第 bid 个窗口对应的 bucket_idx
    uint16_t* bucket_idx_ptr = bucket_idx + npoints * bid;
    // 第 bid 个窗口对应的 点索引
    uint32_t* point_idx_out_ptr = point_idx_out + npoints * bid;
    // 和负载平衡相关
    // 只使用一个config.N * NTHREADS 个线程 处理每个窗口
    // 很明显，每个窗口分配的buffer是 buffer_len
    // 第 bid 个窗口对应的 bucket_pre
    bucket_t* buckets_pre_ptr = buckets_pre + buffer_len * bid;
    // 第 bid 个窗口对应的 bucket_index
    uint16_t* bucket_idx_pre_vector_ptr = bucket_idx_pre_vector + buffer_len * bid;
    // 第 bid 个窗口对应的 bucket_used
    uint16_t* bucket_idx_pre_used_ptr = bucket_idx_pre_used + tnum * bid;
    // 第 bid 个窗口对应的 bucket_offset
    uint32_t* bucket_idx_pre_offset_ptr = bucket_idx_pre_offset + tnum * bid;

    // 每个线程分配的任务 总数是tnum
    // 每个窗口内 每个线程处理的点数
    const uint32_t step_len = (npoints + tnum - 1) / tnum;
    // 首先确定边界范围，当然需要进一步调整
    uint32_t s = step_len * tid;
    uint32_t e = s + step_len;
    if (s >= npoints) {
        bucket_idx_pre_used_ptr[tid] = 0;
        return;
    }
    if (e >= npoints) e = npoints;

    uint16_t pre_bucket_idx = 0x8000;   // not exist
    // 线程块内部共享内存
    bucket_acc_smem[tid_inner * 2 + 1].inf(); // 设置为inf

    // 根据 scalar 值获得 offset
    // 第 s 个 bucket_idx 其实就是scalar i,j_bar
    // salar 是 odd 因此它对应的桶是 + 1 / 2
    uint32_t offset = tid + ((bucket_idx_ptr[s] + 1) >> 1);
    bucket_idx_pre_offset_ptr[tid] = offset;
    uint32_t unique_num = 0;
    // 每个线程在每个窗口下处理的点
    // process [s, e)
    for (uint32_t i = s; i < e; i++) {
        // todo 感觉就是在格式里面嵌入了新东西
        // 获得指数和剩余dbl次数
        uint32_t power_of_2 = (scalar_tuple_out_ptr[i] >> 8) & 0x0f;
        uint32_t dbl_time = (scalar_tuple_out_ptr[i] >> 12) & 0x0f;

        // 当前桶索引 其实就是 ai.ODD
        uint16_t cur_bucket_idx = bucket_idx_ptr[i];

        if (cur_bucket_idx != pre_bucket_idx && (unique_num++)) {
            // 因为unique_num ++ 了 索引就是 i != s 的时候 ,unique_num 起步等于2
            buckets_pre_ptr[offset + unique_num - 2] = bucket_acc_smem[tid_inner * 2 + 1];
            bucket_idx_pre_vector_ptr[offset + unique_num - 2] = (pre_bucket_idx + 1) >> 1;
            bucket_acc_smem[tid_inner * 2 + 1].inf();
        }
        pre_bucket_idx = cur_bucket_idx;
        // 查预计算表获得点值
        bucket_acc_smem[tid_inner * 2] = pre_points[point_idx_out_ptr[i] + power_of_2 * npoints];
        for (uint32_t j = 0; j < dbl_time; j++) {
            bucket_acc_smem[tid_inner * 2].dbl();
        }
        // 根据scalar的符号判断是否需要进行取反
        if (scalar_tuple_out_ptr[i] & 0x01) {
            bucket_acc_smem[tid_inner * 2].neg(true);
        }
        bucket_acc_smem[tid_inner * 2 + 1].add(bucket_acc_smem[tid_inner * 2]);
    }
    buckets_pre_ptr[offset + unique_num - 1] = bucket_acc_smem[tid_inner * 2 + 1];
    bucket_idx_pre_vector_ptr[offset + unique_num - 1] = (pre_bucket_idx + 1) >> 1;
    bucket_idx_pre_used_ptr[tid] = unique_num;

}

// v1.1 (2^{14} THREADS)
// 利用二分搜索去找相应的buffer点进行聚合到相应桶里
__global__
void bucket_acc_2(bucket_t *buckets_pre, uint16_t* bucket_idx_pre_vector, uint16_t* bucket_idx_pre_used,
                  uint32_t* bucket_idx_pre_offset, bucket_t *buckets, uint32_t upper_tnum, size_t npoints) {
    const uint32_t tid_inner = threadIdx.x;
    const uint32_t tid = blockIdx.y * blockDim.x + tid_inner;
    const uint32_t bid = blockIdx.x;
    const uint32_t buffer_len = upper_tnum + (1 << (WBITS - 2));
    // dim3(NWINS, (1 << (WBITS - 2)) / NTHREADS), NTHREADS 不能直接求tnum了
    // upper_tnum = (uint32_t)(config.N * NTHREADS)
    bucket_t* buckets_pre_ptr = buckets_pre + buffer_len * bid;
    uint16_t* bucket_idx_pre_vector_ptr = bucket_idx_pre_vector + buffer_len * bid;
    uint16_t* bucket_idx_pre_used_ptr = bucket_idx_pre_used + upper_tnum * bid;
    uint32_t* bucket_idx_pre_offset_ptr = bucket_idx_pre_offset + upper_tnum * bid;
    bucket_t* buckets_ptr = buckets + (1 << (WBITS - 2)) * bid;

    // 在每个窗口内查线程总数干的东西
    int left = 0, right = upper_tnum - 1;
    bool not_inf = false;
    uint32_t start_pos = 0;
    while (left <= right) {
        int mid = left + ((right - left) >> 1);
        uint16_t vector_used = bucket_idx_pre_used_ptr[mid];
        if (!vector_used) {
            right = mid - 1;
        } else {
            uint32_t vector_ptr = bucket_idx_pre_offset_ptr[mid];
            uint16_t min_idx = bucket_idx_pre_vector_ptr[vector_ptr];
            uint16_t max_idx = bucket_idx_pre_vector_ptr[vector_ptr + vector_used - 1];
            if (min_idx == (tid + 1)) {
                start_pos = mid;
                not_inf = true;
                right = mid - 1;
            } else if (min_idx > (tid + 1)) {
                right = mid - 1;
            } else if (max_idx < (tid + 1)) {
                left = mid + 1;
            } else {
                for (uint32_t i = vector_ptr + 1; i < vector_ptr + vector_used; i++) {
                    if (bucket_idx_pre_vector_ptr[i] == (tid + 1)) {
                        start_pos = mid;
                        not_inf = true;
                        break;
                    }
                }
                break;
            }
        }
    }
    bucket_acc_smem[tid_inner].inf();
    while (not_inf && start_pos < upper_tnum) {
        not_inf = false;
        // 找到对应的buffer了
        uint16_t vector_used = bucket_idx_pre_used_ptr[start_pos];
        uint32_t vector_ptr = bucket_idx_pre_offset_ptr[start_pos];
        for (uint32_t i = vector_ptr; i < vector_ptr + vector_used; i++) {
            if (bucket_idx_pre_vector_ptr[i] == (tid + 1)) {
                not_inf = true;
                // 把找到的点累加起来
                bucket_acc_smem[tid_inner].add(buckets_pre_ptr[i]);
                break;
            }
        }
        // 然后往前找
	    start_pos++;
    }
    // 最后存到相应的全局内存里
    buckets_ptr[tid] = bucket_acc_smem[tid_inner];  // can omit kerner `bucket_inf`

}

__global__
void bucket_agg_1(bucket_t *buckets) {
    // dim3(NWINS, config.N), NTHREADS
    const uint32_t tnum = blockDim.x * gridDim.y;
    const uint32_t tid = blockIdx.y * blockDim.x + threadIdx.x;
    const uint32_t bid = blockIdx.x;

    // 第 i 个窗口对应的桶值
    bucket_t* buckets_ptr = buckets + (1 << (WBITS - 2)) * bid;

    for (uint32_t j = tid; j < (1 << (WBITS - 5)); j += tnum) {
        uint32_t s = j << 3;
        bucket_t* Bi = buckets_ptr + 0x3fff - s;
        for (int i = 1; i < 8; i++) {
            (Bi - i)->add(*(Bi - i + 1));
        }
    }
}

__global__
void bucket_agg_2(bucket_t *buckets) {
    const uint32_t tnum = blockDim.x * gridDim.y;
    const uint32_t tid = blockIdx.y * blockDim.x + threadIdx.x;
    const uint32_t bid = blockIdx.x;

    bucket_t* buckets_ptr = buckets + (1 << (WBITS - 2)) * bid;

    for (uint32_t i = 3; i < 14; i++) {
        for (uint32_t k = tid; k < (1 << (WBITS - 3)); k += tnum) {
            uint32_t baseline = ((1 + (k >> i)) << (i + 1)) - (1 << i);
            uint32_t offset = k & ((1 << i) - 1);

            bucket_t* Bi = buckets_ptr + 0x3fff - (baseline - 1);
            bucket_t* Bj = Bi - (offset + 1);	// B + 0x3fff - (baseline + offset)

            Bj->add(*Bi);
        }
        cooperative_groups::this_grid().sync();
    }
}

__global__
void recursive_sum(bucket_t *buckets, bucket_t *res) {
    // dim3(NWINS, config.N), NTHREADS
    // res 为每个窗口对应的桶和 即算Qj
    const uint32_t tnum = blockDim.x * gridDim.y;
    const uint32_t tid = blockIdx.y * blockDim.x + threadIdx.x;
    const uint32_t bid = blockIdx.x;

    bucket_t* buckets_ptr = buckets + (1 << (WBITS - 2)) * bid;

    if (tid == 0) {
        res[bid] = *buckets_ptr;
    }
    // cooperative_groups::this_grid().sync();

    for (uint32_t j = 1 << (WBITS - 3); j > NTHREADS; j >>= 1) {
        for (uint32_t i = tid; i < j; i += tnum) {
            buckets_ptr[i].add(buckets_ptr[i + j]);
        }
        cooperative_groups::this_grid().sync();
    }
    for (uint32_t j = NTHREADS; j > WARP_SZ; j >>= 1) {
        if (tid < j) {
            buckets_ptr[tid].add(buckets_ptr[tid + j]);
        }
        cooperative_groups::this_thread_block().sync();
    }

    if (tid < WARP_SZ) {
        buckets_ptr[tid].add(buckets_ptr[tid + 32]);
        buckets_ptr[tid].add(buckets_ptr[tid + 16]);
        buckets_ptr[tid].add(buckets_ptr[tid + 8]);
        buckets_ptr[tid].add(buckets_ptr[tid + 4]);
        buckets_ptr[tid].add(buckets_ptr[tid + 2]);
        buckets_ptr[tid].add(buckets_ptr[tid + 1]);
    }
    if (tid == 0) {
        // 2Qj
        buckets_ptr->dbl();
        // -B1
        res[bid].neg(true);
        // 2Qj-B1
        res[bid].add(*buckets_ptr);
    }

    /*cooperative_groups::this_grid().sync();
    if (tid == 0 && bid == 0) {
    bucket_t check_res;
    check_res.inf();

    for (int i = 15; i > -1; i--) {
	for (int j = 0; j < 16; j++) {
	    check_res.add(check_res);
	}
	check_res.add(res[i]);
    }
    printf("\ncheck_2:\n");
    check_res.xyzz_print();
    }*/
}

#else

#include <cassert>
#include <vector>
using namespace std;

#include <util/exception.cuh>
#include <util/rusterror.h>
#include <util/thread_pool_t.hpp>
#include <util/host_pinned_allocator_t.hpp>


template<typename... Types>
inline void launch_coop(void(*f)(Types...),
                        dim3 gridDim, dim3 blockDim, cudaStream_t stream,
                        Types... args)
{
    void* va_args[sizeof...(args)] = { &args... };
    CUDA_OK(cudaLaunchCooperativeKernel((const void*)f, gridDim, blockDim,
                                        va_args, 0, stream));
}

class stream_t {
    cudaStream_t stream;
public:
    stream_t(int device)  {
        CUDA_OK(cudaSetDevice(device));
        cudaStreamCreateWithFlags(&stream, cudaStreamNonBlocking);
    }
    ~stream_t() { cudaStreamDestroy(stream); }
    inline operator decltype(stream)() { return stream; }
};


template<class bucket_t> class result_t_faster {
    bucket_t ret[NWINS];
public:
    result_t_faster() {}
    inline operator decltype(ret)&() { return ret; }
};

template<class T>
class device_ptr_list_t {
    vector<T*> d_ptrs;
public:
    device_ptr_list_t() {}
    ~device_ptr_list_t() {
        for(T *ptr: d_ptrs) {
            cudaFree(ptr);
        }
    }
    size_t allocate(size_t bytes) {
        T *d_ptr;
        CUDA_OK(cudaMalloc(&d_ptr, bytes));
        d_ptrs.push_back(d_ptr);
        return d_ptrs.size() - 1;
    }
    size_t size() {
        return d_ptrs.size();
    }
    T* operator[](size_t i) {
        if (i > d_ptrs.size() - 1) {
            CUDA_OK(cudaErrorInvalidDevicePointer);
        }
        return d_ptrs[i];
    }

};

// Pippenger MSM class
template<class bucket_t, class point_t, class affine_t, class scalar_t>
class pippenger_t {
public:
    typedef vector<result_t_faster<bucket_t>,
                   host_pinned_allocator_t<result_t_faster<bucket_t>>> result_container_t_faster;

private:
    size_t sm_count;
    bool init_done = false;
    device_ptr_list_t<affine_t> d_base_ptrs;
    // 预计算点
    device_ptr_list_t<affine_t> d_pre_points_ptrs;
    device_ptr_list_t<scalar_t> d_scalar_ptrs;
    device_ptr_list_t<bucket_t> d_bucket_ptrs;

    device_ptr_list_t<bucket_t> d_bucket_pre_ptrs;  // v1.1
    device_ptr_list_t<uint16_t> d_bucket_idx_pre_ptrs;  // v1.1
    device_ptr_list_t<uint32_t> d_bucket_idx_pre2_ptrs;  // v1.2

    device_ptr_list_t<bucket_t> d_res_ptrs;

    // GPU device number
    int device;

    // TODO: Move to device class eventually
    thread_pool_t *da_pool = nullptr;

public:
    // Default stream for operations
    stream_t default_stream;

    device_ptr_list_t<uint32_t> d_scalar_map;
    device_ptr_list_t<uint32_t> d_scalar_tuple_ptrs;
    device_ptr_list_t<uint32_t> d_point_idx_ptrs;
    // 符号变换
    device_ptr_list_t<uint32_t> jy_d_scalar_tuple_ptrs;
    device_ptr_list_t<uint32_t> jy_d_point_idx_ptrs;


    device_ptr_list_t<uint16_t> d_bucket_idx_ptrs;
    device_ptr_list_t<unsigned char> d_cub_ptrs;

    // Parameters for an MSM operation
    class MSMConfig {
        friend pippenger_t;
    public:
        size_t npoints;
        size_t N;
        size_t n;
    };

    pippenger_t() : default_stream(0) {
        device = 0;
    }

    pippenger_t(int _device, thread_pool_t *pool = nullptr)
        : default_stream(_device) {
        da_pool = pool;
        device = _device;
    }

    // Initialize instance. Throws cuda_error on error.
    void init() {
        printf("[Initialize GPU instance.]\n");
        if (!init_done) {
            CUDA_OK(cudaSetDevice(device));
            cudaDeviceProp prop;
            if (cudaGetDeviceProperties(&prop, 0) != cudaSuccess || prop.major < 7)
                CUDA_OK(cudaErrorInvalidDevice);
            sm_count = prop.multiProcessorCount;

            if (da_pool == nullptr) {
                da_pool = new thread_pool_t();
            }

            init_done = true;
        }
    }

    int get_device() {
        return device;
    }

    // Initialize parameters for a specific size MSM. Throws cuda_error on error.
    MSMConfig init_msm_faster(size_t npoints) {
        printf("[Begin init MSMConfig parameters]\n");
        init();

        MSMConfig config;
        config.npoints = npoints;
        config.n = (npoints+WARP_SZ-1) & ((size_t)0-WARP_SZ);
        // todo 可能需要修改
        config.N = (sm_count*256) / (NTHREADS*NWINS);
        size_t delta = ((npoints+(config.N)-1)/(config.N)+WARP_SZ-1) & (0U-WARP_SZ);
        config.N = (npoints+delta-1) / delta;
        printf("[MSMConfig] [npoints] [%d] [config.n] [%d] [delta] [%d] [Config.N] [%d]\n", npoints, config.n, delta, config.N);

        //        if(config.N % 2 == 1) config.N -= 1;
        return config;
    }

    size_t get_size_bases(MSMConfig& config) {
        return config.n * sizeof(affine_t);
    }
    size_t get_size_scalars(MSMConfig& config) {
        return config.n * sizeof(scalar_t);
    }
    // 窗口数乘以 2 ^ c - 2
    size_t get_size_buckets() {
        return sizeof(bucket_t) * NWINS * (1 << (WBITS - 2));
    }
    size_t get_size_buckets_pre(MSMConfig& config) { // v1.1
        return sizeof(bucket_t) * NWINS * (config.N * NTHREADS + (1 << (WBITS - 2)));
    }
    size_t get_size_bucket_idx_pre_vector(MSMConfig& config) {  // v1.1
        return sizeof(uint16_t) * NWINS * (config.N * NTHREADS + (1 << (WBITS - 2)));
    }
    size_t get_size_bucket_idx_pre_used(MSMConfig& config) {  // v1.1
        return sizeof(uint16_t) * config.N * NTHREADS * NWINS;
    }
    size_t get_size_bucket_idx_pre_offset(MSMConfig& config) {  // v1.2
        return sizeof(uint32_t) * config.N * NTHREADS * NWINS;
    }
    // 窗口数 * 桶大小
    size_t get_size_res() {
        return sizeof(bucket_t) * NWINS;
    }
    // (2^c + 1) * kij 的组合形式
    size_t get_size_scalar_map() {
        return ((1 << 16) + 1) * sizeof(uint32_t);
    }
    // scalar tuple 存放 kij  uint32 * NWINS * 点数
    size_t get_size_scalar_tuple(MSMConfig& config) {
        return config.n * sizeof(uint32_t) * NWINS;
    }
    size_t get_size_point_idx(MSMConfig& config) {
        return config.n * sizeof(uint32_t) * NWINS;
    }
    // 桶索引大小 点数 * 窗口数 * 窗口内桶索引
    size_t get_size_bucket_idx(MSMConfig& config) {
        return config.n * sizeof(uint16_t) * NWINS;
    }
    // 分配 cub 排序所需空间
    size_t get_size_cub_sort_faster(MSMConfig& config){
        uint32_t *d_scalar_tuple = nullptr;
        uint32_t *d_scalar_tuple_out = nullptr;
        uint32_t *d_point_idx = nullptr;
        uint32_t *d_point_idx_out = nullptr;
        void *d_temp = NULL;
        size_t temp_size = 0;
        cub::DeviceRadixSort::SortPairs(d_temp, temp_size,
                                        d_scalar_tuple, d_scalar_tuple_out,
                                        d_point_idx, d_point_idx_out, config.n, 0, 31);
        return temp_size;
    }

    result_container_t_faster get_result_container_faster() {
        result_container_t_faster res(1);
        return res;
    }

    // Allocate storage for bases on device. Throws cuda_error on error.
    // Returns index of the allocated base storage.
    // 7 是 原 points + 预计算的 六 组点
    size_t allocate_d_bases(MSMConfig& config) {
        printf("[Allocate d_bases] 7 * config.n * sizeof(affine_t) [%d]\n",7 * get_size_bases(config));
        return d_base_ptrs.allocate(7 * get_size_bases(config));
    }

    size_t allocate_d_pre_points(MSMConfig& config) {
        // 11 个窗口 => 2^2c  2^4c 2^6c 2^8c 2&10c  + 原来那组
        size_t num = (NWINS % 2 ==0 ? NWINS - 2 : NWINS - 1) / 2 + 1;
        return d_pre_points_ptrs.allocate( num * get_size_bases(config));
    }

    size_t allocate_d_scalars(MSMConfig& config) {
        printf("[Allocate d_scalars] config.n * sizeof(scalar_t) [%d]\n",get_size_scalars(config));
        return d_scalar_ptrs.allocate(get_size_scalars(config));
    }

    size_t allocate_d_buckets() {
        printf("[Allocate d_buckets] sizeof(bucket_t) * NWINS * (1 << (WBITS - 2)) [%d]\n",get_size_buckets());
        return d_bucket_ptrs.allocate(get_size_buckets());
    }
    // 静态 bucket
    size_t allocate_d_buckets_pre(MSMConfig& config) {  // v1.1
        printf("[Allocate d_buckets_pre] sizeof(bucket_t) * NWINS * (config.N * NTHREADS + (1 << (WBITS - 2))) [%d]\n",get_size_buckets_pre(config));
        return d_bucket_pre_ptrs.allocate(get_size_buckets_pre(config));
    }
    // buffer_index
    size_t allocate_d_bucket_idx_pre_vector(MSMConfig& config) {  // v1.1
        printf("[Allocate d_bucket_idx_pre_vector] sizeof(uint16_t) * NWINS * (config.N * NTHREADS + (1 << (WBITS - 2))) [%d]\n",get_size_bucket_idx_pre_vector(config));
        return d_bucket_idx_pre_ptrs.allocate(get_size_bucket_idx_pre_vector(config));
    }
    // buffer_used
    size_t allocate_d_bucket_idx_pre_used(MSMConfig& config) {  // v1.1
        printf("[Allocate d_bucket_idx_pre_used] sizeof(uint16_t) * config.N * NTHREADS * NWINS [%d]\n",get_size_bucket_idx_pre_used(config));
        return d_bucket_idx_pre_ptrs.allocate(get_size_bucket_idx_pre_used(config));
    }
    // buffer_offset
    size_t allocate_d_bucket_idx_pre_offset(MSMConfig& config) {  // v1.2
        printf("[Allocate d_bucket_idx_pre_offset] sizeof(uint32_t) * config.N * NTHREADS * NWINS [%d]\n",get_size_bucket_idx_pre_offset(config));
        return d_bucket_idx_pre2_ptrs.allocate(get_size_bucket_idx_pre_offset(config));
    }

    size_t allocate_d_res() {
        printf("[Allocate d_res] sizeof(bucket_t) * NWINS [%d]\n",get_size_res());
        return d_res_ptrs.allocate(get_size_res());
    }

    size_t allocate_d_scalar_map() {
        printf("[Allocate d_scalar_map] ((1 << 16) + 1) * sizeof(uint32_t) [%d]\n",get_size_scalar_map());
        return d_scalar_map.allocate(get_size_scalar_map());
    }

    size_t allocate_jy_d_scalar_tuple(MSMConfig& config) {
        return jy_d_scalar_tuple_ptrs.allocate(get_size_scalar_tuple(config));
    }
    size_t allocate_jy_d_scalar_tuple_out(MSMConfig& config) {
        return jy_d_scalar_tuple_ptrs.allocate(get_size_scalar_tuple(config));
    }
    size_t allocate_jy_d_point_idx(MSMConfig& config) {
        return jy_d_point_idx_ptrs.allocate(get_size_point_idx(config));
    }
    size_t allocate_jy_d_point_idx_out(MSMConfig& config) {
        return jy_d_point_idx_ptrs.allocate(get_size_point_idx(config));
    }
    size_t allocate_d_scalar_tuple(MSMConfig& config) {
        printf("[Allocate d_scalar_tuple] config.n * sizeof(uint32_t) * NWINS [%d]\n",get_size_scalar_tuple(config));
        return d_scalar_tuple_ptrs.allocate(get_size_scalar_tuple(config));
    }
    size_t allocate_d_scalar_tuple_out(MSMConfig& config) {
        printf("[Allocate d_scalar_tuple_out] config.n * sizeof(uint32_t) * NWINS [%d]\n",get_size_scalar_tuple(config));
        return d_scalar_tuple_ptrs.allocate(get_size_scalar_tuple(config));
    }

    size_t allocate_d_point_idx(MSMConfig& config) {
        printf("[Allocate d_point_idx] config.n * sizeof(uint32_t) * NWINS [%d]\n",get_size_point_idx(config));
        return d_point_idx_ptrs.allocate(get_size_point_idx(config));
//        return d_point_idx_ptrs.allocate(config.n * sizeof(uint32_t));
    }
    size_t allocate_d_point_idx_out(MSMConfig& config) {
        printf("[Allocate d_point_idx_out] config.n * sizeof(uint32_t) * NWINS [%d]\n",get_size_point_idx(config));
        return d_point_idx_ptrs.allocate(get_size_point_idx(config));
    }
    // 分配桶索引空间
    size_t allocate_d_bucket_idx(MSMConfig& config) {
        printf("[Allocate d_bucket_idx] config.n * sizeof(uint16_t) * NWINS [%d]\n",get_size_bucket_idx(config));
        return d_bucket_idx_ptrs.allocate(get_size_bucket_idx(config));
    }

    size_t allocate_d_cub_sort_faster(MSMConfig& config) {
        printf("[Allocate d_cub_sort_faster WARN Change] config.n * sizeof(uint16_t) * NWINS [%d]\n",get_size_cub_sort_faster(config));
        return d_cub_ptrs.allocate(get_size_cub_sort_faster(config));
    }

    // Transfer bases to device. Throws cuda_error on error.
    void transfer_bases_to_device(MSMConfig& config, size_t d_bases_idx, const affine_t points[],
                                  size_t ffi_affine_sz = sizeof(affine_t),
                                  cudaStream_t s = nullptr) {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        affine_t *d_points = d_base_ptrs[d_bases_idx];
        CUDA_OK(cudaSetDevice(device));
        if (ffi_affine_sz != sizeof(*d_points))
            CUDA_OK(cudaMemcpy2DAsync(d_points, sizeof(*d_points),
                                      points, ffi_affine_sz,
                                      ffi_affine_sz, config.npoints,
                                      cudaMemcpyHostToDevice, stream));
        else
            CUDA_OK(cudaMemcpyAsync(d_points, points, config.npoints*sizeof(*d_points),
                                    cudaMemcpyHostToDevice, stream));
    }

    // Transfer scalars to device. Throws cuda_error on error.
    void transfer_scalars_to_device(MSMConfig& config,
                                    size_t d_scalars_idx, const scalar_t scalars[],
                                    cudaStream_t s = nullptr) {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        scalar_t *d_scalars = d_scalar_ptrs[d_scalars_idx];
        CUDA_OK(cudaSetDevice(device));
        CUDA_OK(cudaMemcpyAsync(d_scalars, scalars, config.npoints*sizeof(*d_scalars),
                                cudaMemcpyHostToDevice, stream));
    }


    void transfer_res_to_host_faster(result_container_t_faster &res, size_t d_res_idx,
                                  cudaStream_t s = nullptr) {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        bucket_t *d_res = d_res_ptrs[d_res_idx];
        CUDA_OK(cudaSetDevice(device));
        CUDA_OK(cudaMemcpyAsync(res[0], d_res, sizeof(res[0]),
                                cudaMemcpyDeviceToHost, stream));
    }

    void transfer_scalar_map_to_device(size_t d_scalar_map_idx, const uint32_t scalar_map[],
                                       cudaStream_t s = nullptr) {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        uint32_t *d_smap = d_scalar_map[d_scalar_map_idx];
        CUDA_OK(cudaSetDevice(device));
        CUDA_OK(cudaMemcpyAsync(d_smap, scalar_map, ((1 << 16) + 1)*sizeof(uint32_t),
                                cudaMemcpyHostToDevice, stream));
    }

    void synchronize_stream() {
        CUDA_OK(cudaSetDevice(device));
        CUDA_OK(cudaStreamSynchronize(default_stream));
    }

    void launch_kernel_init(MSMConfig& config,
                            size_t d_points_sn, cudaStream_t s = nullptr) {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        affine_t *d_points = d_base_ptrs[d_points_sn];

        CUDA_OK(cudaSetDevice(device));
        printf("[pre_compute] NWINS * config.N  NTHREADS \n");
        launch_coop(pre_compute, NWINS * config.N, NTHREADS, stream,
                    d_points, config.npoints);
    }

    void launch_kernel_pre_compute_init(MSMConfig& config,
                                        size_t d_pre_points_sn, cudaStream_t s = nullptr) {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        affine_t *d_pre_points = d_pre_points_ptrs[d_pre_points_sn];

        CUDA_OK(cudaSetDevice(device));
        launch_coop(jy_pre_compute, NWINS * config.N, NTHREADS, stream,
                    d_pre_points, config.npoints);
    }
    // conversion of the sub-scalars (table lookups).
    // d_scalars_sn 标量地址
    // d_scalar_tuples_sn 标量元组地址
    // 查找表地址
    // 点索引地址
    void launch_process_scalar_1(MSMConfig& config,
                                 size_t d_scalars_sn, size_t d_scalar_tuples_sn,
                                 size_t d_scalar_map_sn, size_t d_point_idx_sn,
                                 cudaStream_t s = nullptr) {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        uint16_t* d_scalars = (uint16_t*)d_scalar_ptrs[d_scalars_sn];
        uint32_t* d_scalar_tuple = d_scalar_tuple_ptrs[d_scalar_tuples_sn];
        uint32_t* d_smap = d_scalar_map[d_scalar_map_sn];
        uint32_t* d_point_idx = d_point_idx_ptrs[d_point_idx_sn];

        CUDA_OK(cudaSetDevice(device));
        launch_coop(process_scalar_1, NWINS * config.N, NTHREADS, stream,
                    d_scalars, d_scalar_tuple, d_smap, d_point_idx, config.npoints);
    }

    void launch_jy_process_scalar_1(MSMConfig& config,
                                 size_t d_scalars_sn, size_t jy_d_scalar_tuples_sn,
                                 size_t jy_d_point_idx_sn,
                                 cudaStream_t s = nullptr) {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        uint16_t* d_scalars = (uint16_t*)d_scalar_ptrs[d_scalars_sn];
        uint32_t* d_scalar_tuple = jy_d_scalar_tuple_ptrs[jy_d_scalar_tuples_sn];
        uint32_t* d_point_idx = jy_d_point_idx_ptrs[jy_d_point_idx_sn];

        CUDA_OK(cudaSetDevice(device));
        launch_coop(jy_process_scalar_1, NWINS * config.N, NTHREADS, stream,
                    d_scalars, d_scalar_tuple, d_point_idx, config.npoints);
    }

    // 根据排序后的scalar元组，获得桶idx
    void launch_process_scalar_2(MSMConfig& config,
                                 size_t d_scalar_tuples_out_sn, size_t d_bucket_idx_sn,
                                 cudaStream_t s = nullptr) {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        uint32_t* d_scalar_tuple_out = d_scalar_tuple_ptrs[d_scalar_tuples_out_sn];
        uint16_t* d_bucket_idx = d_bucket_idx_ptrs[d_bucket_idx_sn];

        CUDA_OK(cudaSetDevice(device));
        // NWINS 是网格在 x 维度上的大小，config.N 是网格在 y 维度上的大小。
        // 看成是二维的即可
        launch_coop(process_scalar_2, dim3(NWINS, config.N), NTHREADS, stream,
                    d_scalar_tuple_out, d_bucket_idx, config.npoints);
    }

    void launch_bucket_inf(MSMConfig& config, size_t d_buckets_sn, cudaStream_t s = nullptr) {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        bucket_t* d_buckets = d_bucket_ptrs[d_buckets_sn];

        CUDA_OK(cudaSetDevice(device));
        launch_coop(bucket_inf, dim3(NWINS, config.N), NTHREADS, stream, d_buckets);
    }

    void launch_bucket_acc(MSMConfig& config,
                           size_t d_scalar_tuples_out_sn, size_t d_bucket_idx_sn,
                           size_t d_point_idx_out_sn, size_t d_points_sn, size_t d_buckets_sn,
                           size_t d_buckets_pre_sn, size_t d_bucket_idx_pre_vector_sn,
                           size_t d_bucket_idx_pre_used_sn, size_t d_bucket_idx_pre_offset_sn,
                           cudaStream_t s = nullptr) {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        uint32_t* d_scalar_tuple_out = d_scalar_tuple_ptrs[d_scalar_tuples_out_sn];
        uint16_t* d_bucket_idx = d_bucket_idx_ptrs[d_bucket_idx_sn];
        uint32_t* d_point_idx_out = d_point_idx_ptrs[d_point_idx_out_sn];
        affine_t* d_points = d_base_ptrs[d_points_sn];
        bucket_t* d_buckets = d_bucket_ptrs[d_buckets_sn];
        bucket_t* d_buckets_pre = d_bucket_pre_ptrs[d_buckets_pre_sn];
        uint16_t* d_bucket_idx_pre_vector = d_bucket_idx_pre_ptrs[d_bucket_idx_pre_vector_sn];
        uint16_t* d_bucket_idx_pre_used = d_bucket_idx_pre_ptrs[d_bucket_idx_pre_used_sn];
        uint32_t* d_bucket_idx_pre_offset = d_bucket_idx_pre2_ptrs[d_bucket_idx_pre_offset_sn];

        CUDA_OK(cudaSetDevice(device));
        // accumulate parts of the buckets into static buffers.
        launch_coop(bucket_acc, dim3(NWINS, config.N), NTHREADS, stream,
                    d_scalar_tuple_out, d_bucket_idx, d_point_idx_out,
                    d_points, d_buckets_pre,
                    d_bucket_idx_pre_vector, d_bucket_idx_pre_used,
                    d_bucket_idx_pre_offset, config.npoints);
        // aggregate the buffered points into the buckets.
        bucket_acc_2<<<dim3(NWINS, (1 << (WBITS - 2)) / NTHREADS), NTHREADS, 0, stream>>>(
                d_buckets_pre, d_bucket_idx_pre_vector, d_bucket_idx_pre_used,
                d_bucket_idx_pre_offset, d_buckets, (uint32_t)(config.N * NTHREADS), config.npoints
                );
//        launch_coop(bucket_acc_2, dim3(NWINS, (1 << (WBITS - 2)) / NTHREADS), NTHREADS, stream,
//                    d_buckets_pre, d_bucket_idx_pre_vector, d_bucket_idx_pre_used,
//                    d_bucket_idx_pre_offset, d_buckets, (uint32_t)(config.N * NTHREADS), config.npoints);

    }

    void launch_bucket_agg_1(MSMConfig& config, size_t d_buckets_sn, cudaStream_t s = nullptr) {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        bucket_t* d_buckets = d_bucket_ptrs[d_buckets_sn];

        CUDA_OK(cudaSetDevice(device));
//        bucket_agg_1<<<dim3(NWINS, (1 << (WBITS - 5)) / NTHREADS), NTHREADS, 0, stream>>>(d_buckets);
        launch_coop(bucket_agg_1, dim3(NWINS, config.N), NTHREADS, stream, d_buckets);
    }

    void launch_bucket_agg_2(MSMConfig& config, size_t d_buckets_sn, cudaStream_t s = nullptr) {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        bucket_t* d_buckets = d_bucket_ptrs[d_buckets_sn];

        CUDA_OK(cudaSetDevice(device));
        launch_coop(bucket_agg_2, dim3(NWINS, config.N), NTHREADS, stream, d_buckets);
    }

    void launch_recursive_sum(MSMConfig& config, size_t d_buckets_sn, size_t d_res_sn, cudaStream_t s = nullptr) {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        bucket_t* d_buckets = d_bucket_ptrs[d_buckets_sn];
        bucket_t* d_res = d_res_ptrs[d_res_sn];

        CUDA_OK(cudaSetDevice(device));
        launch_coop(recursive_sum, dim3(NWINS, config.N), NTHREADS, stream, d_buckets, d_res);
    }

    // Perform final accumulation on CPU.
    void accumulate_faster(point_t &out, result_container_t_faster &res) {
        out.inf();

        for(int32_t k = NWINS - 1; k >= 0; k--)
        {
            for (int32_t i = 0; i < WBITS; i++)
            {
                out.dbl();
            }
            point_t p = (res[0])[k];
            out.add(p);
        }

    }
};

#endif
