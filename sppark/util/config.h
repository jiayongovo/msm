#pragma once
#if defined(FEATURE_BLS12_381)
const int NBITS = 255;
#elif defined(FEATURE_BLS12_377)
const int NBITS = 253;
#else
#error "Unknown curve"
#endif
extern const size_t WBITS = 16;
extern const size_t NWINS = 16;
extern const size_t FREQUENCY = 16;
extern const size_t WARP_SZ = 32;
extern const size_t NTHREADS = 128;
static_assert(NTHREADS >= 32 && (NTHREADS & (NTHREADS - 1)) == 0, "bad NTHREADS value");
const bool LARGE_L1_CODE_CACHE = false;