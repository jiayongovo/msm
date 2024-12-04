// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

use ark_bls12_381::G1Affine;
// use ark_bls12_377::G1Affine; // 377
// use ark_ec::msm::VariableBaseMSM;
use ark_ff::BigInteger256;
use std::str::FromStr;
use mmsm::*;

fn main() {
    let run_npow = std::env::var("RUN_NPOW").unwrap_or("22".to_string());
    let npoints_npow = i32::from_str(&run_npow).unwrap();
    let batches_str = std::env::var("BENCHES").unwrap_or("1".to_string());
    let batches = usize::from_str(&batches_str).unwrap();
    let random_test = std::env::var("RANDOM_TEST").unwrap_or("mixed".to_string());
    let (points, scalars) = match random_test.as_str() {
        "true" => util::generate_points_scalars::<G1Affine>(1usize << npoints_npow, batches),
        "zero" => util::generate_zero_points_scalars::<G1Affine>(1usize << npoints_npow, batches),
        "mixed" => util::generate_mixed_points_scalars::<G1Affine>(1usize << npoints_npow, batches),
        _ => {
            util::generate_points_clustered_scalars::<G1Affine>(1usize << npoints_npow, batches, 32)
        }
    };
    let mut context = multi_scalar_mult_init(points.as_slice());
    let msm_res = multi_scalar_mult(&mut context, points.as_slice(), unsafe {
        std::mem::transmute::<&[_], &[BigInteger256]>(scalars.as_slice())
    });
    println!("[INFO] MSM result: {:?}", msm_res);
    println!("[INFO] msm complete!");
}
