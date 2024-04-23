// Copyright Supranational LLC
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

use ark_bls12_381::G1Affine;
use ark_ec::msm::VariableBaseMSM;
use ark_ec::ProjectiveCurve;
use ark_ff::{BigInteger256, ToConstraintField};

use std::str::FromStr;

use jy_msm::*;

#[test]
fn msm_correctness() {
    let test_npow = std::env::var("TEST_NPOW").unwrap_or("5".to_string());
    let npoints_npow = i32::from_str(&test_npow).unwrap();
    let batches = 100;
    let (points, scalars) =
        util::generate_points_scalars::<G1Affine>(1usize << npoints_npow, batches);

    let mut context = multi_scalar_mult_init(points.as_slice());
    let msm_results = multi_scalar_mult(&mut context, points.as_slice(), unsafe {
        std::mem::transmute::<&[_], &[BigInteger256]>(scalars.as_slice())
    });

    // let mut scalars = [BigInteger256::new([
    //     16216263349635534264,
    //     15664681092332222065,
    //     7626266897985184949,
    //     6484672805044197739,
    // ]); 32];
    // scalars[0] = BigInteger256::new([16216263349635534264, 15664681092332222065, 7626266897985184949, 6484672805044197739]);
    // scalars[1] = BigInteger256::new([6374940512951501968, 15748844575639818241, 15414694671438995184, 714067625220903206]);
    // scalars[2] = BigInteger256::new([17005861931591228590, 7130170044400254262, 12975837569963428900, 3995540807181246187]);
    // scalars[3] = BigInteger256::new([6583019371682957120, 16841268807163744160, 9414268603650190992, 5470984689107101035]);
    // scalars[4] = BigInteger256::new([11386359890144092135, 1147055280421771354, 847049832689160614, 5400555142572011733]);
    // scalars[5] = BigInteger256::new([17179112414766999562, 4928623757875394273, 11249420866335815792, 7664464255136568442]);
    // scalars[6] = BigInteger256::new([16122735174912117060, 13138870834588368813, 10404586619618591592, 5540813946931809888]);
    // scalars[7] = BigInteger256::new([15930897433791926327, 13990623268536313409, 4079417416985931711, 5620323104494394956]);
    // scalars[8] = BigInteger256::new([12794431176920526251, 6357771460759075049, 13670752346888298631, 7368537884214310150]);
    // scalars[9] = BigInteger256::new([2335714286551936330, 18148792336649252649, 14818750497631311935, 7998061606949808209]);
    // scalars[10] = BigInteger256::new([8447482183832890021, 15411669865631590081, 5005074130585611155, 5598645544538597843]);
    // scalars[11] = BigInteger256::new([7292163968699804540, 498408923308626898, 1157697632232356100, 6962465460449398228]);
    // scalars[12] = BigInteger256::new([13447878538715027698, 7182144420777310497, 17180468065606877437, 7865123059761711125]);
    // scalars[13] = BigInteger256::new([18229933250205292726, 47318021983033507, 7339197494945942150, 2511458230354677726]);
    // scalars[14] = BigInteger256::new([6399279985979397295, 195597098971313282, 6689914254691987357, 3746575249121307217]);
    // scalars[15] = BigInteger256::new([8259003003613910865, 17076743963956474860, 17258215579222279344, 7986266849229156023]);
    // scalars[16] = BigInteger256::new([4618660977720279503, 3435989892314480818, 1201791281159361931, 4768861437126000395]);
    // scalars[17] = BigInteger256::new([4397709642668703952, 17568759861619883967, 7939990298278490947, 219455574726163089]);
    // scalars[18] = BigInteger256::new([8184219070196705129, 10309635887400016141, 1840059803228378013, 1135390908019947760]);
    // scalars[19] = BigInteger256::new([620470418701746693, 14604860218454828508, 16166875208249264921, 4764185270456131249]);
    // scalars[20] = BigInteger256::new([12293443845891500570, 3568664078462101609, 3094988018169963881, 1529228411683552862]);
    // scalars[21] = BigInteger256::new([2593479639017376871, 14107363584706854376, 3980929624226858414, 6955524286155300412]);
    // scalars[22] = BigInteger256::new([1078966143092302018, 14014451782357032510, 15167673619915926408, 1305406158495266666]);
    // scalars[23] = BigInteger256::new([3408776386119283932, 772590169060453940, 5944474869927335436, 2518217850136829868]);
    // scalars[24] = BigInteger256::new([12186805302322148194, 5397766396866118117, 1286400039290349065, 12473858213657363]);
    // scalars[25] = BigInteger256::new([4222888513970641310, 6470932664362762240, 5644710842409649695, 4363764347158905687]);
    // scalars[26] = BigInteger256::new([4152651523303216837, 12159290502809102550, 946729210810077773, 6387604232672542970]);
    // scalars[27] = BigInteger256::new([4013865385085618542, 3211745543959135698, 4610343782239812346, 1817279969141224060]);
    // scalars[28] = BigInteger256::new([8555509543528364264, 17235009192425663064, 14914547738413831536, 7851891839061380234]);
    // scalars[29] = BigInteger256::new([17403522767558236818, 9983795029877295031, 6881797802194629869, 3913529201039952448]);
    // scalars[30] = BigInteger256::new([3414014116536191969, 537868926796856752, 6733483066437204638, 5401895003828002121]);
    // scalars[31] = BigInteger256::new([12247974729265967748, 17785987365516517758, 7726225532640525801, 1215778371130875798]);


    //println!("scalar[0] is {:?}", scalars[0]);
    
    //let msm_results = multi_scalar_mult(&mut context, points.as_slice(), &scalars);
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
        if arkworks_result != msm_results[b].into_affine() {
            println!("第 {} 批次出现问题", b);
            println!("scalars beign");
            for j in b * points.len()..(b + 1) * points.len() {
                println!("{:?}", scalars[j]);
            }
            println!("scalars end");
            println!("points beign");
            for j in 0..points.len() {
                println!("{:?}", points[j]);
            }
        }
        // assert_eq!(arkworks_result, msm_results[b].into_affine());
    }
}
