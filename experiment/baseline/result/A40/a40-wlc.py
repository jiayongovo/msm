# CUDA/2**20x1            time:   [39.283 ms 39.573 ms 39.728 ms]
# CUDA/2**21x1            time:   [62.004 ms 62.137 ms 62.256 ms]
# CUDA/2**22x1            time:   [104.99 ms 105.89 ms 107.21 ms]
# CUDA/2**23x1            time:   [188.27 ms 189.23 ms 190.41 ms]
# CUDA/2**24x1            time:   [365.68 ms 366.46 ms 367.27 ms]
# CUDA/2**25x1            time:   [705.66 ms 707.03 ms 708.27 ms]

# CUDA/2**20x1            time:   [39.466 ms 39.903 ms 40.243 ms]
# CUDA/2**21x1            time:   [61.690 ms 62.198 ms 62.662 ms]
# CUDA/2**22x1            time:   [104.75 ms 105.68 ms 106.50 ms]
# CUDA/2**23x1            time:   [190.99 ms 192.03 ms 192.98 ms]
# CUDA/2**24x1            time:   [365.16 ms 365.65 ms 366.20 ms]
# CUDA/2**25x1            time:   [715.63 ms 716.95 ms 718.29 ms]

# CUDA/2**20x1            time:   [39.833 ms 40.116 ms 40.517 ms]
# CUDA/2**21x1            time:   [61.645 ms 61.953 ms 62.394 ms]
# CUDA/2**22x1            time:   [105.44 ms 106.02 ms 107.00 ms]
# CUDA/2**23x1            time:   [191.15 ms 192.41 ms 193.67 ms]
# CUDA/2**24x1            time:   [366.05 ms 367.48 ms 368.64 ms]
# CUDA/2**25x1            time:   [717.49 ms 719.13 ms 720.61 ms]

jy_msm_1 = [39.573, 62.137, 105.89, 189.23, 366.46, 707.03]
jy_msm_2 = [39.903, 62.198, 105.68, 192.03, 365.65, 716.95]
jy_msm_3 = [40.116, 61.953, 106.02, 192.41, 367.48, 719.13]

jy_msm = []
for i in range(6):
    jy_msm.append(round((jy_msm_1[i] + jy_msm_2[i] + jy_msm_3[i]) / 3,2))



# CUDA/2**20x1            time:   [67.445 ms 67.823 ms 68.119 ms]
# CUDA/2**21x1            time:   [129.43 ms 130.20 ms 130.66 ms]
# CUDA/2**22x1            time:   [253.03 ms 254.82 ms 257.71 ms]
# CUDA/2**23x1            time:   [497.85 ms 498.95 ms 499.91 ms]
# CUDA/2**24x1            time:   [983.00 ms 984.15 ms 985.34 ms]
# CUDA/2**25x1            time:   [1.9495 s 1.9506 s 1.9516 s]

# CUDA/2**20x1            time:   [66.868 ms 67.219 ms 67.435 ms]
# CUDA/2**21x1            time:   [130.61 ms 131.49 ms 132.31 ms]
# CUDA/2**22x1            time:   [252.99 ms 254.64 ms 257.36 ms]
# CUDA/2**23x1            time:   [496.67 ms 501.91 ms 511.71 ms]
# CUDA/2**24x1            time:   [983.08 ms 984.20 ms 985.50 ms]
# CUDA/2**25x1            time:   [1.9550 s 1.9569 s 1.9587 s]

# CUDA/2**20x1            time:   [68.288 ms 68.618 ms 68.954 ms]
# CUDA/2**21x1            time:   [130.08 ms 130.86 ms 131.37 ms]
# CUDA/2**22x1            time:   [253.13 ms 255.03 ms 257.48 ms]
# CUDA/2**23x1            time:   [497.69 ms 498.87 ms 499.72 ms]
# CUDA/2**24x1            time:   [978.86 ms 996.54 ms 1.0228 s]
# CUDA/2**25x1            time:   [1.9589 s 1.9615 s 1.9643 s]

wlc_bal_1 = [67.823, 130.20, 254.82, 498.95, 984.15, 1950.6]
wlc_bal_2 = [67.219, 131.49, 254.64, 501.91, 984.20, 1956.9]
wlc_bal_3 = [68.618, 130.86, 255.03, 498.87, 996.54, 1961.5]

