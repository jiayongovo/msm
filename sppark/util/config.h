#pragma once
// #if defined(FEATURE_BLS12_381)
// const int NBITS = 255;
// #elif defined(FEATURE_BLS12_377)
// const int NBITS = 253;
// #else
// #error "Unknown curve"
// #endif
const int NBITS = 255;
extern const size_t WBITS = 8;
extern const size_t NWINS = (NBITS + WBITS - 1)/ WBITS;
// extern const size_t WARP_SZ = 32;
extern const size_t NTHREADS = 128;
static_assert(NTHREADS >= 32 && (NTHREADS & (NTHREADS - 1)) == 0, "bad NTHREADS value");
static_assert(WARP_SZ >= 32 && (WARP_SZ & (WARP_SZ - 1)) == 0, "bad WARP_SZ value");
const bool LARGE_L1_CODE_CACHE = false;