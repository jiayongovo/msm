// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <cuda.h>

#ifndef WARP_SZ
#define WARP_SZ 32
#endif

#ifndef NTHREADS
#define NTHREADS 64
#endif
#if NTHREADS < 32 || (NTHREADS & (NTHREADS - 1)) != 0
#error "bad NTHREADS value"
#endif

constexpr static int log2(int n)
{
    int ret = 0;
    while (n >>= 1)
        ret++;
    return ret;
}

static const int NTHRBITS = log2(NTHREADS);

#if defined(FEATURE_BLS12_381)
#ifndef NBITS
#define NBITS 255
#endif
#elif defined(FEATURE_BLS12_377)
#ifndef NBITS
#define NBITS 253
#endif
#else
# error "no nbits"
#endif

#ifndef FREQUENCY
#define FREQUENCY 8
#endif
#ifndef WBITS
#define WBITS 16
#endif
#define NWINS 16 // ((NBITS+WBITS-1)/WBITS)   // ceil(NBITS/WBITS)

#if FREQUENCY > NWINS | FREQUENCY < 1
#error "bad FREQUENCY value"
#endif

#ifndef LARGE_L1_CODE_CACHE
#define LARGE_L1_CODE_CACHE 0
#endif

__global__ void jy_pre_compute(affine_t *pre_points, size_t npoints);

__global__ void jy_process_scalar_1(uint16_t *scalar, uint32_t *scalar_tuple,
                                    uint32_t *point_idx, size_t npoints);

// v1.1
__global__ void bucket_acc(uint32_t *scalar_tuple_out, /*uint16_t *bucket_idx, */ uint32_t *point_idx_out,
                           affine_t *pre_points, bucket_t *buckets_pre,
                           uint16_t *bucket_idx_pre_vector, uint16_t *bucket_idx_pre_used,
                           uint32_t *bucket_idx_pre_offset, size_t npoints);

__global__ void bucket_acc_2(bucket_t *buckets_pre, uint16_t *bucket_idx_pre_vector, uint16_t *bucket_idx_pre_used,
                             uint32_t *bucket_idx_pre_offset, bucket_t *buckets, uint32_t upper_tnum, size_t npoints);

__global__ void bucket_agg_1(bucket_t *buckets);

__global__ void bucket_agg_2(bucket_t *buckets, bucket_t *res, bucket_t *st, bucket_t *sos);

#ifdef __CUDA_ARCH__

static __shared__ bucket_t bucket_acc_smem[NTHREADS * 2];

// Transposed scalar_t
class scalar_T
{
    uint32_t val[sizeof(scalar_t) / sizeof(uint32_t)][WARP_SZ];

public:
    __device__ uint32_t &operator[](size_t i) { return val[i][0]; }
    __device__ const uint32_t &operator[](size_t i) const { return val[i][0]; }
    __device__ scalar_T &operator=(const scalar_t &rhs)
    {
        for (size_t i = 0; i < sizeof(scalar_t) / sizeof(uint32_t); i++)
            val[i][0] = rhs[i];
        return *this;
    }
};

class scalars_T
{
    scalar_T *ptr;

public:
    __device__ scalars_T(void *rhs) { ptr = (scalar_T *)rhs; }
    __device__ scalar_T &operator[](size_t i)
    {
        return *(scalar_T *)&(&ptr[i / WARP_SZ][0])[i % WARP_SZ];
    }
    __device__ const scalar_T &operator[](size_t i) const
    {
        return *(const scalar_T *)&(&ptr[i / WARP_SZ][0])[i % WARP_SZ];
    }
};

constexpr static __device__ int dlog2(int n)
{
    int ret = 0;
    while (n >>= 1)
        ret++;
    return ret;
}

