// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

use ark_bls12_381::G1Affine; // 默认 381
// use ark_bls12_377::G1Affine; // 377
use ark_ec::ProjectiveCurve;
use ark_ff::BigInteger256;
use ark_msm::msm::VariableBaseMSM;
use criterion::{criterion_group, criterion_main, Criterion};

use std::str::FromStr;
use std::time::Instant;

use jy_msm::*;

fn criterion_benchmark(c: &mut Criterion) {
    let bench_npow = std::env::var("BENCH_NPOW").unwrap_or("20".to_string());
    let npoints_npow = i32::from_str(&bench_npow).unwrap();

    // 添加环境 
    let batches_str = std::env::var("BENCHES").unwrap_or("1".to_string());
    let batches = usize::from_str(&batches_str).unwrap();
    // 随机标量bench
    let (points, scalars) =
        util::generate_points_scalars::<G1Affine>(1usize << npoints_npow, batches);
    // 聚集标量bench
    // let (points, scalars) =
    //     util::generate_points_clustered_scalars::<G1Affine>(1usize << npoints_npow, batches, 32);
    // let init_start_time = Instant::now();
    let mut context: MultiScalarMultContext = multi_scalar_mult_init(points.as_slice());
    // let init_end_time = init_start_time.elapsed();
    // let init_time = init_end_time;
    // let init_time_us = init_time.as_micros();
    // println!("precompute init_time: {} us", init_time_us);

    let mut group = c.benchmark_group("CUDA");
    group.sample_size(10);
    let mut msm_result = vec![];
    let name = format!("2**{}x{}", npoints_npow, batches);
    group.bench_function(name, |b| {
        b.iter(|| {
            msm_result = multi_scalar_mult(&mut context, &points.as_slice(), unsafe {
                std::mem::transmute::<&[_], &[BigInteger256]>(scalars.as_slice())
            });
        })
    });
    for b in 0..batches {
        let start = b * points.len();
        let end = (b + 1) * points.len();
        let arkworks_result = VariableBaseMSM::multi_scalar_mul(points.as_slice(), unsafe {
            std::mem::transmute::<&[_], &[BigInteger256]>(&scalars[start..end])
        })
        .into_affine();
        println!("msm_result[{}]: {:?}", b, msm_result[b].into_affine());
        println!("arkworks_result[{}]: {:?}", b, arkworks_result);
        assert_eq!(msm_result[b].into_affine(), arkworks_result);
    }
    group.finish();
}

criterion_group!(benches, criterion_benchmark);
criterion_main!(benches);
