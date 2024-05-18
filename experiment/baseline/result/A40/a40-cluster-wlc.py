# CUDA/2**20x1            time:   [31.402 ms 31.498 ms 31.636 ms]
# CUDA/2**21x1            time:   [53.919 ms 54.182 ms 54.501 ms]
# CUDA/2**22x1            time:   [96.358 ms 96.904 ms 97.234 ms]
# CUDA/2**23x1            time:   [184.41 ms 185.77 ms 187.16 ms]
# CUDA/2**24x1            time:   [356.24 ms 357.99 ms 359.55 ms]
# CUDA/2**25x1            time:   [714.19 ms 715.31 ms 716.57 ms]

# CUDA/2**20x1            time:   [31.176 ms 31.259 ms 31.385 ms]
# CUDA/2**21x1            time:   [54.186 ms 54.583 ms 54.812 ms]
# CUDA/2**22x1            time:   [97.017 ms 97.784 ms 98.349 ms]
# CUDA/2**23x1            time:   [186.41 ms 189.81 ms 195.50 ms]
# CUDA/2**24x1            time:   [357.81 ms 359.31 ms 360.79 ms]
# CUDA/2**25x1            time:   [712.84 ms 714.45 ms 715.72 ms]

# CUDA/2**20x1            time:   [31.374 ms 31.450 ms 31.538 ms]
# CUDA/2**21x1            time:   [54.202 ms 54.371 ms 54.516 ms]
# CUDA/2**22x1            time:   [97.023 ms 97.854 ms 98.516 ms]
# CUDA/2**23x1            time:   [182.63 ms 183.24 ms 183.89 ms]
# CUDA/2**24x1            time:   [354.93 ms 356.62 ms 358.36 ms]
# CUDA/2**25x1            time:   [717.92 ms 724.16 ms 732.78 ms]

jy_msm_1 = [31.498, 54.182, 96.904, 185.77, 357.99, 715.31]
jy_msm_2 = [31.259, 54.583, 97.784, 189.81, 359.31, 714.45]
jy_msm_3 = [31.450, 54.371, 97.854, 183.24, 356.62, 724.16]

jy_msm = []
for i in range(6):
    jy_msm.append(round((jy_msm_1[i] + jy_msm_2[i] + jy_msm_3[i]) / 3,2))

# CUDA/2**20x1            time:   [62.060 ms 62.202 ms 62.327 ms]
# CUDA/2**21x1            time:   [134.02 ms 134.43 ms 134.71 ms]
# CUDA/2**22x1            time:   [262.08 ms 262.70 ms 263.44 ms]
# CUDA/2**23x1            time:   [457.94 ms 459.55 ms 461.12 ms]
# CUDA/2**24x1            time:   [1.0257 s 1.0268 s 1.0278 s]
# CUDA/2**25x1            time:   [1.1193 s 1.1207 s 1.1224 s]

# CUDA/2**20x1            time:   [55.902 ms 56.046 ms 56.181 ms]
# CUDA/2**21x1            time:   [134.33 ms 134.96 ms 135.33 ms]
# CUDA/2**22x1            time:   [142.15 ms 142.82 ms 143.45 ms]
# CUDA/2**23x1            time:   [461.79 ms 473.18 ms 488.47 ms]
# CUDA/2**24x1            time:   [810.34 ms 811.75 ms 813.12 ms]
# CUDA/2**25x1            time:   [1.6050 s 1.6327 s 1.6833 s]

# CUDA/2**20x1            time:   [48.741 ms 49.114 ms 49.555 ms]
# CUDA/2**21x1            time:   [74.643 ms 74.991 ms 75.360 ms]
# CUDA/2**22x1            time:   [236.56 ms 237.75 ms 238.97 ms]
# CUDA/2**23x1            time:   [411.26 ms 412.62 ms 413.86 ms]
# CUDA/2**24x1            time:   [697.43 ms 698.73 ms 700.12 ms]
# CUDA/2**25x1            time:   [1.1107 s 1.1175 s 1.1298 s]

wlc_bal_1 = [62.202, 134.43, 262.70, 459.55, 1026.8, 1120.7]

wlc_bal_2 = [56.046, 134.96, 142.82, 473.18, 811.75, 1632.7]

wlc_bal_3 = [49.114, 74.991, 237.75, 412.62, 698.73, 1117.5]

wlc_bal = []
for i in range(6):
    wlc_bal.append(round((wlc_bal_1[i] + wlc_bal_2[i] + wlc_bal_3[i]) / 3,2))


# CUDA/2**20x1            time:   [27.600 ms 27.700 ms 27.819 ms]
# CUDA/2**21x1            time:   [50.851 ms 51.166 ms 51.518 ms]
# CUDA/2**22x1            time:   [93.631 ms 94.359 ms 95.098 ms]
# CUDA/2**23x1            time:   [186.18 ms 187.64 ms 188.98 ms]
# CUDA/2**24x1            time:   [369.01 ms 377.18 ms 386.28 ms]

# CUDA/2**20x1            time:   [27.614 ms 27.666 ms 27.721 ms]
# CUDA/2**21x1            time:   [51.335 ms 51.556 ms 51.901 ms]
# CUDA/2**22x1            time:   [93.986 ms 94.720 ms 95.592 ms]
# CUDA/2**23x1            time:   [185.16 ms 186.60 ms 188.03 ms]
# CUDA/2**24x1            time:   [364.76 ms 366.25 ms 367.55 ms]

# CUDA/2**20x1            time:   [27.788 ms 27.888 ms 27.966 ms]
# CUDA/2**21x1            time:   [51.408 ms 51.630 ms 51.896 ms]
# CUDA/2**22x1            time:   [95.226 ms 96.408 ms 97.513 ms]
# CUDA/2**23x1            time:   [185.75 ms 187.48 ms 189.22 ms]
# CUDA/2**24x1            time:   [366.82 ms 368.41 ms 369.68 ms]

wlc_con_1 = [27.700, 51.166, 94.359, 187.64, 377.18,0]
wlc_con_2 = [27.666, 51.556, 94.720, 186.60, 366.25,0]
wlc_con_3 = [27.888, 51.630, 96.408, 187.48, 368.41,0]

wlc_con = []
for i in range(6):
    wlc_con.append(round((wlc_con_1[i] + wlc_con_2[i] + wlc_con_3[i]) / 3,2))

print(jy_msm)
print(wlc_bal)
print(wlc_con)

wlc_bal_jy = []
wlc_con_jy = []
for i in range(6):
    wlc_bal_jy.append(round(wlc_bal[i] / jy_msm[i],2))
    wlc_con_jy.append(round(wlc_con[i] / jy_msm[i],2))

print("\n")
print(wlc_bal_jy)
print(wlc_con_jy)