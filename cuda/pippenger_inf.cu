// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <cub/cub.cuh>
#include <cuda.h>
#include <sys/mman.h>
#include <ec/jacobian_t.hpp>
#include <ec/xyzz_t.hpp>
#include <ec/xyzt_t.hpp>
#include <util/log.h>
#include <ff/bls12-381.hpp>

// #if defined(FEATURE_BLS12_381)
// #include <ff/bls12-381.hpp>
// #elif defined(FEATURE_BLS12_377)
// #include <ff/bls12-377.hpp>
// #else
// #error "Unknown curve"
// #endif

typedef jacobian_t<fp_t> point_t;
typedef xyzz_t<fp_t> bucket_t;
// typedef xyzt_t<fp_t> bucket_t;
typedef bucket_t::affine_inf_t affine_t;
typedef fr_t scalar_t;

#include <msm/pippenger.cuh>

// init cub radix sort
extern "C" void cub_initial()
{
  uint32_t *d_scalar_tuple = nullptr;
  uint32_t *d_scalar_tuple_out = nullptr;
  uint32_t *d_point_idx = nullptr;
  uint32_t *d_point_idx_out = nullptr;
  uint32_t *d_offset_a = nullptr;
  uint32_t *d_offset_b = nullptr;
  void *d_temp = NULL;
  size_t temp_size = 0;
  cub::DeviceRadixSort::SortPairs(d_temp, temp_size, d_scalar_tuple,
                                  d_scalar_tuple_out, d_point_idx,
                                  d_point_idx_out, 1);
  cub::DeviceSegmentedRadixSort::SortPairs(
      d_temp, temp_size, d_scalar_tuple, d_scalar_tuple_out, d_point_idx,
      d_point_idx_out, 1, 1, d_offset_a, d_offset_b);
}

#ifndef __CUDA_ARCH__

// 每批次启动线程数
static const size_t NUM_BATCH_THREADS = 2;
static thread_pool_t batch_pool(NUM_BATCH_THREADS);

typedef pippenger_t<bucket_t, point_t, affine_t, scalar_t> pipp_t;

// MSM context used store persistent state
template <class bucket_t, class affine_t, class scalar_t>
struct Context
{
  pipp_t pipp;
  typename pipp_t::MSMConfig config;
  size_t ffi_affine_sz;
  size_t d_pre_points_sn;
  size_t d_scalars_sn[NUM_BATCH_THREADS];
  size_t d_buckets_sn;
  size_t d_scalar_tuples_sn;
  size_t d_point_idx_sn;
  size_t d_scalar_tuples_out_sn;
  size_t d_point_idx_out_sn;
  // buffer
  size_t d_buckets_pre_sn;
  // buffer index
  size_t d_bucket_idx_pre_vector_sn;
  // buffer used
  size_t d_bucket_idx_pre_used_sn;
  // buffer offest
  size_t d_bucket_idx_pre_offset_sn;
  size_t d_res_sn;
  size_t d_sost_sn;
  size_t d_cub_sort_idx;
  scalar_t *h_scalars;

  typename pipp_t::result_container_t_faster fres0;
  typename pipp_t::result_container_t_faster fres1;
};

template <class bucket_t, class affine_t, class scalar_t>
struct RustContext
{
  Context<bucket_t, affine_t, scalar_t> *context;
};

