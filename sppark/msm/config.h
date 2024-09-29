// config.h
#ifndef CONFIG_H
#define CONFIG_H

const int WARP_SZ = 32;

const int NTHREADS = 128;
static_assert(NTHREADS >= 32 && (NTHREADS & (NTHREADS - 1)) == 0, "bad NTHREADS value");

#if defined(FEATURE_BLS12_381)
const int NBITS = 255;
#elif defined(FEATURE_BLS12_377)
const int NBITS = 253;
#else
#error "no nbits"
#endif

const int FREQUENCY = 8;
const int WBITS = 16;
const int NWINS = 16; // ((NBITS + WBITS - 1) / WBITS)   // ceil(NBITS/WBITS)

static_assert(FREQUENCY <= NWINS && FREQUENCY >= 1, "bad FREQUENCY value");

const bool LARGE_L1_CODE_CACHE = false;

#endif // CONFIG_H
