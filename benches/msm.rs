// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

use ark_ec::ProjectiveCurve;
use ark_msm::msm::VariableBaseMSM;
use criterion::{criterion_group, criterion_main, Criterion};
use ark_bls12_381::G1Affine;
use ark_ff::BigInteger256;
use rayon::vec;

use std::str::FromStr;

use jy_msm::*;

fn criterion_benchmark(c: &mut Criterion) {
    let bench_npow = std::env::var("BENCH_NPOW").unwrap_or("22".to_string());
    let npoints_npow = i32::from_str(&bench_npow).unwrap();

    let batches = 1;
    let (points, scalars) =
        util::generate_points_clustered_scalars::<G1Affine>(1usize << npoints_npow, batches,32);
    // let (points, scalars) =
    //     util::generate_points_scalars::<G1Affine>(1usize << npoints_npow, batches);
    let mut context: MultiScalarMultContext = multi_scalar_mult_init(points.as_slice());

    let mut group = c.benchmark_group("CUDA");
    group.sample_size(10);
    let mut res = vec![];
    let name = format!("2**{}x{}", npoints_npow, batches);
    group.bench_function(name, |b| {
        b.iter(|| {
            res = multi_scalar_mult(&mut context, &points.as_slice(), unsafe {
                std::mem::transmute::<&[_], &[BigInteger256]>(scalars.as_slice())
            });
        })
    });
    for b in 0..batches {
        println!("res[{}]: {:?}", b, res[b].into_affine());
        let start = b * points.len();
        let end = (b + 1) * points.len();
        let arkworks_result = VariableBaseMSM::multi_scalar_mul(points.as_slice(), unsafe {
            std::mem::transmute::<&[_], &[BigInteger256]>(&scalars[start..end])
        })
        .into_affine();
        println!("arkworks_result[{}]: {:?}", b, arkworks_result);
        assert_eq!(res[b].into_affine(),arkworks_result);
    }
    group.finish();
}

criterion_group!(benches, criterion_benchmark);
criterion_main!(benches);
