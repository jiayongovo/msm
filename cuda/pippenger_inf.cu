// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <cuda.h>
#include <sys/mman.h>
#include <cub/cub.cuh>

#include <ff/bls12-381.hpp>
#include <ec/jacobian_t.hpp>
#include <ec/xyzz_t.hpp>

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
    cub::DeviceRadixSort::SortPairs(d_temp, temp_size,
                                    d_scalar_tuple, d_scalar_tuple_out,
                                    d_point_idx, d_point_idx_out, 1);
    cub::DeviceSegmentedRadixSort::SortPairs(d_temp, temp_size,
                                             d_scalar_tuple, d_scalar_tuple_out,
                                             d_point_idx, d_point_idx_out, 1, 1, d_offset_a, d_offset_b);
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
    // pippenger
    pipp_t pipp;
    // MSMConfig
    typename pipp_t::MSMConfig config;
    // 仿射点大小
    size_t ffi_affine_sz;
    // 预计算 point 包括 原始 point
    // p1 p2 p3 ... pn   2^2c p1  2^2c p2  ...  2^2c pn ....
    size_t d_pre_points_sn;
    // 批次数
    size_t d_scalars_sn[NUM_BATCH_THREADS];
    // 桶索引
    size_t d_buckets_sn;
    // 标量数组索引
    // k1,1 k2,1,...,kn,1   k1,2,k2,2 ,...kn,2  ...  k1,lambda/c...kn,lambda/c
    size_t jy_d_scalar_tuples_sn;
    // 标量对应点索引
    // p1,p2,p3,..,...pn   p1,p2,...,pn     ...      p1,p2,...,pn
    size_t jy_d_point_idx_sn;
    // 排序标量索引
    // 对每个窗口进行排序后的值
    size_t jy_d_scalar_tuples_out_sn;
    // 与之相对应的 point 索引
    size_t jy_d_point_idx_out_sn;
    // 用于负载平衡的 buffer
    // buffer
    size_t d_buckets_pre_sn;
    // buffer index
    size_t d_bucket_idx_pre_vector_sn;
    // buffer used
    size_t d_bucket_idx_pre_used_sn;
    // buffer offest
    size_t d_bucket_idx_pre_offset_sn;
    // res
    size_t d_res_sn;

    size_t d_st_sn;
    size_t d_sost_sn;
    // point => buffer index
    size_t d_bucket_idx_sn;
    // cub
    size_t d_cub_sort_idx;
    // host scalars
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
extern "C" RustError mult_pippenger_faster_init(RustContext<bucket_t, affine_t, scalar_t> *context,
                                                const affine_t points[], size_t npoints,
                                                size_t ffi_affine_sz)
{
    context->context = new Context<bucket_t, affine_t, scalar_t>();
    Context<bucket_t, affine_t, scalar_t> *ctx = context->context;
    ctx->ffi_affine_sz = ffi_affine_sz;
    try
    {
        ctx->config = ctx->pipp.init_msm_faster(npoints);

        // Allocate GPU storage
        // 分配预计算点空间
        ctx->d_pre_points_sn = ctx->pipp.allocate_d_pre_points(ctx->config);
        //
        for (size_t i = 0; i < NUM_BATCH_THREADS; i++)
        {
            ctx->d_scalars_sn[i] = ctx->pipp.allocate_d_scalars(ctx->config);
        }
        // 分配桶空间
        ctx->d_buckets_sn = ctx->pipp.allocate_d_buckets();
        // 静态 bucket
        ctx->d_buckets_pre_sn = ctx->pipp.allocate_d_buckets_pre(ctx->config);
        // buffer_index
        ctx->d_bucket_idx_pre_vector_sn = ctx->pipp.allocate_d_bucket_idx_pre_vector(ctx->config);
        // buffer_used
        ctx->d_bucket_idx_pre_used_sn = ctx->pipp.allocate_d_bucket_idx_pre_used(ctx->config);
        // buffer_offset
        ctx->d_bucket_idx_pre_offset_sn = ctx->pipp.allocate_d_bucket_idx_pre_offset(ctx->config);

        ctx->d_st_sn = ctx->pipp.allocate_d_st(ctx->config);
        ctx->d_sost_sn = ctx->pipp.allocate_d_sost(ctx->config);
        // 返回值 NWIN * bucket
        ctx->d_res_sn = ctx->pipp.allocate_d_res();
        // 分配符号变换空间
        ctx->jy_d_scalar_tuples_sn = ctx->pipp.allocate_jy_d_scalar_tuple(ctx->config);
        ctx->jy_d_point_idx_sn = ctx->pipp.allocate_jy_d_point_idx(ctx->config);
        ctx->jy_d_scalar_tuples_out_sn = ctx->pipp.allocate_jy_d_scalar_tuple_out(ctx->config);
        ctx->jy_d_point_idx_out_sn = ctx->pipp.allocate_jy_d_point_idx(ctx->config);
        // 分配桶索引空间
        ctx->d_bucket_idx_sn = ctx->pipp.allocate_d_bucket_idx(ctx->config);
        // CUB 排序
        ctx->d_cub_sort_idx = ctx->pipp.allocate_d_cub_sort_faster(ctx->config);

        // Allocate pinned memory on host
        CUDA_OK(cudaMallocHost(&ctx->h_scalars, ctx->pipp.get_size_scalars(ctx->config)));

        // 传输到预计算点那组
        ctx->pipp.transfer_bases_to_device(ctx->config, ctx->d_pre_points_sn, points,
                                           ffi_affine_sz);
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
extern "C" RustError mult_pippenger_faster_inf(RustContext<bucket_t, affine_t, scalar_t> *context,
                                               point_t *out, const affine_t points[],
                                               size_t npoints, size_t batches,
                                               const scalar_t scalars[],
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
        // 每次执行两批
        // 一批传送
        // 一批计算
        size_t d_scalars_xfer = ctx->d_scalars_sn[0];
        size_t d_scalars_compute = ctx->d_scalars_sn[1];

        channel_t<size_t> ch;
        size_t scalars_sz = ctx->pipp.get_size_scalars(ctx->config);

        int work = 0;
        // 复制第 0 批标量到h_scalars
        memcpy(ctx->h_scalars, &scalars[work * npoints], scalars_sz);
        // 把计算点传送到设备中
        ctx->pipp.transfer_scalars_to_device(ctx->config, d_scalars_compute,
                                             ctx->h_scalars, aux_stream);
        CUDA_OK(cudaStreamSynchronize(aux_stream));

        for (; work < (int)batches; work++)
        {
            // Launch the GPU kernel, transfer the results back
            batch_pool.spawn([&]()
                             {

                CUDA_OK(cudaStreamSynchronize(aux_stream));
                // 进行标量变换，{2^c}k_{i,j} => {2^{c-1}}k_{i,j} | sign 获得对应 point_idx
                // k1,1|sign k2,1|sign ...kn,1|sign , ... , k1,[lambda/c]|sign k2,[lambda/c]|sign ... kn,[lambda/c]|sign
                // p1,p2,.. pn    p1,p2,pn    p1,p2,pn ...
                //printf("begin launch_jy_process_scalar_1\n");
                ctx->pipp.launch_jy_process_scalar_1(ctx->config, d_scalars_compute,
                                                  ctx->jy_d_scalar_tuples_sn,
                                                  ctx->jy_d_point_idx_sn
                                                  );
                //printf("end launch_jy_process_scalar_1\n");

                // scalar point
                uint32_t* jy_d_scalar_tuple = ctx->pipp.jy_d_scalar_tuple_ptrs[ctx->jy_d_scalar_tuples_sn];
                uint32_t* jy_d_scalar_tuple_out = ctx->pipp.jy_d_scalar_tuple_ptrs[ctx->jy_d_scalar_tuples_out_sn];
                uint32_t* jy_d_point_idx = ctx->pipp.jy_d_point_idx_ptrs[ctx->jy_d_point_idx_sn];
                uint32_t* jy_d_point_idx_out = ctx->pipp.jy_d_point_idx_ptrs[ctx->jy_d_point_idx_out_sn];
                uint32_t nscalars = npoints;
                // 主要是为了获取空间大小
                void *d_temp = NULL;
                size_t temp_sort_size = 0;
                // 暂时先将最低1位到最高31位获取sij
                cub::DeviceRadixSort::SortPairs(d_temp, temp_sort_size,
                                                jy_d_scalar_tuple, jy_d_scalar_tuple_out,
                                                jy_d_point_idx, jy_d_point_idx_out, nscalars, 0, 31, stream);
                void *d_cub_sort = (void *)ctx->pipp.d_cub_ptrs[ctx->d_cub_sort_idx];
                //printf("begin cub::DeviceRadixSort::SortPairs\n");
                // 在每个窗口内进行排序
                for(size_t k = 0; k < NWINS; k++)
                {
                    size_t ptr = k * nscalars;
                    cub::DeviceRadixSort::SortPairs(d_cub_sort, temp_sort_size,
                                                    jy_d_scalar_tuple + ptr, jy_d_scalar_tuple_out + ptr,
                                                    jy_d_point_idx + ptr, jy_d_point_idx_out + ptr, nscalars, 0, 31, stream);
                }
                //printf("end cub::DeviceRadixSort::SortPairs\n");
                //printf("begin launch_jy_process_scalar_2\n");
                // 获得 bucket index
                ctx->pipp.launch_process_scalar_2(ctx->config,
                                                  ctx->jy_d_scalar_tuples_out_sn, ctx->d_bucket_idx_sn);

                //printf("end launch_jy_process_scalar_2\n");

                // accumulate parts of the buckets into static buffers.
                // 预计算点
                //printf("begin launch_bucket_acc\n");
                ctx->pipp.launch_bucket_acc(ctx->config, ctx->jy_d_scalar_tuples_out_sn,
                                            ctx->d_bucket_idx_sn, ctx->jy_d_point_idx_out_sn,
                                            ctx->d_pre_points_sn, ctx->d_buckets_sn,
                                            ctx->d_buckets_pre_sn, ctx->d_bucket_idx_pre_vector_sn,
                                            ctx->d_bucket_idx_pre_used_sn, ctx->d_bucket_idx_pre_offset_sn);
                //printf("end launch_bucket_acc\n");

                //printf("begin launch_bucket_agg_1\n");
                ctx->pipp.launch_bucket_agg_1(ctx->config, ctx->d_buckets_sn);
                //printf("end launch_bucket_agg_1\n");
                //printf("begin launch_bucket_agg_2\n");
                ctx->pipp.launch_bucket_agg_2(ctx->config, ctx->d_buckets_sn,ctx->d_res_sn,ctx->d_st_sn,ctx->d_sost_sn);
                //printf("end launch_bucket_agg_2\n");

                // ctx->pipp.synchronize_stream();
                //printf("begin transfer_res_to_host_faster\n");
                ctx->pipp.transfer_res_to_host_faster(*kernel_res, ctx->d_res_sn);
                //printf("end transfer_res_to_host_faster\n");
                ctx->pipp.synchronize_stream();
                
                ch.send(work); });

            // Transfer the next set of scalars, Faccumulate the previous result
            batch_pool.spawn([&]()
                             {
                // Start next scalar transfer
                if (work + 1 < (int)batches) {
                    // Copy into pinned memory
                    memcpy(ctx->h_scalars, &scalars[(work + 1) * npoints], scalars_sz);

                    ctx->pipp.transfer_scalars_to_device(ctx->config,
                                                         d_scalars_xfer, ctx->h_scalars,
                                                         aux_stream);
                }
                // Accumulate the previous result
                if (work - 1 >= 0) {
                    ctx->pipp.accumulate_faster(out[work - 1], *accum_res);

		    
                }
                ch.send(work); });
            ch.recv();
            ch.recv();
            std::swap(kernel_res, accum_res);
            std::swap(d_scalars_xfer, d_scalars_compute);
        }

        // Accumulate the final result
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
