// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <cuda.h>
#include "util/log.h"
#include "util/config.h"

__global__ void process_scalars(scalar_t *scalar, uint32_t *scalar_tuple, uint32_t *point_idx, size_t npoints);
__global__ void bucket_acc(uint32_t *scalar_tuple_out,
                           uint32_t *point_idx_out,
                           affine_t *points, bucket_t *buckets_pre,
                           uint16_t *bucket_idx_pre_vector,
                           uint16_t *bucket_idx_pre_used,
                           uint32_t *bucket_idx_pre_offset, size_t npoints);

__global__ void bucket_acc_2(bucket_t *buckets_pre,
                             uint16_t *bucket_idx_pre_vector,
                             uint16_t *bucket_idx_pre_used,
                             uint32_t *bucket_idx_pre_offset, bucket_t *buckets,
                             uint32_t upper_tnum, size_t npoints);

__global__ void bucket_agg(bucket_t *buckets, bucket_t *res);

#ifdef __CUDA_ARCH__

static __shared__ bucket_t bucket_acc_smem[NTHREADS * 2];

template <class scalar_t>
static __forceinline__ __device__ uint32_t get_wval(const scalar_t *d, uint32_t off, uint32_t bits)
{
  uint32_t *scalar = (uint32_t *)d;
  uint32_t top = off + bits - 1;
  uint64_t ret = ((uint64_t)scalar[top / 32] << 32) | scalar[off / 32];
  return (uint32_t)(ret >> (off % 32)) & ((1 << bits) - 1);
}

static __forceinline__ __device__ uint32_t max_bits(uint32_t scalar)
{
  uint32_t max = 32;
  return max;
}

static __forceinline__ __device__ bool test_bit(uint32_t scalar, uint32_t bitno)
{
  if (bitno >= 32)
    return false;
  return ((scalar >> bitno) & 0x1);
}

template <class bucket_t>
static __device__ void mul(bucket_t &res, const bucket_t &base,
                           uint32_t scalar)
{
  res.inf();

  bool found_one = false;
  uint32_t mb = max_bits(scalar);
#pragma unroll
  for (int32_t i = mb - 1; i >= 0; i--)
  {
    if (found_one)
      res.dbl();
    if (test_bit(scalar, i))
    {
      found_one = true;
      res.add(base);
    }
  }
}

__global__ void process_scalars(scalar_t *scalar, uint32_t *scalar_tuple,
                                uint32_t *point_idx, size_t npoints)
{
  const uint32_t tnum = blockDim.x * gridDim.x;
  const uint32_t tid = blockIdx.x * blockDim.x + threadIdx.x;
  const uint32_t scalar_max = 1U << WBITS;
  const uint32_t half_scalar = scalar_max >> 1;

#pragma unroll
  for (int i = tid; i < npoints; i += tnum)
  {
    uint32_t cur_scalar = get_wval<scalar_t>(scalar, i * NWINS * WBITS, WBITS);
    uint16_t cur_sign = (cur_scalar >> (WBITS - 1)) & 1;
    cur_scalar = cur_sign == 1 ? (scalar_max - cur_scalar) : cur_scalar;
    scalar_tuple[i] = cur_scalar << 1 | cur_sign;
    point_idx[i] = i;
    int m = 0;
#pragma unroll
    for (int j = i + npoints; j < NWINS * npoints; j += npoints)
    {
      m += 1;
      uint32_t cur_scalar = get_wval<scalar_t>(scalar, (i * NWINS + m) * WBITS, WBITS);
      cur_scalar += (scalar_tuple[j - npoints] & 1);
      uint16_t cur_sign = (cur_scalar == half_scalar) ? 0 : (((cur_scalar >> (WBITS - 1)) | (cur_scalar >> WBITS)) & 1);
      cur_scalar = cur_sign == 1 ? scalar_max - cur_scalar : cur_scalar;
      point_idx[j] = i;
      scalar_tuple[j] = cur_scalar << 1 | cur_sign;
    }
  }
}

