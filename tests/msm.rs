// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

use ark_bls12_381::G1Affine;
use ark_ec::msm::VariableBaseMSM;
use ark_ec::ProjectiveCurve;
use ark_ff::BigInteger256;

use std::str::FromStr;

use jy_msm::*;

#[test]
fn msm_correctness() {
    let test_npow = std::env::var("TEST_NPOW").unwrap_or("5".to_string());
    let npoints_npow = i32::from_str(&test_npow).unwrap();
    let batches = 1;
    let (points, scalars) =
        util::generate_points_scalars::<G1Affine>(1usize << npoints_npow, batches);

    let mut context = multi_scalar_mult_init(points.as_slice());
    let msm_results = multi_scalar_mult(&mut context, points.as_slice(), unsafe {
        std::mem::transmute::<&[_], &[BigInteger256]>(scalars.as_slice())
    });
    // println!("===========points beign============");
    // for i in 0..points.len() {
    //     println!("points[{}]: {:?}  and {}", i, points[i] ,points[i].to_string());
    // }
    // println!("===========points end============");

    // println!("===========scalars beign============");
    // for i in 0..batches {
    //     println!("bench {}:", i);
    //     for j in 0..scalars.len() {
    //         println!("scalar[{}]: {:?} and {}", j, scalars[j],scalars[j].to_string());
    //     }
    // }

    // todo 没有完成转换
    for b in 0..batches {
        let start = b * points.len();
        let end = (b + 1) * points.len();
        let arkworks_result = VariableBaseMSM::multi_scalar_mul(points.as_slice(), unsafe {
            std::mem::transmute::<&[_], &[BigInteger256]>(&scalars[start..end])
        })
        .into_affine();
        // if arkworks_result != msm_results[b].into_affine(){
        //     println!("第 {} 批次出现问题", b);
        // }
        assert_eq!(arkworks_result, msm_results[b].into_affine());
    }
}
