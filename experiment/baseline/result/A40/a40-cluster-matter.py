# CUDA/2**21x1            time:   [53.903 ms 54.527 ms 54.893 ms]
# CUDA/2**22x1            time:   [99.460 ms 100.15 ms 100.48 ms]
# CUDA/2**23x1            time:   [185.88 ms 187.57 ms 189.24 ms]
# CUDA/2**24x1            time:   [355.31 ms 356.76 ms 358.41 ms]
# CUDA/2**25x1            time:   [716.27 ms 717.85 ms 719.31 ms]
# CUDA/2**26x1            time:   [1.4211 s 1.4697 s 1.5652 s]

# CUDA/2**21x1            time:   [54.442 ms 54.753 ms 54.960 ms]
# CUDA/2**22x1            time:   [96.751 ms 97.563 ms 98.063 ms]
# CUDA/2**23x1            time:   [184.37 ms 185.04 ms 185.72 ms]
# CUDA/2**24x1            time:   [355.42 ms 356.64 ms 357.49 ms]
# CUDA/2**25x1            time:   [722.16 ms 723.16 ms 724.07 ms]
# CUDA/2**26x1            time:   [1.4232 s 1.4250 s 1.4267 s]

# CUDA/2**21x1            time:   [54.458 ms 54.729 ms 55.078 ms]
# CUDA/2**22x1            time:   [95.805 ms 96.711 ms 97.558 ms]
# CUDA/2**23x1            time:   [183.22 ms 184.00 ms 184.85 ms]
# CUDA/2**24x1            time:   [356.51 ms 358.77 ms 361.39 ms]
# CUDA/2**25x1            time:   [720.60 ms 722.03 ms 723.44 ms]
# CUDA/2**26x1            time:   [1.4116 s 1.4139 s 1.4160 s]


jy_msm_1 = [54.527, 100.15, 187.57, 356.76, 717.85, 1469.7]
jy_msm_2 = [54.753, 97.563, 185.04, 356.64, 723.16, 1425.0]
jy_msm_3 = [54.729, 96.711, 184.00, 358.77, 722.03, 1413.9]


jy_msm = []
for i in range(6):
    jy_msm.append(round((jy_msm_1[i] + jy_msm_2[i] + jy_msm_3[i]) / 3,2))

print(jy_msm)
# CUDA/2**23x1            time:   [2.7580 s 2.7594 s 2.7623 s]
# CUDA/2**24x1            time:   [5.4724 s 5.4725 s 5.4726 s]
# CUDA/2**25x1            time:   [10.906 s 10.906 s 10.906 s]


matter_lab = [0,0,2759.4, 5472.5, 10906, 21818]

matter_jy_msm = []
for i in range(6):
    matter_jy_msm.append(round(matter_lab[i] / jy_msm[i],2))

print(matter_jy_msm)

