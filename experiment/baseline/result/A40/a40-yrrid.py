# CUDA/2**21x1            time:   [61.128 ms 61.676 ms 62.198 ms]
# CUDA/2**22x1            time:   [106.48 ms 107.43 ms 108.28 ms]
# CUDA/2**23x1            time:   [197.45 ms 199.89 ms 202.57 ms]
# CUDA/2**24x1            time:   [365.21 ms 370.57 ms 376.56 ms]
# CUDA/2**25x1            time:   [704.28 ms 708.88 ms 715.90 ms]
# CUDA/2**26x1            time:   [1.4653 s 1.5993 s 1.7704 s]

# CUDA/2**21x1            time:   [62.773 ms 62.877 ms 63.024 ms]
# CUDA/2**22x1            time:   [106.99 ms 107.76 ms 108.17 ms]
# CUDA/2**23x1            time:   [192.77 ms 194.67 ms 196.45 ms]
# CUDA/2**24x1            time:   [364.33 ms 364.88 ms 365.43 ms]
# CUDA/2**25x1            time:   [704.95 ms 706.47 ms 707.90 ms]
# CUDA/2**26x1            time:   [1.4217 s 1.4362 s 1.4518 s]

# CUDA/2**21x1            time:   [62.500 ms 62.719 ms 62.959 ms]
# CUDA/2**22x1            time:   [106.44 ms 107.35 ms 109.28 ms]
# CUDA/2**23x1            time:   [207.43 ms 209.24 ms 210.79 ms]
# CUDA/2**24x1            time:   [365.74 ms 369.17 ms 374.95 ms]
# CUDA/2**25x1            time:   [708.21 ms 709.59 ms 711.08 ms]
# CUDA/2**26x1            time:   [1.4158 s 1.4191 s 1.4215 s]

jy_msm_1 = [61.676, 107.43, 199.89, 370.57, 708.88, 1599.3]
jy_msm_2 = [62.877, 107.76, 194.67, 364.88, 706.47, 1436.2]
jy_msm_3 = [62.719, 107.35, 209.24, 369.17, 709.59, 1419.1]
jy_msm = []
for i in range(6):
    jy_msm.append(round((jy_msm_1[i] + jy_msm_2[i] + jy_msm_3[i]) / 3,2))


# CUDA/2**21x1            time:   [49.991 ms 50.292 ms 50.740 ms]
# CUDA/2**22x1            time:   [71.233 ms 71.821 ms 72.571 ms]
# CUDA/2**23x1            time:   [118.74 ms 119.94 ms 122.19 ms]
# CUDA/2**24x1            time:   [219.49 ms 223.03 ms 228.14 ms]
# CUDA/2**25x1            time:   [411.14 ms 411.99 ms 412.81 ms]
# CUDA/2**26x1            time:   [801.81 ms 803.08 ms 804.48 ms]

# CUDA/2**21x1            time:   [50.410 ms 50.701 ms 51.049 ms]
# CUDA/2**22x1            time:   [71.252 ms 71.840 ms 72.608 ms]
# CUDA/2**23x1            time:   [118.59 ms 120.54 ms 123.70 ms]
# CUDA/2**24x1            time:   [217.24 ms 220.19 ms 224.22 ms]
# CUDA/2**25x1            time:   [409.67 ms 410.16 ms 410.69 ms]
# CUDA/2**26x1            time:   [796.66 ms 797.81 ms 799.09 ms]

# CUDA/2**21x1            time:   [50.075 ms 50.341 ms 50.692 ms]
# CUDA/2**22x1            time:   [70.739 ms 71.396 ms 72.257 ms]
# CUDA/2**23x1            time:   [118.38 ms 119.66 ms 122.12 ms]
# CUDA/2**24x1            time:   [215.05 ms 216.97 ms 220.37 ms]
# CUDA/2**25x1            time:   [410.91 ms 411.92 ms 413.06 ms]
# CUDA/2**26x1            time:   [798.43 ms 799.54 ms 800.90 ms]

yrrid_1 = [50.292, 71.821, 119.94, 223.03, 411.99, 803.08]
yrrid_2 = [50.701, 71.840, 120.54, 220.19, 410.16, 797.81]
yrrid_3 = [50.341, 71.396, 119.66, 216.97, 411.92, 799.54]

yrrid = []
for i in range(6):
    yrrid.append(round((yrrid_1[i] + yrrid_2[i] + yrrid_3[i]) / 3,2))



# CUDA/2**23x1            time:   [127.05 ms 127.22 ms 127.32 ms]
# CUDA/2**24x1            time:   [207.76 ms 207.99 ms 208.21 ms]
# CUDA/2**25x1            time:   [360.15 ms 360.33 ms 360.51 ms]
# CUDA/2**26x1            time:   [656.61 ms 657.02 ms 657.42 ms]

# CUDA/2**23x1            time:   [127.52 ms 127.57 ms 127.61 ms]
# CUDA/2**24x1            time:   [207.95 ms 208.05 ms 208.15 ms]
# CUDA/2**25x1            time:   [359.84 ms 360.07 ms 360.32 ms]
# CUDA/2**26x1            time:   [656.24 ms 656.91 ms 657.62 ms]

# CUDA/2**23x1            time:   [127.59 ms 127.73 ms 127.81 ms]
# CUDA/2**24x1            time:   [207.89 ms 208.02 ms 208.15 ms]
# CUDA/2**25x1            time:   [360.19 ms 360.33 ms 360.49 ms]
# CUDA/2**26x1            time:   [656.36 ms 656.87 ms 657.42 ms]

matter_lab_1 = [0,0,127.22, 207.99, 360.33, 657.02]
matter_lab_2 = [0,0,127.57, 208.05, 360.07, 656.91]
matter_lab_3 = [0,0,127.73, 208.02, 360.33, 656.87]

matter_lab = []
for i in range(6):
    matter_lab.append(round((matter_lab_1[i] + matter_lab_2[i] + matter_lab_3[i]) / 3,2))

matter_lab_jy = []
yrrid_jy = []
for i in range(6):
    matter_lab_jy.append(round(matter_lab[i] / jy_msm[i],2))
    yrrid_jy.append(round(yrrid[i] / jy_msm[i],2))

print(matter_lab)
print(yrrid)
print(jy_msm)

print("\n")
print(matter_lab_jy)
print(yrrid_jy)