// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

use ark_bls12_381::G1Affine; // 默认 381
                             // use ark_bls12_377::G1Affine; // 377
use ark_ff::BigInteger256;
use criterion::{criterion_group, criterion_main, Criterion};

use std::str::FromStr;

use jy_msm::*;

fn criterion_benchmark(c: &mut Criterion) {
    let bench_npow = std::env::var("BENCH_NPOW").unwrap_or("17".to_string());
    let npoints_npow = i32::from_str(&bench_npow).unwrap();
    let batches_str = std::env::var("BENCHES").unwrap_or("1".to_string());
    let batches = usize::from_str(&batches_str).unwrap();
    let random_bench = std::env::var("RANDOM_BENCH").unwrap_or("mixed".to_string());
    let (points, scalars) = match random_bench.as_str() {
        "true" => util::generate_points_scalars::<G1Affine>(1usize << npoints_npow, batches),
        "mixed" => util::generate_mixed_points_scalars::<G1Affine>(1usize << npoints_npow, batches),
        _ => {
            util::generate_points_clustered_scalars::<G1Affine>(1usize << npoints_npow, batches, 32)
        }
    };

    let mut context: MultiScalarMultContext = multi_scalar_mult_init(points.as_slice());

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
    group.finish();
}

criterion_group!(benches, criterion_benchmark);
criterion_main!(benches);
