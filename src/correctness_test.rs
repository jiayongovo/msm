use ark_bls12_381::G1Affine;
use ark_bls12_381::G1Projective;
// 默认 381
use ark_ec::ProjectiveCurve;
use ark_ff::BigInteger256;
use ark_msm::msm::VariableBaseMSM;
use ark_msm::types::G1ScalarField;

#[warn(dead_code)]
pub fn correctness_test(
    points: Vec<G1Affine>,
    scalars: Vec<G1ScalarField>,
    batches: usize,
    msm_result: Vec<G1Projective>,
) {
    for b in 0..batches {
        let start = b * points.len();
        let end = (b + 1) * points.len();

        let arkworks_result = VariableBaseMSM::multi_scalar_mul(points.as_slice(), unsafe {
            std::mem::transmute::<&[_], &[BigInteger256]>(&scalars[start..end])
        })
        .into_affine();
        println!("msm_result: {:?}", msm_result[b].into_affine());
        println!("arkworks_result: {:?}", arkworks_result);
        assert_eq!(msm_result[b].into_affine(), arkworks_result);
    }
}