__global__ void bucket_acc(uint32_t *scalar_tuple_out,
                           uint32_t *point_idx_out,
                           affine_t *points, bucket_t *buckets_pre,
                           uint16_t *bucket_idx_pre_vector,
                           uint16_t *bucket_idx_pre_used,
                           uint32_t *bucket_idx_pre_offset, size_t npoints)
{
  const uint32_t tnum = blockDim.x * gridDim.y;
  const uint32_t tid_inner = threadIdx.x;
  const uint32_t tid = blockIdx.y * blockDim.x + tid_inner;
  const uint32_t bid = blockIdx.x;
  const uint32_t buffer_len = tnum + (1 << (WBITS - 1));
  
  uint32_t *scalar_tuple_out_ptr = scalar_tuple_out + npoints * bid;
  uint32_t *point_idx_out_ptr = point_idx_out + npoints * bid;
  bucket_t *buckets_pre_ptr = buckets_pre + buffer_len * bid;
  uint16_t *bucket_idx_pre_vector_ptr = bucket_idx_pre_vector + buffer_len * bid;
  uint16_t *bucket_idx_pre_used_ptr = bucket_idx_pre_used + tnum * bid;
  uint32_t *bucket_idx_pre_offset_ptr = bucket_idx_pre_offset + tnum * bid;

  const uint32_t step_len = (npoints + tnum - 1) / tnum;
  uint32_t s = step_len * tid;
  uint32_t e = min(s + step_len, (uint32_t)npoints);
  
  if (s >= npoints) {
    bucket_idx_pre_used_ptr[tid] = 0;
    return;
  }

  bucket_acc_smem[tid_inner * 2 + 1].inf();
  
  const uint32_t scalar_tuple_val = scalar_tuple_out_ptr[s];
  uint16_t pre_bucket_idx = scalar_tuple_val >> 1;
  uint32_t offset = tid + pre_bucket_idx;
  bucket_idx_pre_offset_ptr[tid] = offset;
  uint32_t unique_num = 0;
  
  for (uint32_t i = s; i < e; i++)
  {
    const uint32_t curr_scalar_tuple = scalar_tuple_out_ptr[i];
    const uint16_t cur_bucket_idx = curr_scalar_tuple >> 1;
    const uint32_t point_idx = point_idx_out_ptr[i];
    
    bool changed = (cur_bucket_idx != pre_bucket_idx);
    if (changed && i > s) 
    {
      buckets_pre_ptr[offset + unique_num] = bucket_acc_smem[tid_inner * 2 + 1];
      bucket_idx_pre_vector_ptr[offset + unique_num] = pre_bucket_idx;
      bucket_acc_smem[tid_inner * 2 + 1].inf();
      unique_num++;
    }
    
    pre_bucket_idx = cur_bucket_idx;
    
    affine_t tmp = points[point_idx];
    tmp.neg((curr_scalar_tuple & 0x01) != 0);
    bucket_acc_smem[tid_inner * 2 + 1].add(tmp);
  }
  
  if (s < e) { 
    buckets_pre_ptr[offset + unique_num] = bucket_acc_smem[tid_inner * 2 + 1];
    bucket_idx_pre_vector_ptr[offset + unique_num] = pre_bucket_idx;
    bucket_idx_pre_used_ptr[tid] = unique_num + 1; 
  } else {
    bucket_idx_pre_used_ptr[tid] = 0;
  }
}

