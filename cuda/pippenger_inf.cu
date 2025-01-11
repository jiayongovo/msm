// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <cub/cub.cuh>
#include <cuda.h>
#include <sys/mman.h>
#include <ec/jacobian_t.hpp>
#include <ec/xyzz_t.hpp>
#include <util/log.h>
#include <util/all_gpus.cpp>
#include <ff/bls12-381.hpp>

typedef jacobian_t<fp_t> point_t;
typedef xyzz_t<fp_t> bucket_t;
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

template <class bucket_t, class affine_t, class scalar_t>
struct MmsmContext
{
  // 识别多块GPU的类型，将原始的points进行分割划分
  std::vector<RustContext<bucket_t, affine_t, scalar_t> *> contexts;
  size_t npoints;
  size_t ffi_affine_sz;
  size_t batches;
  gpus_t gpus;
};

template <class bucket_t, class affine_t, class scalar_t>
struct RustMmsmContext
{
  MmsmContext<bucket_t, affine_t, scalar_t> *context;
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
    cudaStream_t stream = ctx->pipp.default_stream;
    LOG(INFO, "Molloc MSM memory %d", ctx->pipp.get_device());
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
                                       points, ffi_affine_sz, stream);
    LOG(INFO, "Launch kernel pre compute init");
    ctx->pipp.launch_kernel_pre_compute_init(ctx->config, ctx->d_pre_points_sn, stream);
    LOG(INFO, "Get result container faster");
    ctx->fres0 = ctx->pipp.get_result_container_faster();
    ctx->fres1 = ctx->pipp.get_result_container_faster();
    LOG(INFO, "MSM init done");
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
  // stream_t aux_stream(ctx->pipp.get_device());

  try
  {
    for (size_t i = 0; i < batches; i++)
    {
      out[i].set_inf();
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
                                         ctx->h_scalars, stream);
    CUDA_OK(cudaStreamSynchronize(stream));

    for (; work < (int)batches; work++)
    {
      // Launch the GPU kernel, transfer the results back
      batch_pool.spawn([&]()
                       {
        CUDA_OK(cudaStreamSynchronize(stream));
        LOG(INFO, "Launch process scalars");
        ctx->pipp.launch_process_scalars(ctx->config, d_scalars_compute,
                                        ctx->d_scalar_tuples_sn,
                                        ctx->d_point_idx_sn);


        LOG(INFO, "Launch sort");
        
        ctx->pipp.launch_sort(ctx->config, ctx->d_scalar_tuples_sn,
                            ctx->d_scalar_tuples_out_sn, ctx->d_point_idx_sn,
                            ctx->d_point_idx_out_sn,
                            ctx->d_cub_sort_idx);

        // accumulate parts of the buckets into static buffers.
        LOG(INFO, "Launch bucket acc");
        ctx->pipp.launch_bucket_acc(
            ctx->config, ctx->d_scalar_tuples_out_sn,
            ctx->d_point_idx_out_sn, ctx->d_pre_points_sn, ctx->d_buckets_sn,
            ctx->d_buckets_pre_sn, ctx->d_bucket_idx_pre_vector_sn,
            ctx->d_bucket_idx_pre_used_sn, ctx->d_bucket_idx_pre_offset_sn);
        LOG(INFO, "Launch bucket agg");

        ctx->pipp.launch_bucket_agg_1(ctx->config, ctx->d_buckets_sn);

        ctx->pipp.launch_bucket_agg_2(ctx->config, ctx->d_buckets_sn,
                                      ctx->d_res_sn);
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
                                               ctx->h_scalars, stream);
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

extern "C" RustError
mmsm_mult_pippenger_faster_init(RustMmsmContext<bucket_t, affine_t, scalar_t> *context,
                                const affine_t points[], size_t npoints,
                                size_t ffi_affine_sz)
{
  context->context = new MmsmContext<bucket_t, affine_t, scalar_t>();
  MmsmContext<bucket_t, affine_t, scalar_t> *ctx = context->context;
  LOG(INFO, "Init MSM with %d points", npoints);
  ctx->gpus = gpus_t();
  try
  {
    size_t num_gpus = ngpus();
    ctx->ffi_affine_sz = ffi_affine_sz;
    // 根据识别到的设备和points进行划分，根据设备能力进行划分
    size_t chunk_size = (npoints + num_gpus - 1) / num_gpus;
    size_t offset = 0;
    for (size_t i = 0; i < num_gpus; i++)
    {
      auto gpu = ctx->gpus.all()[i];
      select_gpu(gpu->cid());
      RustContext<bucket_t, affine_t, scalar_t> *rust_ctx =
          new RustContext<bucket_t, affine_t, scalar_t>();
      ctx->contexts.push_back(rust_ctx);

      // 当前块GPU实际拿到的点数
      size_t size_for_this_gpu = std::min(chunk_size, npoints - offset);
      if (size_for_this_gpu == 0)
        break;

      // 传入某段 points
      mult_pippenger_faster_init(rust_ctx, points,
                                 size_for_this_gpu, ffi_affine_sz);

      offset += size_for_this_gpu;
    }

    for (size_t i = 0; i < num_gpus; i++)
    {
      auto gpu = ctx->gpus.all()[i];
      select_gpu(gpu->cid());
    }
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

extern "C" RustError
mmsm_mult_pippenger_faster_inf(RustMmsmContext<bucket_t, affine_t, scalar_t> *context,
                               point_t *out, const affine_t points[], size_t npoints,
                               size_t batches, const scalar_t scalars[],
                               size_t ffi_affine_sz)
{
  (void)points; // Silence unused param warning

  MmsmContext<bucket_t, affine_t, scalar_t> *ctx = context->context;
  try
  {
    size_t num_gpus = ngpus();

    size_t chunk_size = (npoints + num_gpus - 1) / num_gpus;
    size_t offset = 0;
    point_t *host_results = new point_t[num_gpus];
    for (size_t i = 0; i < num_gpus; i++)
    {
      auto gpu = ctx->gpus.all()[i];
      select_gpu(gpu->cid());
      RustContext<bucket_t, affine_t, scalar_t> *rust_ctx = ctx->contexts[i];

      size_t size_for_this_gpu = std::min(chunk_size, npoints - offset);
      if (size_for_this_gpu == 0)
        break;

      host_results[i].set_inf();
      mult_pippenger_faster_inf(rust_ctx, &host_results[i], points + offset, size_for_this_gpu, batches, scalars + offset, ffi_affine_sz);

      offset += size_for_this_gpu;
    }

    // for (size_t i = 0; i < num_gpus; i++)
    // {
    //   auto gpu = ctx->gpus.all()[i];
    //   select_gpu(gpu->cid());
    //   cudaDeviceSynchronize();
    // }

    // 在CPU上累加结果
    for (size_t i = 0; i < num_gpus; i++)
    {
      out->add(host_results[i]);
    }

    delete[] host_results;
  }
  catch (const cuda_error &e)
  {
#ifdef TAKE_RESPONSIBILITY_FOR_ERROR_MESSAGE
    return RustError{e.code(), e.what()};
#else
    return RustError{e.code()};
#endif
  }

  return RustError{cudaSuccess};
}

#endif //  __CUDA_ARCH__