wlc_bal = []
for i in range(6):
    wlc_bal.append(round((wlc_bal_1[i] + wlc_bal_2[i] + wlc_bal_3[i]) / 3,2))


# CUDA/2**20x1            time:   [29.300 ms 29.395 ms 29.499 ms]
# CUDA/2**21x1            time:   [51.960 ms 52.373 ms 52.777 ms]
# CUDA/2**22x1            time:   [94.209 ms 94.916 ms 95.773 ms]
# CUDA/2**23x1            time:   [185.40 ms 192.54 ms 204.97 ms]
# CUDA/2**24x1            time:   [365.92 ms 379.92 ms 406.02 ms]

# CUDA/2**20x1            time:   [29.414 ms 29.669 ms 29.932 ms]
# CUDA/2**21x1            time:   [52.186 ms 52.448 ms 52.682 ms]
# CUDA/2**22x1            time:   [94.158 ms 94.781 ms 95.731 ms]
# CUDA/2**23x1            time:   [185.69 ms 193.01 ms 206.26 ms]
# CUDA/2**24x1            time:   [365.95 ms 380.32 ms 406.86 ms]

# CUDA/2**20x1            time:   [29.320 ms 29.553 ms 29.748 ms]
# CUDA/2**21x1            time:   [52.375 ms 52.895 ms 53.555 ms]
# CUDA/2**22x1            time:   [94.377 ms 94.943 ms 95.525 ms]
# CUDA/2**23x1            time:   [185.27 ms 191.98 ms 203.69 ms]
# CUDA/2**24x1            time:   [365.40 ms 379.30 ms 405.27 ms]


wlc_con_1 = [29.395, 52.373, 94.916, 192.54, 379.92,0]
wlc_con_2 = [29.669, 52.448, 94.781, 193.01, 380.32,0]
wlc_con_3 = [29.553, 52.895, 94.943, 191.98, 379.30,0]
wlc_con = []
for i in range(6):
    wlc_con.append(round((wlc_con_1[i] + wlc_con_2[i] + wlc_con_3[i]) / 3,2))

# Time thread 0 for MSM:  124.54093 ms
# Time thread 0 for MSM:  200.68967 ms
# Time thread 0 for MSM:  349.43179 ms
# Time thread 0 for MSM:  684.04022 ms
# Time thread 0 for MSM:  1259.78113 ms
# Time thread 0 for MSM:  2381.57007 ms

# Time thread 0 for MSM:  124.63718 ms
# Time thread 0 for MSM:  200.83405 ms
# Time thread 0 for MSM:  345.10745 ms
# Time thread 0 for MSM:  684.84711 ms
# Time thread 0 for MSM:  1253.33398 ms
# Time thread 0 for MSM:  2373.36475 ms

# Time thread 0 for MSM:  125.01913 ms
# Time thread 0 for MSM:  198.15424 ms
# Time thread 0 for MSM:  345.68396 ms
# Time thread 0 for MSM:  684.54913 ms
# Time thread 0 for MSM:  1255.41174 ms
# Time thread 0 for MSM:  2379.79248 ms


cuzk_1 = [124.54093, 200.68967, 349.43179, 684.04022, 1259.78113, 2381.57007]
cuzk_2 = [124.63718, 200.83405, 345.10745, 684.84711, 1253.33398, 2373.36475]
cuzk_3 = [125.01913, 198.15424, 345.68396, 684.54913, 1255.41174, 2379.79248]

cuzk = []
for i in range(6):
    cuzk.append(round((cuzk_1[i] + cuzk_2[i] + cuzk_3[i]) / 3,2))

print(wlc_bal)
print(wlc_con)
print(cuzk)
print(jy_msm)


wlc_bal_jy_msm = []
wlc_con_jy_msm = []
cuzk_jy_msm = []
for i in range(6):
    wlc_bal_jy_msm.append(round(wlc_bal[i] / jy_msm[i], 2))
    wlc_con_jy_msm.append(round(wlc_con[i] / jy_msm[i], 2))
    cuzk_jy_msm.append(round(cuzk[i] / jy_msm[i], 2))


print("\n")
print(wlc_bal_jy_msm)
print(wlc_con_jy_msm)
print(cuzk_jy_msm)