// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

use ark_bls12_381::G1Affine;
use ark_ff::BigInteger256;
use mmsm::*;
use std::str::FromStr;
use correctness_test::correctness_test;
fn main() {
    let test_npow = std::env::var("MAIN_NPOW").unwrap_or("20".to_string());
    let npoints_npow = i32::from_str(&test_npow).unwrap();
    let batches_str = std::env::var("BENCHES").unwrap_or("1".to_string());
    let batches = usize::from_str(&batches_str).unwrap();
    let random_test = std::env::var("RANDOM_TEST").unwrap_or("random".to_string());
    let (points, scalars) = match random_test.as_str() {
        "random" => util::generate_points_scalars::<G1Affine>(1usize << npoints_npow, batches),
        "clusted" => {
            util::generate_points_clustered_scalars::<G1Affine>(1usize << npoints_npow, batches, 32)
        }
        "mixed" => util::generate_mixed_points_scalars::<G1Affine>(1usize << npoints_npow, batches),
        _ => unimplemented!(),
    };

    let mut context = multi_scalar_mult_init(points.as_slice());
    let msm_results = multi_scalar_mult(&mut context, points.as_slice(), unsafe {
        std::mem::transmute::<&[_], &[BigInteger256]>(scalars.as_slice())
    });
    // correctness_test(points, scalars, batches, msm_results);
}