// Initialization function
// Allocate device storage, transfer bases
extern "C" RustError
mult_pippenger_faster_init(RustContext<bucket_t, affine_t, scalar_t> *context,
                           const affine_t points[], size_t npoints,
                           size_t ffi_affine_sz)
{
  LOG(INFO, "MSM init");
  context->context = new Context<bucket_t, affine_t, scalar_t>();
  Context<bucket_t, affine_t, scalar_t> *ctx = context->context;
  ctx->ffi_affine_sz = ffi_affine_sz;
  try
  {
    ctx->config = ctx->pipp.init_msm_faster(npoints);
    LOG(INFO, "Molloc MSM memory");
    ctx->d_pre_points_sn = ctx->pipp.allocate_d_pre_points(ctx->config);
    //
    for (size_t i = 0; i < NUM_BATCH_THREADS; i++)
    {
      ctx->d_scalars_sn[i] = ctx->pipp.allocate_d_scalars(ctx->config);
    }
    ctx->d_buckets_sn = ctx->pipp.allocate_d_buckets();
    ctx->d_buckets_pre_sn = ctx->pipp.allocate_d_buckets_pre(ctx->config);
    ctx->d_bucket_idx_pre_vector_sn =
        ctx->pipp.allocate_d_bucket_idx_pre_vector(ctx->config);
    ctx->d_bucket_idx_pre_used_sn =
        ctx->pipp.allocate_d_bucket_idx_pre_used(ctx->config);
    ctx->d_bucket_idx_pre_offset_sn =
        ctx->pipp.allocate_d_bucket_idx_pre_offset(ctx->config);

    ctx->d_sost_sn = ctx->pipp.allocate_d_sost(ctx->config);
    ctx->d_res_sn = ctx->pipp.allocate_d_res();
    ctx->d_scalar_tuples_sn =
        ctx->pipp.allocate_d_scalar_tuple(ctx->config);
    ctx->d_point_idx_sn = ctx->pipp.allocate_d_point_idx(ctx->config);
    ctx->d_scalar_tuples_out_sn =
        ctx->pipp.allocate_d_scalar_tuple_out(ctx->config);
    ctx->d_point_idx_out_sn = ctx->pipp.allocate_d_point_idx(ctx->config);
    ctx->d_cub_sort_idx = ctx->pipp.allocate_d_cub_sort_faster(ctx->config);

    // Allocate pinned memory on host
    CUDA_OK(cudaMallocHost(&ctx->h_scalars,
                           ctx->pipp.get_size_scalars(ctx->config)));

    LOG(INFO, "Transfer bases to device");

    ctx->pipp.transfer_bases_to_device(ctx->config, ctx->d_pre_points_sn,
                                       points, ffi_affine_sz);
    LOG(INFO, "Launch kernel pre compute init");
    ctx->pipp.launch_kernel_pre_compute_init(ctx->config, ctx->d_pre_points_sn);

    ctx->fres0 = ctx->pipp.get_result_container_faster();
    ctx->fres1 = ctx->pipp.get_result_container_faster();
  }
  catch (const cuda_error &e)
  {
#ifdef TAKE_RESPONSIBILITY_FOR_ERROR_MESSAGE
    return RustError{e.code(), e.what()};
#else
    return RustError { e.code() }
#endif
  }
  return RustError{cudaSuccess};
}

