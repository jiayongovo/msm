# CUDA/2**14x1            time:   [18.683 ms 18.695 ms 18.710 ms]
# CUDA/2**16x1            time:   [21.756 ms 21.771 ms 21.779 ms]
# CUDA/2**18x1            time:   [28.627 ms 28.671 ms 28.700 ms]
# CUDA/2**20x1            time:   [55.578 ms 55.879 ms 56.225 ms]
# CUDA/2**22x1            time:   [162.65 ms 162.83 ms 163.00 ms]
# CUDA/2**24x1            time:   [585.88 ms 586.61 ms 587.36 ms]
# CUDA/2**26x1            time:   [2.3214 s 2.3582 s 2.4102 s]


# CUDA/2**14x1            time:   [18.574 ms 18.597 ms 18.630 ms]
# CUDA/2**16x1            time:   [21.754 ms 21.768 ms 21.792 ms]
# CUDA/2**18x1            time:   [28.482 ms 28.509 ms 28.544 ms]
# CUDA/2**20x1            time:   [55.489 ms 55.685 ms 55.971 ms]
# CUDA/2**22x1            time:   [162.87 ms 163.01 ms 163.17 ms]
# CUDA/2**24x1            time:   [589.37 ms 590.04 ms 590.76 ms]
# CUDA/2**26x1            time:   [2.3231 s 2.3266 s 2.3298 s]


# CUDA/2**14x1            time:   [18.598 ms 18.604 ms 18.611 ms]
# CUDA/2**16x1            time:   [21.740 ms 21.803 ms 21.848 ms]
# CUDA/2**18x1            time:   [28.541 ms 28.583 ms 28.680 ms]
# CUDA/2**20x1            time:   [55.576 ms 55.784 ms 56.109 ms]
# CUDA/2**22x1            time:   [162.48 ms 164.13 ms 167.19 ms]
# CUDA/2**24x1            time:   [588.33 ms 588.96 ms 589.63 ms]
# CUDA/2**26x1            time:   [2.3038 s 2.3060 s 2.3083 s]


jy_msm_1 = [18.695, 21.771, 28.671, 55.879, 162.83, 586.61, 2358.2]
jy_msm_2 = [18.597, 21.768, 28.509, 55.685, 163.01, 590.04, 2326.6]
jy_msm_3 = [18.604, 21.803, 28.583, 55.784, 164.13, 588.96, 2306.0]

jy_msm = []
for i in range(7):
    jy_msm.append(round((jy_msm_1[i] + jy_msm_2[i] + jy_msm_3[i]) / 3,2))

print(jy_msm)

gzkp = [4,7,20,62,240,1100,4000]

for i in range(7):
    print(round(gzkp[i] / jy_msm[i],2))