#if WBITS == 16
template <class scalar_t>
static __device__ int get_wval(const scalar_t &d, uint32_t off, uint32_t bits)
{
    uint32_t ret = d[off / 32];
    return (ret >> (off % 32)) & ((1 << bits) - 1);
}
#else
template <class scalar_t>
static __device__ int get_wval(const scalar_t &d, uint32_t off, uint32_t bits)
{
    uint32_t top = off + bits - 1;
    uint64_t ret = ((uint64_t)d[top / 32] << 32) | d[off / 32];

    return (int)(ret >> (off % 32)) & ((1 << bits) - 1);
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

template <class bucket_t>
static __device__ void mul(bucket_t &res, const bucket_t &base, uint32_t scalar)
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

// jy_msm 点预计算 小优化
__global__ void jy_pre_compute(affine_t *pre_points, size_t npoints)
{
    const uint32_t tnum = blockDim.x * gridDim.x;
    const uint32_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    // 除了原始点 需要多少个num窗口 2^2num pi
    const uint32_t num = (NWINS % FREQUENCY == 0) ? ((NWINS / FREQUENCY - 1)) : (NWINS / FREQUENCY);
    bucket_t Pi_xyzz;
    for (uint32_t i = tid; i < npoints; i += tnum)
    {
        affine_t *Pi = pre_points + i;
        for (int j = 0; j < num; j++)
        {
            Pi_xyzz = *(pre_points + i + j * npoints);
            uint32_t pow = FREQUENCY * WBITS;
            Pi = Pi + npoints;
            for (uint32_t k = 0; k < pow; k++)
                Pi_xyzz.dbl();
            Pi_xyzz.xyzz_to_affine_inf(*Pi);
        }
    }
}

// 把输进来的scalar看作是u16
// 只支持窗口大小为 16 的...
__global__ void jy_process_scalar_1(uint16_t *scalar, uint32_t *scalar_tuple,
                                    uint32_t *point_idx, size_t npoints)
{

    const uint32_t tnum = blockDim.x * gridDim.x;
    const uint32_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    // 每个线程分配到一个标量的划分
    for (int i = tid; i < npoints; i += tnum)
    {
        // 因为把他看作是u16 因此偏移需要加 2^16 * i
        // 每个 scalar 是 256位即 16个 16位
        // 当前线程处理的起始标量 ki
        uint16_t *cur_scalar_ptr = scalar + (i << 4);
        // 获得标量值
        uint32_t cur_scalar = *cur_scalar_ptr;
        // tid ktid 对应的第一个 cur_sign
        // 右移 WBITS-1 位
        uint16_t cur_sign = (cur_scalar >> (WBITS - 1)) & 1;
        cur_scalar = cur_sign == 1 ? ((1 << WBITS) - cur_scalar) : cur_scalar;
        // 将 scalar 和 sign进行拼接
        scalar_tuple[i] = cur_scalar << 1 | cur_sign;
        point_idx[i] = i;
        int m = 0;
        // j 放进去
        for (int j = i + npoints; j < NWINS * npoints; j += npoints)
        {
            // 获取下一个呗
            m += 1;
            cur_scalar_ptr += 1;
            if (m == NWINS - 1)
            {
                // 说明到达了最后一个
                // 取低 WBITS
                // 256 - 253 16 * 16 15 * 16  255位
                uint32_t cur_scalar = (*cur_scalar_ptr) & (0x7fff);

                //  获得之前处理的最低位
                cur_scalar += (scalar_tuple[j - npoints] & 1);
                uint16_t cur_sign;
                // 对于 2^{c-1} 次方 目前选择sign = 0
                if (cur_scalar == (1 << (WBITS - 1)))
                {
                    cur_sign = 0;
                }
                else
                {
                    cur_sign = ((cur_scalar >> (WBITS - 1)) | (cur_scalar >> WBITS)) & 1;
                }
                // uint16_t cur_sign = ((cur_scalar >> (WBITS - 1)) | (cur_scalar >> WBITS)) & 1;
                cur_scalar = cur_sign == 1 ? (1 << WBITS) - cur_scalar : cur_scalar;
                point_idx[j] = i;
                scalar_tuple[j] = cur_scalar << 1 | cur_sign;
            }
            else
            {
                uint32_t cur_scalar = *cur_scalar_ptr;
                // 获得之前处理的最低位
                cur_scalar += (scalar_tuple[j - npoints] & 1);
                uint16_t cur_sign;
                // 对于 2^{c-1} 次方 目前选择sign = 0
                if (cur_scalar == (1 << (WBITS - 1)))
                {
                    cur_sign = 0;
                }
                else
                {
                    cur_sign = ((cur_scalar >> (WBITS - 1)) | (cur_scalar >> WBITS)) & 1;
                }
                // uint16_t cur_sign = ((cur_scalar >> (WBITS - 1)) | (cur_scalar >> WBITS)) & 1;
                cur_scalar = cur_sign == 1 ? (1 << WBITS) - cur_scalar : cur_scalar;
                point_idx[j] = i;
                scalar_tuple[j] = cur_scalar << 1 | cur_sign;
            }
        }
    }
}

// v1.1
__global__ void bucket_acc(uint32_t *scalar_tuple_out, /*uint16_t *bucket_idx,*/ uint32_t *point_idx_out,
                           affine_t *pre_points, bucket_t *buckets_pre,
                           uint16_t *bucket_idx_pre_vector, uint16_t *bucket_idx_pre_used,
                           uint32_t *bucket_idx_pre_offset, size_t npoints)
{
    const uint32_t tnum = blockDim.x * gridDim.y;
    const uint32_t tid_inner = threadIdx.x;
    const uint32_t tid = blockIdx.y * blockDim.x + tid_inner;
    const uint32_t bid = blockIdx.x;
    const uint32_t buffer_len = tnum + (1 << (WBITS - 1));
    uint32_t *scalar_tuple_out_ptr = scalar_tuple_out + npoints * bid;
    // uint16_t *bucket_idx_ptr = bucket_idx + npoints * bid;
    uint32_t *point_idx_out_ptr = point_idx_out + npoints * bid;
    // 和负载平衡相关
    // 只使用一个config.N * NTHREADS 个线程 处理每个窗口
    // 很明显，每个窗口分配的buffer是 buffer_len
    // 第 bid 个窗口对应的 bucket_pre
    bucket_t *buckets_pre_ptr = buckets_pre + buffer_len * bid;
    uint16_t *bucket_idx_pre_vector_ptr = bucket_idx_pre_vector + buffer_len * bid;
    uint16_t *bucket_idx_pre_used_ptr = bucket_idx_pre_used + tnum * bid;
    uint32_t *bucket_idx_pre_offset_ptr = bucket_idx_pre_offset + tnum * bid;

    // 每个线程分配的任务 总数是tnum
    // 每个窗口内 每个线程处理的点数
    const uint32_t step_len = (npoints + tnum - 1) / tnum;
    // 首先确定边界范围，当然需要进一步调整
    uint32_t s = step_len * tid;
    uint32_t e = s + step_len;
    if (s >= npoints)
    {
        bucket_idx_pre_used_ptr[tid] = 0;
        return;
    }
    if (e >= npoints)
        e = npoints;

    uint16_t pre_bucket_idx = 0xffff; // not exist
    // 线程块内部共享内存
    bucket_acc_smem[tid_inner * 2 + 1].inf(); // 设置为inf

    uint32_t offset = tid + (scalar_tuple_out_ptr[s] >> 1); // bucket_idx_ptr[s];
    bucket_idx_pre_offset_ptr[tid] = offset;
    uint32_t unique_num = 0;
    // 每个线程在每个窗口下处理的点
    // process [s, e)
    for (uint32_t i = s; i < e; i++)
    {
        uint16_t cur_bucket_idx = scalar_tuple_out_ptr[i] >> 1; // bucket_idx_ptr[i];
        if (cur_bucket_idx != pre_bucket_idx && (unique_num++))
        {
            // 因为unique_num ++ 了 索引就是 i != s 的时候 ,unique_num 起步等于2
            buckets_pre_ptr[offset + unique_num - 2] = bucket_acc_smem[tid_inner * 2 + 1];
            bucket_idx_pre_vector_ptr[offset + unique_num - 2] = pre_bucket_idx;
            bucket_acc_smem[tid_inner * 2 + 1].inf();
        }
        pre_bucket_idx = cur_bucket_idx;
        uint32_t windows_pre_point_num = bid / FREQUENCY;
        // 第 bid/2 个窗口需要加 相应点的 多少次方到对应的窗口内
        bucket_acc_smem[tid_inner * 2] = pre_points[point_idx_out_ptr[i] + windows_pre_point_num * npoints];
        // 根据scalar的符号判断是否需要进行取反
        if (scalar_tuple_out_ptr[i] & 0x01)
        {
            bucket_acc_smem[tid_inner * 2].neg(true);
        }
        bucket_acc_smem[tid_inner * 2 + 1].add(bucket_acc_smem[tid_inner * 2]);
    }
    buckets_pre_ptr[offset + unique_num - 1] = bucket_acc_smem[tid_inner * 2 + 1];
    bucket_idx_pre_vector_ptr[offset + unique_num - 1] = pre_bucket_idx;
    bucket_idx_pre_used_ptr[tid] = unique_num;
}

// v1.1 (2^{15} THREADS)
// 利用二分搜索去找相应的buffer点进行聚合到相应桶里
__global__ void bucket_acc_2(bucket_t *buckets_pre, uint16_t *bucket_idx_pre_vector, uint16_t *bucket_idx_pre_used,
                             uint32_t *bucket_idx_pre_offset, bucket_t *buckets, uint32_t upper_tnum, size_t npoints)
{
    const uint32_t tid_inner = threadIdx.x;
    const uint32_t tid = blockIdx.y * blockDim.x + tid_inner;
    const uint32_t bid = blockIdx.x;
    const uint32_t buffer_len = upper_tnum + (1 << (WBITS - 1));
    bucket_t *buckets_pre_ptr = buckets_pre + buffer_len * bid;
    uint16_t *bucket_idx_pre_vector_ptr = bucket_idx_pre_vector + buffer_len * bid;
    uint16_t *bucket_idx_pre_used_ptr = bucket_idx_pre_used + upper_tnum * bid;
    uint32_t *bucket_idx_pre_offset_ptr = bucket_idx_pre_offset + upper_tnum * bid;
    bucket_t *buckets_ptr = buckets + (1 << (WBITS - 1)) * bid;

    // 在每个窗口内查线程总数干的东西
    int left = 0, right = upper_tnum - 1;
    bool not_inf = false;
    uint32_t start_pos = 0;
    while (left <= right)
    {
        int mid = left + ((right - left) >> 1);
        uint16_t vector_used = bucket_idx_pre_used_ptr[mid];
        if (!vector_used)
        {
            right = mid - 1;
        }
        else
        {
            uint32_t vector_ptr = bucket_idx_pre_offset_ptr[mid];
            uint16_t min_idx = bucket_idx_pre_vector_ptr[vector_ptr];
            uint16_t max_idx = bucket_idx_pre_vector_ptr[vector_ptr + vector_used - 1];
            if (min_idx == (tid + 1))
            {
                start_pos = mid;
                not_inf = true;
                right = mid - 1;
            }
            else if (min_idx > (tid + 1))
            {
                right = mid - 1;
            }
            else if (max_idx < (tid + 1))
            {
                left = mid + 1;
            }
            else
            {
                for (uint32_t i = vector_ptr + 1; i < vector_ptr + vector_used; i++)
                {
                    if (bucket_idx_pre_vector_ptr[i] == (tid + 1))
                    {
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
    while (not_inf && start_pos < upper_tnum)
    {
        not_inf = false;
        // 找到对应的buffer了
        uint16_t vector_used = bucket_idx_pre_used_ptr[start_pos];
        uint32_t vector_ptr = bucket_idx_pre_offset_ptr[start_pos];
        for (uint32_t i = vector_ptr; i < vector_ptr + vector_used; i++)
        {
            if (bucket_idx_pre_vector_ptr[i] == (tid + 1))
            {
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
    buckets_ptr[tid] = bucket_acc_smem[tid_inner]; // can omit kerner `bucket_inf`
}

// 完成窗口(0,FREQUENCY)聚合
__global__ void bucket_agg_1(bucket_t *buckets)
{
    // dim3(2, config.N), NTHREADS
    const uint32_t tnum = blockDim.x * gridDim.y;
    const uint32_t tid = blockIdx.y * blockDim.x + threadIdx.x;
    const uint32_t bid = blockIdx.x;
    const uint32_t bucket_num = 1 << (WBITS - 1);
    // uint32_t wins = NWINS % 2 == 0 ? (NWINS - 2) / 2 : (bid == 0 ? (NWINS - 1) / 2 : ((NWINS - 1) / 2 - 1));
    uint32_t wins = (NWINS % FREQUENCY == 0) ? ((NWINS / FREQUENCY - 1)) : (NWINS / FREQUENCY);

    bucket_t *buckets_ptr = buckets + (1 << (WBITS - 1)) * bid;
    for (uint32_t i = tid; i < bucket_num; i += tnum)
    {
        for (int j = 1; j <= wins; j++)
        {
            uint32_t win_add_idx = FREQUENCY * j;
            if (win_add_idx >= (NWINS - bid))
                break;
            bucket_t *buckets_ptr_add = buckets_ptr + (1 << (WBITS - 1)) * win_add_idx;
            buckets_ptr[i].add(buckets_ptr_add[i]);
        }
    }
}

__global__ void bucket_agg_2(bucket_t *buckets, bucket_t *res, bucket_t *st, bucket_t *sos)
{
    const uint32_t tnum = blockDim.x * gridDim.y;
    const uint32_t tid = blockIdx.y * blockDim.x + threadIdx.x;
    const uint32_t bid = blockIdx.x;
    const uint32_t tid_inner = threadIdx.x;

    bucket_t *buckets_ptr = buckets + (1 << (WBITS - 1)) * bid;
    const uint32_t bucket_num = 1 << (WBITS - 1);
    bucket_t *st_my = st + bid * tnum;
    bucket_t *sos_my = sos + bid * tnum;
    bucket_t tmp;
    st_my[tid].inf();
    sos_my[tid].inf();
    bucket_acc_smem[tid_inner * 2 + 1].inf(); // 设置为inf
    bucket_acc_smem[tid_inner * 2].inf();
    // 传统串行算法
    // if (tid == 0){
    //     res[bid].inf();
    //     tmp.inf();
    //     for(int i = bucket_num - 1; i >= 0; i--){
    //         bucket_t cur = buckets_ptr[i];
    //         tmp.add(cur);
    //         res[bid].add(tmp);
    //     }
    // }
    const uint32_t step_len = (bucket_num + tnum - 1) / tnum;
    int32_t s = step_len * tid;
    int32_t e = s + step_len;
    // 对于超出的线程，直接返回
    if (s > bucket_num)
    {
        return;
    }
    if (e >= (bucket_num))
        e = bucket_num;
    for (int32_t i = e - 1; i >= s; i--)
    {
        bucket_acc_smem[tid_inner * 2].add(buckets_ptr[i]);
        bucket_acc_smem[tid_inner * 2 + 1].add(bucket_acc_smem[tid_inner * 2]);
    }
    mul(st_my[tid], bucket_acc_smem[tid_inner * 2], tid);
    sos_my[tid] = bucket_acc_smem[tid_inner * 2 + 1];
    __syncthreads();
    if (tid == 0)
    {
        res[bid].inf();
        for (int i = 1; i < tnum; i++)
            st_my[0].add(st_my[i]);
        for (int i = 0; i < tnum; i++)
        {
            res[bid].add(sos_my[i]);
        }
        for (int i = 0; i < step_len; i++)
            res[bid].add(st_my[0]);
    }
}

#else

#include <cassert>
#include <vector>
using namespace std;

#include <util/exception.cuh>
#include <util/rusterror.h>
#include <util/thread_pool_t.hpp>
#include <util/host_pinned_allocator_t.hpp>

template <typename... Types>
inline void launch_coop(void (*f)(Types...),
                        dim3 gridDim, dim3 blockDim, cudaStream_t stream,
                        Types... args)
{
    void *va_args[sizeof...(args)] = {&args...};
    CUDA_OK(cudaLaunchCooperativeKernel((const void *)f, gridDim, blockDim,
                                        va_args, 0, stream));
}

class stream_t
{
    cudaStream_t stream;

public:
    stream_t(int device)
    {
        CUDA_OK(cudaSetDevice(device));
        cudaStreamCreateWithFlags(&stream, cudaStreamNonBlocking);
    }
    ~stream_t() { cudaStreamDestroy(stream); }
    inline operator decltype(stream)() { return stream; }
};

template <class bucket_t>
class result_t_faster
{
    bucket_t ret[NWINS];

public:
    result_t_faster() {}
    inline operator decltype(ret) & () { return ret; }
};

template <class T>
class device_ptr_list_t
{
    vector<T *> d_ptrs;

public:
    device_ptr_list_t() {}
    ~device_ptr_list_t()
    {
        for (T *ptr : d_ptrs)
        {
            cudaFree(ptr);
        }
    }
    size_t allocate(size_t bytes)
    {
        T *d_ptr;
        CUDA_OK(cudaMalloc(&d_ptr, bytes));
        d_ptrs.push_back(d_ptr);
        return d_ptrs.size() - 1;
    }
    size_t size()
    {
        return d_ptrs.size();
    }
    T *operator[](size_t i)
    {
        if (i > d_ptrs.size() - 1)
        {
            CUDA_OK(cudaErrorInvalidDevicePointer);
        }
        return d_ptrs[i];
    }
};

// Pippenger MSM class
template <class bucket_t, class point_t, class affine_t, class scalar_t>
class pippenger_t
{
public:
    typedef vector<result_t_faster<bucket_t>,
                   host_pinned_allocator_t<result_t_faster<bucket_t>>>
        result_container_t_faster;

private:
    size_t sm_count;
    bool init_done = false;
    // 预计算点
    device_ptr_list_t<affine_t> d_pre_points_ptrs;
    device_ptr_list_t<scalar_t> d_scalar_ptrs;
    device_ptr_list_t<bucket_t> d_bucket_ptrs;
    // buffer
    device_ptr_list_t<bucket_t> d_bucket_pre_ptrs; // v1.1
    // buffer index and uesd
    device_ptr_list_t<uint16_t> d_bucket_idx_pre_ptrs; // v1.1
    // buffer offest
    device_ptr_list_t<uint32_t> d_bucket_idx_pre2_ptrs; // v1.2

    device_ptr_list_t<bucket_t> d_res_ptrs;
    device_ptr_list_t<bucket_t> d_st_ptrs;

    // GPU device number
    int device;

    // TODO: Move to device class eventually
    thread_pool_t *da_pool = nullptr;

public:
    // Default stream for operations
    stream_t default_stream;

    // scalar tuple and point index
    device_ptr_list_t<uint32_t> jy_d_scalar_tuple_ptrs;
    device_ptr_list_t<uint32_t> jy_d_point_idx_ptrs;

    // cub
    device_ptr_list_t<unsigned char> d_cub_ptrs;

    // Parameters for an MSM operation
    class MSMConfig
    {
        friend pippenger_t;

    public:
        size_t npoints;
        size_t N;
        size_t n;
    };

    pippenger_t() : default_stream(0)
    {
        device = 0;
    }

    pippenger_t(int _device, thread_pool_t *pool = nullptr)
        : default_stream(_device)
    {
        da_pool = pool;
        device = _device;
    }

    // Initialize instance. Throws cuda_error on error.
    void init()
    {
        if (!init_done)
        {
            CUDA_OK(cudaSetDevice(device));
            cudaDeviceProp prop;
            if (cudaGetDeviceProperties(&prop, 0) != cudaSuccess || prop.major < 7)
                CUDA_OK(cudaErrorInvalidDevice);
            sm_count = prop.multiProcessorCount;

            if (da_pool == nullptr)
            {
                da_pool = new thread_pool_t();
            }

            init_done = true;
        }
    }

    int get_device()
    {
        return device;
    }

    // Initialize parameters for a specific size MSM. Throws cuda_error on error.
    MSMConfig init_msm_faster(size_t npoints)
    {
        init();

        MSMConfig config;
        config.npoints = npoints;
        config.n = (npoints + WARP_SZ - 1) & ((size_t)0 - WARP_SZ);
        // todo 可能需要修改
        config.N = (sm_count * 256) / (NTHREADS * NWINS);
        size_t delta = ((npoints + (config.N) - 1) / (config.N) + WARP_SZ - 1) & (0U - WARP_SZ);
        config.N = (npoints + delta - 1) / delta;

        //        if(config.N % 2 == 1) config.N -= 1;
        return config;
    }

    size_t get_size_bases(MSMConfig &config)
    {
        return config.n * sizeof(affine_t);
    }
    size_t get_size_scalars(MSMConfig &config)
    {
        return config.n * sizeof(scalar_t);
    }
    // 窗口数乘以 2 ^ c - 2
    size_t get_size_buckets()
    {
        return sizeof(bucket_t) * NWINS * (1 << (WBITS - 1));
    }
    size_t get_size_buckets_pre(MSMConfig &config)
    { // v1.1
        return sizeof(bucket_t) * NWINS * (config.N * NTHREADS + (1 << (WBITS - 1)));
    }
    size_t get_size_bucket_idx_pre_vector(MSMConfig &config)
    { // v1.1
        return sizeof(uint16_t) * NWINS * (config.N * NTHREADS + (1 << (WBITS - 1)));
    }
    size_t get_size_bucket_idx_pre_used(MSMConfig &config)
    { // v1.1
        return sizeof(uint16_t) * config.N * NTHREADS * NWINS;
    }
    size_t get_size_bucket_idx_pre_offset(MSMConfig &config)
    { // v1.2
        return sizeof(uint32_t) * config.N * NTHREADS * NWINS;
    }
    // 窗口数 * 桶大小
    size_t get_size_res()
    {
        return sizeof(bucket_t) * NWINS;
    }
    // scalar tuple 存放 kij  uint32 * NWINS * 点数
    size_t get_size_scalar_tuple(MSMConfig &config)
    {
        return config.n * sizeof(uint32_t) * NWINS;
    }
    size_t get_size_point_idx(MSMConfig &config)
    {
        return config.n * sizeof(uint32_t) * NWINS;
    }
    // 分配 cub 排序所需空间
    size_t get_size_cub_sort_faster(MSMConfig &config)
    {
        uint32_t *jy_d_scalar_tuple = nullptr;
        uint32_t *jy_d_scalar_tuple_out = nullptr;
        uint32_t *jy_d_point_idx = nullptr;
        uint32_t *jy_d_point_idx_out = nullptr;
        void *d_temp = NULL;
        size_t temp_size = 0;
        cub::DeviceRadixSort::SortPairs(d_temp, temp_size,
                                        jy_d_scalar_tuple, jy_d_scalar_tuple_out,
                                        jy_d_point_idx, jy_d_point_idx_out, config.n, 0, 31);
        return temp_size;
    }

    result_container_t_faster get_result_container_faster()
    {
        result_container_t_faster res(1);
        return res;
    }

    size_t allocate_d_pre_points(MSMConfig &config)
    {
        size_t num = (NWINS % FREQUENCY == 0) ? ((NWINS / FREQUENCY)) : (NWINS / FREQUENCY + 1);
        return d_pre_points_ptrs.allocate(num * get_size_bases(config));
    }

    size_t allocate_d_scalars(MSMConfig &config)
    {
        return d_scalar_ptrs.allocate(get_size_scalars(config));
    }

    size_t allocate_d_buckets()
    {
        return d_bucket_ptrs.allocate(get_size_buckets());
    }
    // 静态 bucket
    size_t allocate_d_buckets_pre(MSMConfig &config)
    { // v1.1
        return d_bucket_pre_ptrs.allocate(get_size_buckets_pre(config));
    }
    // buffer_index
    size_t allocate_d_bucket_idx_pre_vector(MSMConfig &config)
    { // v1.1
        return d_bucket_idx_pre_ptrs.allocate(get_size_bucket_idx_pre_vector(config));
    }
    // buffer_used
    size_t allocate_d_bucket_idx_pre_used(MSMConfig &config)
    { // v1.1
        return d_bucket_idx_pre_ptrs.allocate(get_size_bucket_idx_pre_used(config));
    }
    // buffer_offset
    size_t allocate_d_bucket_idx_pre_offset(MSMConfig &config)
    { // v1.2
        return d_bucket_idx_pre2_ptrs.allocate(get_size_bucket_idx_pre_offset(config));
    }

    size_t allocate_d_st(MSMConfig &config)
    {
        return d_st_ptrs.allocate(FREQUENCY * NTHREADS * config.N * sizeof(bucket_t));
    }

    size_t allocate_d_sost(MSMConfig &config)
    {
        return d_st_ptrs.allocate(FREQUENCY * NTHREADS * config.N * sizeof(bucket_t));
    }
    size_t allocate_d_res()
    {
        return d_res_ptrs.allocate(get_size_res());
    }

    size_t allocate_jy_d_scalar_tuple(MSMConfig &config)
    {
        return jy_d_scalar_tuple_ptrs.allocate(get_size_scalar_tuple(config));
    }
    size_t allocate_jy_d_scalar_tuple_out(MSMConfig &config)
    {
        return jy_d_scalar_tuple_ptrs.allocate(get_size_scalar_tuple(config));
    }
    size_t allocate_jy_d_point_idx(MSMConfig &config)
    {
        return jy_d_point_idx_ptrs.allocate(get_size_point_idx(config));
    }
    size_t allocate_jy_d_point_idx_out(MSMConfig &config)
    {
        return jy_d_point_idx_ptrs.allocate(get_size_point_idx(config));
    }

    size_t allocate_d_cub_sort_faster(MSMConfig &config)
    {
        return d_cub_ptrs.allocate(get_size_cub_sort_faster(config));
    }

    // Transfer bases to device. Throws cuda_error on error.
    void transfer_bases_to_device(MSMConfig &config, size_t d_pre_points_sn, const affine_t points[],
                                  size_t ffi_affine_sz = sizeof(affine_t),
                                  cudaStream_t s = nullptr)
    {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        affine_t *d_points = d_pre_points_ptrs[d_pre_points_sn];
        CUDA_OK(cudaSetDevice(device));
        if (ffi_affine_sz != sizeof(*d_points))
            CUDA_OK(cudaMemcpy2DAsync(d_points, sizeof(*d_points),
                                      points, ffi_affine_sz,
                                      ffi_affine_sz, config.npoints,
                                      cudaMemcpyHostToDevice, stream));
        else
            CUDA_OK(cudaMemcpyAsync(d_points, points, config.npoints * sizeof(*d_points),
                                    cudaMemcpyHostToDevice, stream));
    }

    // Transfer scalars to device. Throws cuda_error on error.
    void transfer_scalars_to_device(MSMConfig &config,
                                    size_t d_scalars_idx, const scalar_t scalars[],
                                    cudaStream_t s = nullptr)
    {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        scalar_t *d_scalars = d_scalar_ptrs[d_scalars_idx];
        CUDA_OK(cudaSetDevice(device));
        CUDA_OK(cudaMemcpyAsync(d_scalars, scalars, config.npoints * sizeof(*d_scalars),
                                cudaMemcpyHostToDevice, stream));
    }

    void transfer_res_to_host_faster(result_container_t_faster &res, size_t d_res_idx,
                                     cudaStream_t s = nullptr)
    {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        bucket_t *d_res = d_res_ptrs[d_res_idx];

        CUDA_OK(cudaSetDevice(device));
        CUDA_OK(cudaMemcpyAsync(res[0], d_res, sizeof(res[0]),
                                cudaMemcpyDeviceToHost, stream));
    }

    void synchronize_stream()
    {
        CUDA_OK(cudaSetDevice(device));
        CUDA_OK(cudaStreamSynchronize(default_stream));
    }

    void launch_kernel_pre_compute_init(MSMConfig &config,
                                        size_t d_pre_points_sn, cudaStream_t s = nullptr)
    {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        affine_t *d_pre_points = d_pre_points_ptrs[d_pre_points_sn];

        CUDA_OK(cudaSetDevice(device));
        launch_coop(jy_pre_compute, NWINS * config.N, NTHREADS, stream,
                    d_pre_points, config.npoints);
        // jy_pre_compute<<<NWINS * config.N,NTHRBITS,0,stream>>>(
        //     d_pre_points, config.npoints);
    }

    void launch_jy_process_scalar_1(MSMConfig &config,
                                    size_t d_scalars_sn, size_t jy_d_scalar_tuples_sn,
                                    size_t jy_d_point_idx_sn,
                                    cudaStream_t s = nullptr)
    {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        // 把传进来的 scalar 看成是u16集合
        uint16_t *d_scalars = (uint16_t *)d_scalar_ptrs[d_scalars_sn];
        uint32_t *d_scalar_tuple = jy_d_scalar_tuple_ptrs[jy_d_scalar_tuples_sn];
        uint32_t *d_point_idx = jy_d_point_idx_ptrs[jy_d_point_idx_sn];

        CUDA_OK(cudaSetDevice(device));
        launch_coop(jy_process_scalar_1, NWINS * config.N, NTHREADS, stream,
                    d_scalars, d_scalar_tuple, d_point_idx, config.npoints);
        // jy_process_scalar_1<<<NWINS * config.N, NTHREADS,0,stream>>>(
        //     d_scalars, d_scalar_tuple, d_point_idx, config.npoints);
    }

    void launch_bucket_acc(MSMConfig &config,
                           size_t jy_d_scalar_tuples_out_sn, // size_t d_bucket_idx_sn,
                           size_t jy_d_point_idx_out_sn, size_t d_points_sn, size_t d_buckets_sn,
                           size_t d_buckets_pre_sn, size_t d_bucket_idx_pre_vector_sn,
                           size_t d_bucket_idx_pre_used_sn, size_t d_bucket_idx_pre_offset_sn,
                           cudaStream_t s = nullptr)
    {
        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        uint32_t *jy_d_scalar_tuple_out = jy_d_scalar_tuple_ptrs[jy_d_scalar_tuples_out_sn];
        // uint16_t *d_bucket_idx = d_bucket_idx_ptrs[d_bucket_idx_sn];
        uint32_t *jy_d_point_idx_out = jy_d_point_idx_ptrs[jy_d_point_idx_out_sn];
        affine_t *d_points = d_pre_points_ptrs[d_points_sn];
        bucket_t *d_buckets = d_bucket_ptrs[d_buckets_sn];
        bucket_t *d_buckets_pre = d_bucket_pre_ptrs[d_buckets_pre_sn];
        uint16_t *d_bucket_idx_pre_vector = d_bucket_idx_pre_ptrs[d_bucket_idx_pre_vector_sn];
        uint16_t *d_bucket_idx_pre_used = d_bucket_idx_pre_ptrs[d_bucket_idx_pre_used_sn];
        uint32_t *d_bucket_idx_pre_offset = d_bucket_idx_pre2_ptrs[d_bucket_idx_pre_offset_sn];

        CUDA_OK(cudaSetDevice(device));
        //  accumulate parts of the buckets into static buffers.
        launch_coop(bucket_acc, dim3(NWINS, config.N), NTHREADS, stream,
                    jy_d_scalar_tuple_out, /*d_bucket_idx,*/ jy_d_point_idx_out,
                    d_points, d_buckets_pre,
                    d_bucket_idx_pre_vector, d_bucket_idx_pre_used,
                    d_bucket_idx_pre_offset, config.npoints);
        // bucket_acc<<<dim3(NWINS, config.N), NTHREADS, 0, stream>>>(
        //     jy_d_scalar_tuple_out, /*d_bucket_idx,*/ jy_d_point_idx_out,
        //     d_points, d_buckets_pre,
        //     d_bucket_idx_pre_vector, d_bucket_idx_pre_used,
        //     d_bucket_idx_pre_offset, config.npoints);
        //  aggregate the buffered points into the buckets.
        bucket_acc_2<<<dim3(NWINS, (1 << (WBITS - 1)) / NTHREADS), NTHREADS, 0, stream>>>(
            d_buckets_pre, d_bucket_idx_pre_vector, d_bucket_idx_pre_used,
            d_bucket_idx_pre_offset, d_buckets, (uint32_t)(config.N * NTHREADS), config.npoints);
    }

    void launch_bucket_agg_1(MSMConfig &config, size_t d_buckets_sn, cudaStream_t s = nullptr)
    {

        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        bucket_t *d_buckets = d_bucket_ptrs[d_buckets_sn];
        size_t tnum = config.N * NWINS;
        size_t y_tnum = (tnum / FREQUENCY + config.N - 1) / config.N;
        CUDA_OK(cudaSetDevice(device));
        // launch_coop(bucket_agg_1, dim3(FREQUENCY, config.N), NTHREADS, stream, d_buckets);
        bucket_agg_1<<<dim3(FREQUENCY, y_tnum), NTHREADS, 0, stream>>>(d_buckets);
    }

    void launch_bucket_agg_2(MSMConfig &config, size_t d_buckets_sn, size_t d_res_sn, size_t d_st_sn, size_t d_sost_sn, cudaStream_t s = nullptr)
    {

        cudaStream_t stream = (s == nullptr) ? default_stream : s;
        bucket_t *d_buckets = d_bucket_ptrs[d_buckets_sn];
        bucket_t *d_res = d_res_ptrs[d_res_sn];
        bucket_t *st = d_st_ptrs[d_st_sn];
        bucket_t *sost = d_st_ptrs[d_sost_sn];
        size_t tnum = config.N * NWINS;
        size_t y_tnum = (tnum / FREQUENCY + config.N - 1) / config.N;
        CUDA_OK(cudaSetDevice(device));
        // launch_coop(bucket_agg_2, dim3(FREQUENCY, config.N), NTHREADS, stream, d_buckets, d_res, st, sost);

        bucket_agg_2<<<dim3(FREQUENCY, y_tnum), NTHREADS, 0, stream>>>(d_buckets, d_res, st, sost);
    }

    // Perform final accumulation on CPU.
    void accumulate_faster(point_t &out, result_container_t_faster &res)
    {
        out.inf();

        for (int32_t k = FREQUENCY - 1; k >= 0; k--)
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
