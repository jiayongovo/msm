// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

use ark_bls12_381::G1Affine;
use ark_ec::AffineCurve;
// use ark_bls12_377::G1Affine; // 377
use std::{convert::TryInto, str::FromStr};
use ark_ed_on_bls12_381::EdwardsAffine;

use mmsm::*;

fn main() {
    let run_npow = 20;
    let batches = 1;
    let (points, scalars) = util::generate_mixed_points_scalars::<EdwardsAffine>(1usize << run_npow, batches);
    // let mut context = multi_scalar_mult_init(points.as_slice());
    // let msm_res = multi_scalar_mult(&mut context, points.as_slice(), unsafe {
    //     std::mem::transmute::<&[_], &[BigInteger256]>(scalars.as_slice())
    // });

    let test_npow = 20;
    let test_batch = 1;
    let (test_points,test_scalars) = util::generate_mixed_points_scalars::<G1Affine>(1usize << test_npow, test_batch);

    println!("[INFO] Test scalars: {:?}", test_scalars[0]);
    println!("[INFO] scalars: {:?}", scalars[0]);

    println!("[INFO] MSM test points: {:?}", test_points[0]);
    println!("[INFO] MSM points: {:?}", points[0]);
}
