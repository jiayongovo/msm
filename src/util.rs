// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

use ark_ff::Zero;
use rand::SeedableRng;
use rand_chacha::ChaCha20Rng;

use ark_ec::{AffineCurve, ProjectiveCurve};
use ark_std::vec::Vec;
use ark_std::UniformRand;


pub fn generate_points_scalars<G: AffineCurve>(
    len: usize,
    batch_size: usize,
) -> (Vec<G>, Vec<G::ScalarField>) {
    let rand_gen: usize = 1 << 11;
    let mut rng = ChaCha20Rng::from_entropy();

    let mut points = <G::Projective as ProjectiveCurve>::batch_normalization_into_affine(
        &(0..rand_gen)
            .map(|_| G::Projective::rand(&mut rng))
            .collect::<Vec<_>>(),
    );

    // Sprinkle in some infinity points
    // points[1] = G::zero();
    // points[10] = G::zero();
    while points.len() < len {
        points.append(&mut points.clone());
    }

    let points = &points[0..len];

    let scalars = (0..len * batch_size)
        .map(|_| G::ScalarField::rand(&mut rng))
        .collect::<Vec<_>>();

    (points.to_vec(), scalars)
}

pub fn generate_points_clustered_scalars<G: AffineCurve>(
    len: usize,
    batch_size: usize,
    cluster: usize,
) -> (Vec<G>, Vec<G::ScalarField>) {
    let rand_gen: usize = 1 << 11;
    let mut rng = ChaCha20Rng::from_entropy();

    let mut points = <G::Projective as ProjectiveCurve>::batch_normalization_into_affine(
        &(0..rand_gen)
            .map(|_| G::Projective::rand(&mut rng))
            .collect::<Vec<_>>(),
    );

    while points.len() < len {
        points.append(&mut points.clone());
    }

    let points = &points[0..len];

    let mut scalars = (0..cluster)
        .map(|_| G::ScalarField::rand(&mut rng))
        .collect::<Vec<_>>();

    while scalars.len() < batch_size * len {
        scalars.append(&mut scalars.clone());
    }

    let points = &points[0..len];
    (points.to_vec(), scalars)
}

pub fn generate_zero_points_scalars<G:AffineCurve>(
    len: usize,
    batch_size: usize
) -> (Vec<G>,Vec<G::ScalarField>){
    let rand_gen: usize = 1 << 11;
    let mut rng = ChaCha20Rng::from_entropy();

    let mut points = <G::Projective as ProjectiveCurve>::batch_normalization_into_affine(
        &(0..rand_gen)
            .map(|_| G::Projective::rand(&mut rng))
            .collect::<Vec<_>>(),
    );
    for i in 0..points.len(){
            points[i] = G::zero();
    }
    while points.len() < len {
        points.append(&mut points.clone());
    }

    let points = &points[0..len];

    let mut scalars = (0..len * batch_size)
        .map(|_| G::ScalarField::rand(&mut rng))
        .collect::<Vec<_>>();
    for i in 0..scalars.len(){
        scalars[i] = G::ScalarField::zero();
    }
    (points.to_vec(), scalars)
}

pub fn generate_mixed_points_scalars<G:AffineCurve>(
    len: usize,
    batch_size: usize
) -> (Vec<G>,Vec<G::ScalarField>){
    let rand_gen: usize = 1 << 11;
    let seed = [
        1, 0, 52, 0, 0, 0, 0, 0, 1, 0, 10, 0, 22, 32, 0, 0, 2, 0, 55, 49, 0, 11, 0, 0, 3, 0, 0, 0, 0,
        0, 2, 92,
    ];
    let mut rng = ChaCha20Rng::from_seed(seed);

    let mut points = <G::Projective as ProjectiveCurve>::batch_normalization_into_affine(
        &(0..rand_gen)
            .map(|_| G::Projective::rand(&mut rng))
            .collect::<Vec<_>>(),
    );
    while points.len() < len {
        points.append(&mut points.clone());
    }

    let points = &points[0..len];

    let scalars = (0..len * batch_size)
        .map(|_| G::ScalarField::rand(&mut rng))
        .collect::<Vec<_>>();
    (points.to_vec(), scalars)
}