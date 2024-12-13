// // Copyright Supranational LLC
// // Licensed under the Apache License, Version 2.0, see LICENSE for details.
// // SPDX-License-Identifier: Apache-2.0

// #pragma once

// #ifndef __CUDA_ARCH__
// #undef __host__
// #define __host__
// #undef __device__
// #define __device__
// #undef __noinline__
// #define __noinline__
// #endif

// template <class field_t>
// class xyzt_t
// {
//     field_t X, Y, Z, T;
//     const field_t a = field_t::one();
//     const field_t d = field_t::one();

// public:
// #ifdef __NVCC__
//     class affine_inf_t
//     {
//         friend xyzt_t;
//         field_t X, Y;
//         int inf[sizeof(field_t) % 16 ? 2 : 4];

//     public:
//         inline __device__ bool is_inf() const
//         {
//             return inf[0] & 1 != 0;
//         };
//         inline __device__ void affine_inf_set_inf()
//         {
//             inf[0] = 1;
//             return *this;
//         }
//     };
//     inline __device__ xyzt_t &operator=(const affine_inf_t &a)
//     {
//         X = a.X;
//         Y = a.Y;
//         if (a.is_inf())
//         {
//             Z.zero();
//         }
//         else
//         {
//             Z = field_t::one();
//             T = X * Y;
//         }
//         return *this;
//     }
// #else
//     class affine_inf_t
//     {
//         friend xyzt_t;
//         field_t X, Y;
//         bool inf;

//         inline __device__ bool is_inf() const
//         {
//             return inf;
//         }
//     };
// #endif

//     class affine_t
//     {
//         friend xyzt_t;
//         field_t X, Y;

//         inline __device__ bool is_inf() const
//         {
//             return (bool)(X.is_zero() & Y.is_zero());
//         }

//     public:
//         inline affine_t &operator=(const xyzt_t &a)
//         {
//             X = a.X / a.Z;
//             Y = a.X / a.Z;
//         }
//         inline affine_t(const xyzt_t &a) { *this = a; }
//     };

//     inline operator affine_t() const { return affine_t(*this); }

//     template <class affine_t>
//     inline __device__ xyzt_t &operator=(const affine_t &a)
//     {
//         // 确保是不为 0 的
//         X = a.X;
//         Y = a.Y;
//         if (a.is_inf())
//         {
//             Z.zero();
//         }
//         else
//         {
//             Z = field_t::one();
//             T = X * Y;
//         }
//         return *this;
//     }

//     template <class affine_t>
//     inline __device__ void xyzt_to_affine(affine_t &a)
//     {
//         if (Z.is_zero())
//         {
//             a.X = field_t::zero();
//             a.Y = field_t::zero();
//         }
//         else
//         {
//             a.X = X / Z;
//             a.Y = Y / Z;
//         }
//     }
//     template <class affine_inf_t>
//     inline __device__ void xyzt_to_affine_inf(affine_inf_t &a)
//     {
//         if (Z.is_zero())
//         {
//             a.X = field_t::zero();
//             a.Y = field_t::zero();
//         }
//         else
//         {
//             a.X = X / Z;
//             a.Y = Y / Z;
//         }
//     }

//     inline __device__ operator jacobian_t<field_t>() const
//     {
//         return jacobian_t<field_t>{X, Y, Z};
//     }
//     inline __device__ bool is_inf() const { return (bool)(Z.is_zero()); }
//     inline __device__ void inf()
//     {
//         Z.zero();
//     }

//     inline __device__ void neg(bool subtract = false)
//     {
//         this->Y.cneg(subtract);
//     }

//     __device__ void add(const xyzt_t &p2)
//     {
// #ifdef __CUDA_ARCH__
//         xyzt_t p31 = *this;
// #else
//         xyzt_t &p31 = *this;
// #endif
//         if (p2.is_inf())
//         {
//             return;
//         }
//         else if (p31.is_inf())
//         {
//             *this = p2;
//             return;
//         }
//         else
//         {
//             field_t A = p31.X * p2.X;
//             field_t B = p31.Y * p2.Y;
//             field_t C = p31.T * p2.T * d;
//             field_t D = p31.Z * p2.Z;
//             field_t E = (p31.X + p31.Y) * (p2.X + p2.Y) - A - B;
//             field_t F = D - C;
//             field_t G = D + C;
//             field_t H = B - a * A;
//             p31.X = E * F;
//             p31.Y = G * H;
//             p31.T = E * H;
//             p31.Z = F * G;
//         }
// #ifdef __CUDA_ARCH__
//         *this = p31;
// #endif
//     }

//     __device__ void add(const affine_t &p2, bool subtract = false)
//     {
// #ifdef __CUDA_ARCH__
//         xyzt_t p31 = *this;
// #else
//         xyzt_t &p31 = *this;
// #endif
//         if (p2.is_inf())
//         {
//             return;
//         }
//         else if (p31.is_inf())
//         {
//             *this = p2;
//             this->Z.neg(subtract);
//         }
//         else
//         {
//             xyzt_t p2t = p2;
//             field_t A = p31.X * p2t.X;
//             field_t B = p31.Y * p2t.Y;
//             field_t C = p31.Z * p2t.T;
//             field_t D = p31.T;
//             field_t E = D + C;
//             field_t F = (p31.X - p31.Y) * (p2t.X + p2t.Y) - A + B;
//             field_t G = B + a * A;
//             field_t H = D - C;
//             p31.X = E * F;
//             p31.Y = G * H;
//             p31.T = E * H;
//             p31.Z = F * G;
//         }
// #ifdef __CUDA_ARCH__
//         *this = p31;
// #endif   
//     }

//     __device__ void dbl()
//     {
//         if (is_inf())
//         {
//             return;
//         }
// #ifdef __CUDA_ARCH__
//         xyzt_t p31 = *this;
// #else
//         xyzt_t &p31 = *this;
// #endif
//         field_t A = X * X;
//         field_t B = Y * Y;
//         field_t C = Z * Z;
//         field_t tmp2 = field_t::one() + field_t::one();
//         C = tmp2 * C;
//         field_t D = a * A;
//         field_t E = (X + Y) * (X + Y) - A - B;
//         field_t G = D + B;
//         field_t F = G - C;
//         field_t H = D - B;
//         p31.X = E * F;
//         p31.Y = G * H;
//         p31.T = E * H;
//         p31.Z = F * G;
// #ifdef __CUDA_ARCH__
//         *this = p31;
// #endif
//     }
// };