__global__ void bucket_acc_2(bucket_t *buckets_pre,
                             uint16_t *bucket_idx_pre_vector,
                             uint16_t *bucket_idx_pre_used,
                             uint32_t *bucket_idx_pre_offset, bucket_t *buckets,
                             uint32_t upper_tnum, size_t npoints)
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

  const uint16_t target_idx = tid + 1;
  
  int left = 0, right = upper_tnum - 1;
  bool not_inf = false;
  uint32_t start_pos = 0;
  
  while (left <= right) 
  {
    int mid = left + ((right - left) >> 1);
    uint16_t vector_used = bucket_idx_pre_used_ptr[mid];
    
    if (!vector_used) {
      right = mid - 1;
    } else {
      uint32_t vector_ptr = bucket_idx_pre_offset_ptr[mid];
      uint16_t min_idx = bucket_idx_pre_vector_ptr[vector_ptr];
      uint16_t max_idx = bucket_idx_pre_vector_ptr[vector_ptr + vector_used - 1];
      
      if (min_idx == target_idx) {
        start_pos = mid;
        not_inf = true;
        right = mid - 1; 
      } else if (min_idx > target_idx) {
        right = mid - 1;
      } else if (max_idx < target_idx) {
        left = mid + 1;
      } else {
        for (uint32_t i = 1; i < vector_used; i++) { 
          if (bucket_idx_pre_vector_ptr[vector_ptr + i] == target_idx) {
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
    uint16_t vector_used = bucket_idx_pre_used_ptr[start_pos];
    if (vector_used == 0) {
      start_pos++;
      continue;
    }
    
    uint32_t vector_ptr = bucket_idx_pre_offset_ptr[start_pos];
    
    for (uint32_t i = vector_ptr; i < vector_ptr + vector_used; i++) {
      if (bucket_idx_pre_vector_ptr[i] == target_idx) {
        bucket_acc_smem[tid_inner].add(buckets_pre_ptr[i]);
        not_inf = true;
        break;
      }
    }
    
    start_pos++; 
  }
  
  buckets_ptr[tid] = bucket_acc_smem[tid_inner];
}

__global__ void bucket_agg(bucket_t *buckets, bucket_t *res)
{
  const uint32_t tid = threadIdx.x;
  const uint32_t bid = blockIdx.x;
  const uint32_t bucket_num = 1 << (WBITS - 1);
  
  __shared__ bucket_t shared_sos[NTHREADS];
  
  shared_sos[tid].inf();
  
  bucket_t *buckets_ptr = buckets + bucket_num * bid;
  
  const uint32_t items_per_thread = (bucket_num + NTHREADS - 1) / NTHREADS;
  const uint32_t start = tid * items_per_thread;
  const uint32_t end = min(start + items_per_thread, bucket_num);
  
  if (start < bucket_num)
  {
    bucket_t running_sum, total_sum;
    running_sum.inf();
    total_sum.inf();
    
    #pragma unroll 4
    for (int32_t i = end - 1; i >= (int32_t)start; i--)
    {
      running_sum.add(buckets_ptr[i]);
      total_sum.add(running_sum);
    }
    
    if (start > 0)
    {
      bucket_t offset;
      mul(offset, running_sum, start);
      total_sum.add(offset);
    }
    
    shared_sos[tid] = total_sum;
  }
  
  __syncthreads();
  
  for (uint32_t stride = NTHREADS / 2; stride > 0; stride >>= 1)
  {
    if (tid < stride)
    {
      shared_sos[tid].add(shared_sos[tid + stride]);
    }
    __syncthreads();
  }
  
  if (tid == 0)
  {
    res[bid] = shared_sos[0];
  }
}

#else

#include <cassert>
#include <vector>
using namespace std;

#include <util/exception.cuh>
#include <util/host_pinned_allocator_t.hpp>
#include <util/rusterror.h>
#include <util/thread_pool_t.hpp>

template <typename... Types>
inline void launch_coop(void (*f)(Types...), dim3 gridDim, dim3 blockDim,
                        cudaStream_t stream, Types... args)
{
  void *va_args[sizeof...(args)] = {&args...};
  CUDA_OK(cudaLaunchCooperativeKernel((const void *)f, gridDim, blockDim,
                                      va_args, 0, stream));
}

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
  size_t size() { return d_ptrs.size(); }
  T *operator[](size_t i)
  {
    if (i > d_ptrs.size() - 1)
    {
      CUDA_OK(cudaErrorInvalidDevicePointer);
    }
    return d_ptrs[i];
  }
};

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
  // device_ptr_list_t<affine_t> d_pre_points_ptrs;
  device_ptr_list_t<affine_t> d_points_ptrs;
  device_ptr_list_t<scalar_t> d_scalar_ptrs;
  device_ptr_list_t<bucket_t> d_bucket_ptrs;
  device_ptr_list_t<bucket_t> d_bucket_pre_ptrs;
  device_ptr_list_t<uint16_t> d_bucket_idx_pre_ptrs;
  device_ptr_list_t<uint32_t> d_bucket_idx_pre2_ptrs;

  device_ptr_list_t<bucket_t> d_res_ptrs;

  int device;

  thread_pool_t *da_pool = nullptr;

public:
  // Default stream for operations
  stream_t default_stream;

  // scalar tuple and point index
  device_ptr_list_t<uint32_t> d_scalar_tuple_ptrs;
  device_ptr_list_t<uint32_t> d_point_idx_ptrs;

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

  pippenger_t() : default_stream(0) { device = 0; }
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
      CUDA_OK(cudaGetDevice(&device));
      default_stream = stream_t(device);
      LOG(INFO, "Initializing GPU device %d", device);
      // CUDA_OK(cudaSetDevice(device));
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

  int get_device() { return device; }

  // Initialize parameters for a specific size MSM. Throws cuda_error on error.
  MSMConfig init_msm_faster(size_t npoints)
  {
    LOG(INFO, "Init GPU device for MSM with %d points", npoints);
    init();
    LOG(INFO, "Find Best parameters for MSM");
    MSMConfig config;
    config.npoints = npoints;
    config.n = (npoints + WARP_SZ - 1) & ((size_t)0 - WARP_SZ);
    config.N = (sm_count * 256) / (NTHREADS * NWINS);
    size_t delta = ((npoints + config.N - 1) / config.N + WARP_SZ - 1) & (0U - WARP_SZ);
    config.N = (npoints + delta - 1) / delta;
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
    return sizeof(bucket_t) * NWINS *
           (config.N * NTHREADS + (1 << (WBITS - 1)));
  }
  size_t get_size_bucket_idx_pre_vector(MSMConfig &config)
  { // v1.1
    return sizeof(uint16_t) * NWINS *
           (config.N * NTHREADS + (1 << (WBITS - 1)));
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
  size_t get_size_res() { return sizeof(bucket_t) * NWINS; }
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
    uint32_t *d_scalar_tuple = nullptr;
    uint32_t *d_scalar_tuple_out = nullptr;
    uint32_t *d_point_idx = nullptr;
    uint32_t *d_point_idx_out = nullptr;
    void *d_temp = NULL;
    size_t temp_size = 0;
    cub::DeviceRadixSort::SortPairs(d_temp, temp_size, d_scalar_tuple,
                                    d_scalar_tuple_out, d_point_idx,
                                    d_point_idx_out, config.n, 0, 31);
    return temp_size;
  }

  result_container_t_faster get_result_container_faster()
  {
    result_container_t_faster res(1);
    return res;
  }

  size_t allocate_d_points(MSMConfig &config)
  {
    return d_points_ptrs.allocate(get_size_bases(config));
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
    return d_bucket_idx_pre_ptrs.allocate(
        get_size_bucket_idx_pre_vector(config));
  }
  // buffer_used
  size_t allocate_d_bucket_idx_pre_used(MSMConfig &config)
  { // v1.1
    return d_bucket_idx_pre_ptrs.allocate(get_size_bucket_idx_pre_used(config));
  }
  // buffer_offset
  size_t allocate_d_bucket_idx_pre_offset(MSMConfig &config)
  { // v1.2
    return d_bucket_idx_pre2_ptrs.allocate(
        get_size_bucket_idx_pre_offset(config));
  }
  size_t allocate_d_res() { return d_res_ptrs.allocate(get_size_res()); }

  size_t allocate_d_scalar_tuple(MSMConfig &config)
  {
    return d_scalar_tuple_ptrs.allocate(get_size_scalar_tuple(config));
  }
  size_t allocate_d_scalar_tuple_out(MSMConfig &config)
  {
    return d_scalar_tuple_ptrs.allocate(get_size_scalar_tuple(config));
  }
  size_t allocate_d_point_idx(MSMConfig &config)
  {
    return d_point_idx_ptrs.allocate(get_size_point_idx(config));
  }
  size_t allocate_d_point_idx_out(MSMConfig &config)
  {
    return d_point_idx_ptrs.allocate(get_size_point_idx(config));
  }

  size_t allocate_d_cub_sort_faster(MSMConfig &config)
  {
    return d_cub_ptrs.allocate(get_size_cub_sort_faster(config));
  }

  // Transfer bases to device. Throws cuda_error on error.
  void transfer_bases_to_device(MSMConfig &config, size_t d_points_sn,
                                const affine_t points[],
                                size_t ffi_affine_sz = sizeof(affine_t),
                                cudaStream_t s = nullptr)
  {
    cudaStream_t stream = (s == nullptr) ? default_stream : s;
    affine_t *d_points = d_points_ptrs[d_points_sn];
    CUDA_OK(cudaSetDevice(device));
    if (ffi_affine_sz != sizeof(*d_points))
      CUDA_OK(cudaMemcpy2DAsync(d_points, sizeof(*d_points), points,
                                ffi_affine_sz, ffi_affine_sz, config.npoints,
                                cudaMemcpyHostToDevice, stream));
    else
      CUDA_OK(cudaMemcpyAsync(d_points, points,
                              config.npoints * sizeof(*d_points),
                              cudaMemcpyHostToDevice, stream));
  }

  // Transfer scalars to device. Throws cuda_error on error.
  void transfer_scalars_to_device(MSMConfig &config, size_t d_scalars_idx,
                                  const scalar_t scalars[],
                                  cudaStream_t s = nullptr)
  {
    cudaStream_t stream = (s == nullptr) ? default_stream : s;
    scalar_t *d_scalars = d_scalar_ptrs[d_scalars_idx];
    CUDA_OK(cudaSetDevice(device));
    CUDA_OK(cudaMemcpyAsync(d_scalars, scalars,
                            config.npoints * sizeof(*d_scalars),
                            cudaMemcpyHostToDevice, stream));
  }

  void transfer_res_to_host_faster(result_container_t_faster &res,
                                   size_t d_res_idx, cudaStream_t s = nullptr)
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

  void launch_process_scalars(MSMConfig &config, size_t d_scalars_sn,
                              size_t d_scalar_tuples_sn,
                              size_t d_point_idx_sn,
                              cudaStream_t s = nullptr)
  {
    cudaStream_t stream = (s == nullptr) ? default_stream : s;
    // 把传进来的 scalar 看成是u16集合
    scalar_t *d_scalars = d_scalar_ptrs[d_scalars_sn];
    uint32_t *d_scalar_tuple = d_scalar_tuple_ptrs[d_scalar_tuples_sn];
    uint32_t *d_point_idx = d_point_idx_ptrs[d_point_idx_sn];

    CUDA_OK(cudaSetDevice(device));
    launch_coop(process_scalars, NWINS * config.N, NTHREADS, stream, d_scalars,
                d_scalar_tuple, d_point_idx, config.npoints);
  }

  void launch_bucket_acc(
      MSMConfig &config,
      size_t d_scalar_tuples_out_sn, // size_t d_bucket_idx_sn,
      size_t d_point_idx_out_sn, size_t d_points_sn, size_t d_buckets_sn,
      size_t d_buckets_pre_sn, size_t d_bucket_idx_pre_vector_sn,
      size_t d_bucket_idx_pre_used_sn, size_t d_bucket_idx_pre_offset_sn,
      cudaStream_t s = nullptr)
  {
    cudaStream_t stream = (s == nullptr) ? default_stream : s;
    uint32_t *d_scalar_tuple_out =
        d_scalar_tuple_ptrs[d_scalar_tuples_out_sn];
    uint32_t *d_point_idx_out = d_point_idx_ptrs[d_point_idx_out_sn];
    affine_t *d_points = d_points_ptrs[d_points_sn];
    bucket_t *d_buckets = d_bucket_ptrs[d_buckets_sn];
    bucket_t *d_buckets_pre = d_bucket_pre_ptrs[d_buckets_pre_sn];
    uint16_t *d_bucket_idx_pre_vector =
        d_bucket_idx_pre_ptrs[d_bucket_idx_pre_vector_sn];
    uint16_t *d_bucket_idx_pre_used =
        d_bucket_idx_pre_ptrs[d_bucket_idx_pre_used_sn];
    uint32_t *d_bucket_idx_pre_offset =
        d_bucket_idx_pre2_ptrs[d_bucket_idx_pre_offset_sn];

    CUDA_OK(cudaSetDevice(device));

    bucket_acc<<<dim3(NWINS, config.N), NTHREADS, 0, stream>>>(
        d_scalar_tuple_out, /*d_bucket_idx,*/ d_point_idx_out,
        d_points, d_buckets_pre,
        d_bucket_idx_pre_vector, d_bucket_idx_pre_used,
        d_bucket_idx_pre_offset, config.npoints);
    //  aggregate the buffered points into the buckets.
    bucket_acc_2<<<dim3(NWINS, (1 << (WBITS - 1)) / NTHREADS), NTHREADS, 0,
                   stream>>>(d_buckets_pre, d_bucket_idx_pre_vector,
                             d_bucket_idx_pre_used, d_bucket_idx_pre_offset,
                             d_buckets, (uint32_t)(config.N * NTHREADS),
                             config.npoints);
  }

  void launch_bucket_agg(MSMConfig &config, size_t d_buckets_sn,
                         size_t d_res_sn,
                         cudaStream_t s = nullptr)
  {
    cudaStream_t stream = (s == nullptr) ? default_stream : s;
    bucket_t *d_buckets = d_bucket_ptrs[d_buckets_sn];
    bucket_t *d_res = d_res_ptrs[d_res_sn];
    CUDA_OK(cudaSetDevice(device));
    CUDA_OK(cudaSetDevice(device));
    bucket_agg<<<NWINS, NTHREADS, 0, stream>>>(d_buckets,
                                               d_res);
  }

  // Perform final accumulation on CPU.
  void accumulate_faster(point_t &out, result_container_t_faster &res)
  {
    LOG(WARN, "accumulate_faster");
    out.inf();
#pragma unroll 1
    for (int32_t k = NWINS - 1; k >= 0; k--)
    {
      for (uint32_t i = 0; i < WBITS; i++)
      {
        out.dbl();
      }
      point_t p = (res[0])[k];
      out.add(p);
    }
  }
};

#endif