// Peform MSM on a batch of scalars over fixed bases
extern "C" RustError
mult_pippenger_faster_inf(RustContext<bucket_t, affine_t, scalar_t> *context,
                          point_t *out, const affine_t points[], size_t npoints,
                          size_t batches, const scalar_t scalars[],
                          size_t ffi_affine_sz)
{
  (void)points; // Silence unused param warning

  Context<bucket_t, affine_t, scalar_t> *ctx = context->context;
  assert(ctx->config.npoints == npoints);
  assert(ctx->ffi_affine_sz == ffi_affine_sz);
  assert(batches > 0);

  cudaStream_t stream = ctx->pipp.default_stream;
  stream_t aux_stream(ctx->pipp.get_device());

  try
  {
    for (size_t i = 0; i < batches; i++)
    {
      out[i].inf();
    }

    typename pipp_t::result_container_t_faster *kernel_res = &ctx->fres0;
    typename pipp_t::result_container_t_faster *accum_res = &ctx->fres1;

    size_t d_scalars_xfer = ctx->d_scalars_sn[0];
    size_t d_scalars_compute = ctx->d_scalars_sn[1];

    channel_t<size_t> ch;
    size_t scalars_sz = ctx->pipp.get_size_scalars(ctx->config);

    int work = 0;
    LOG(INFO, "Transfer scalars to device");
    memcpy(ctx->h_scalars, &scalars[work * npoints], scalars_sz);
    ctx->pipp.transfer_scalars_to_device(ctx->config, d_scalars_compute,
                                         ctx->h_scalars, aux_stream);
    CUDA_OK(cudaStreamSynchronize(aux_stream));

    for (; work < (int)batches; work++)
    {
      // Launch the GPU kernel, transfer the results back
      batch_pool.spawn([&]()
                       {
        CUDA_OK(cudaStreamSynchronize(aux_stream));
        LOG(INFO, "Launch process scalars");
        nvtxRangePushA("process_scalars");
        ctx->pipp.launch_process_scalars(ctx->config, d_scalars_compute,
                                        ctx->d_scalar_tuples_sn,
                                        ctx->d_point_idx_sn);
        nvtxRangePop();
        // scalar point
        uint32_t *d_scalar_tuple =
            ctx->pipp.d_scalar_tuple_ptrs[ctx->d_scalar_tuples_sn];
        uint32_t *d_scalar_tuple_out =
            ctx->pipp.d_scalar_tuple_ptrs[ctx->d_scalar_tuples_out_sn];
        uint32_t *d_point_idx =
            ctx->pipp.d_point_idx_ptrs[ctx->d_point_idx_sn];
        uint32_t *d_point_idx_out =
            ctx->pipp.d_point_idx_ptrs[ctx->d_point_idx_out_sn];
        uint32_t nscalars = npoints;
        void *d_temp = NULL;
        size_t temp_sort_size = 0;
        // 暂时先将最低1位到最高31位获取sij
        cub::DeviceRadixSort::SortPairs(
            d_temp, temp_sort_size, d_scalar_tuple, d_scalar_tuple_out,
            d_point_idx, d_point_idx_out, nscalars, 0, 31, stream);
        void *d_cub_sort = (void *)ctx->pipp.d_cub_ptrs[ctx->d_cub_sort_idx];
        // 在每个窗口内进行排序
        LOG(INFO, "Launch sort");
        for (size_t k = 0; k < NWINS; k++) {
          size_t ptr = k * nscalars;
          cub::DeviceRadixSort::SortPairs(
              d_cub_sort, temp_sort_size, d_scalar_tuple + ptr,
              d_scalar_tuple_out + ptr, d_point_idx + ptr,
              d_point_idx_out + ptr, nscalars, 0, 31, stream);
        }

        // accumulate parts of the buckets into static buffers.
        LOG(INFO, "Launch bucket acc");
        nvtxRangePushA("bucket_acc");
        ctx->pipp.launch_bucket_acc(
            ctx->config, ctx->d_scalar_tuples_out_sn,
            ctx->d_point_idx_out_sn, ctx->d_pre_points_sn, ctx->d_buckets_sn,
            ctx->d_buckets_pre_sn, ctx->d_bucket_idx_pre_vector_sn,
            ctx->d_bucket_idx_pre_used_sn, ctx->d_bucket_idx_pre_offset_sn);
        nvtxRangePop();
        LOG(INFO, "Launch bucket agg");
        nvtxRangePushA("bucket_agg_1");

        ctx->pipp.launch_bucket_agg_1(ctx->config, ctx->d_buckets_sn);
        nvtxRangePop();
        nvtxRangePushA("bucket_agg_2");

        ctx->pipp.launch_bucket_agg_2(ctx->config, ctx->d_buckets_sn,
                                      ctx->d_res_sn, ctx->d_sost_sn);
        nvtxRangePop();
        LOG(INFO, "Transfer res to host");
        ctx->pipp.transfer_res_to_host_faster(*kernel_res, ctx->d_res_sn);
        ctx->pipp.synchronize_stream();

        ch.send(work); });

      // Transfer the next set of scalars, Faccumulate the previous result
      batch_pool.spawn([&]()
                       {
        // Start next scalar transfer
        if (work + 1 < (int)batches) {
          // Copy into pinned memory
          LOG(INFO, "Transfer next batch scalars to device");
          memcpy(ctx->h_scalars, &scalars[(work + 1) * npoints], scalars_sz);

          ctx->pipp.transfer_scalars_to_device(ctx->config, d_scalars_xfer,
                                               ctx->h_scalars, aux_stream);
        }
        // Accumulate the previous result
        if (work - 1 >= 0) {
          LOG(INFO, "Accumulate result");
          ctx->pipp.accumulate_faster(out[work - 1], *accum_res);
        }
        ch.send(work); });
      ch.recv();
      ch.recv();
      std::swap(kernel_res, accum_res);
      std::swap(d_scalars_xfer, d_scalars_compute);
    }

    // Accumulate the final result
    LOG(INFO, "Accumulate final result");
    ctx->pipp.accumulate_faster(out[batches - 1], *accum_res);
  }
  catch (const cuda_error &e)
  {
#ifdef TAKE_RESPONSIBILITY_FOR_ERROR_MESSAGE
    return RustError{e.code(), e.what()};
#else
    return RustError { e.code() }
#endif
  }

  return RustError{cudaSuccess};
}

#endif //  __CUDA_ARCH__
