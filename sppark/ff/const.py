from sympy import mod_inverse

# 定义 q
q = 4002409555221667393417789825735904156556882819939007885332058136124031650490837864442687629129015664037894272559787

# 选择 R = 2^384
R = 2**384

# 计算 RR = R^2 mod q
RR = pow(R, 2, q)

# 计算 ONE = R mod q
ONE = pow(R, 1, q)

# 计算 M0 = -q^{-1} mod 2^32
M0 = -mod_inverse(q, 2**32) % 2**32

print(f"RR = {RR}")
print(f"ONE = {ONE}")
print(f"M0 = {M0:#010x}")

# 拆分为32位部分
def split_into_uint32(n, parts):
    mask = 0xFFFFFFFF
    return [(n >> (32 * i)) & mask for i in range(parts)]

RR_parts = split_into_uint32(RR, 12)
ONE_parts = split_into_uint32(ONE, 12)

print("RR_parts = ", [hex(part) for part in RR_parts])
print("ONE_parts = ", [hex(part) for part in ONE_parts])
print(f"M0 = {M0:#010x}")