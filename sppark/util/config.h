#pragma once
// #if defined(FEATURE_BLS12_381)
// const int NBITS = 255;
// #elif defined(FEATURE_BLS12_377)
// const int NBITS = 253;
// #else
// #error "Unknown curve"
// #endif
#define NBITS 255
#define WNBITS 256
#define WBITS 13
#define NWINS ((NBITS + WBITS -1 ) / WBITS)
#define FREQUENCY NWINS
#define WARP_SZ 32
#define NTHREADS 128

static_assert(NTHREADS >= 32 && (NTHREADS & (NTHREADS - 1)) == 0, "bad NTHREADS value");
static_assert(WARP_SZ >= 32 && (WARP_SZ & (WARP_SZ - 1)) == 0, "bad WARP_SZ value");
static_assert(FREQUENCY >= 1 && FREQUENCY <= NWINS, "bad FREQUENCY value");
const bool LARGE_L1_CODE_CACHE = false;