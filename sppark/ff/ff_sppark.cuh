#include <cuda_runtime_api.h>

namespace ff_sppark
{
    const int THREADS_PER_BLOCK = 32;
    const int ITEMS_PER_THREAD = 4;
    const int LEN_A = 8;
    const int LEN_B = 8;
    const int LEN_RESULT = LEN_A + LEN_B;


    __device__ __forceinline__ void ff_sppark_calc_kernel(uint32_t *a, uint32_t *b, uint32_t *result, size_t n)
    {
        auto warp_id = blockIdx.x;
        auto lane_id = threadIdx.x;
        __shared__ uint32_t shared_b[LEN_B];
        if (lane_id < LEN_B)
        {
            shared_b[lane_id] = b[lane_id];
        }
        __syncwarp();
        for (size_t item_idx = warp_id * THREADS_PER_BLOCK * ITEMS_PER_THREAD + lane_id;
             item_idx < n;
             item_idx += gridDim.x * THREADS_PER_BLOCK * ITEMS_PER_THREAD)
        {
            for (int item_offset = 0; item_offset < ITEMS_PER_THREAD; item_offset++)
            {
                size_t i = item_idx + item_offset * THREADS_PER_BLOCK;
                if (i >= n)
                    break;
                uint32_t temp_a[LEN_A];
                uint32_t temp_result[LEN_RESULT] = {0};
#pragma unroll
                for (int j = 0; j < LEN_A; j += 4)
                {
                    uint4 vec = *reinterpret_cast<uint4 *>(a + i * LEN_A + j);
                    temp_a[j] = vec.x;
                    temp_a[j + 1] = vec.y;
                    temp_a[j + 2] = vec.z;
                    temp_a[j + 3] = vec.w;
                }
#pragma unroll
                for (int j = 0; j < LEN_A; j++)
                {
                    uint32_t carry = 0;
#pragma unroll
                    for (auto k = 0; k < LEN_B; k++)
                    {
                        uint64_t temp = (uint64_t)temp_a[j] * shared_b[k] + temp_result[j + k] + carry;
                        temp_result[j + k] = temp & 0xFFFFFFFF;
                        carry = temp >> 32;
                    }
                    temp_result[j + LEN_B] = carry;
                }
#pragma unroll
                for (int j = 0; j < LEN_RESULT; j += 4)
                {
                    if (j + 3 < LEN_RESULT)
                    {
                        uint4 vec;
                        vec.x = temp_result[j];
                        vec.y = temp_result[j + 1];
                        vec.z = temp_result[j + 2];
                        vec.w = temp_result[j + 3];
                        *reinterpret_cast<uint4 *>(result + i * LEN_RESULT + j) = vec;
                    }
                    else
                    {
                        for (int k = j; k < LEN_RESULT; k++)
                        {
                            result[i * LEN_RESULT + k] = temp_result[k];
                        }
                    }
                }
            }
        }
    }
}
