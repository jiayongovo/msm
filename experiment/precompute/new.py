# CUDA/2**17x1            time:   [18.327 ms 18.375 ms 18.497 ms]
# CUDA/2**18x1            time:   [20.654 ms 20.732 ms 20.817 ms]
# CUDA/2**19x1            time:   [23.236 ms 23.513 ms 23.954 ms]
# CUDA/2**20x1            time:   [29.843 ms 30.084 ms 30.212 ms]
# CUDA/2**21x1            time:   [41.832 ms 42.657 ms 43.198 ms]
# CUDA/2**22x1            time:   [70.109 ms 71.295 ms 72.670 ms]
# CUDA/2**23x1            time:   [123.29 ms 129.81 ms 140.76 ms]

# CUDA/2**17x1            time:   [18.665 ms 18.740 ms 18.838 ms]
# CUDA/2**18x1            time:   [19.965 ms 20.133 ms 20.359 ms]
# CUDA/2**19x1            time:   [23.141 ms 23.435 ms 23.716 ms]
# CUDA/2**20x1            time:   [29.408 ms 29.723 ms 29.923 ms]
# CUDA/2**21x1            time:   [43.921 ms 44.199 ms 44.546 ms]
# CUDA/2**22x1            time:   [70.046 ms 70.442 ms 70.833 ms]
# CUDA/2**23x1            time:   [118.08 ms 128.16 ms 140.70 ms]

# CUDA/2**17x1            time:   [18.295 ms 18.348 ms 18.404 ms]
# CUDA/2**18x1            time:   [20.350 ms 20.511 ms 20.813 ms]
# CUDA/2**19x1            time:   [23.813 ms 24.010 ms 24.246 ms]
# CUDA/2**20x1            time:   [29.596 ms 30.108 ms 30.523 ms]
# CUDA/2**21x1            time:   [42.654 ms 43.292 ms 43.942 ms]
# CUDA/2**22x1            time:   [69.543 ms 69.974 ms 70.298 ms]
# CUDA/2**23x1            time:   [122.55 ms 128.20 ms 136.20 ms]


jy_msm_m_1_1 = [18.375,20.732,23.513,30.084,42.657,71.295,129.81,0]
jy_msm_m_1_2 = [18.740,20.133,23.435,29.723,44.199,70.442,128.16,0]
jy_msm_m_1_3 = [18.348,20.511,24.010,30.108,43.292,69.974,128.20,0]

jy_msm_m_1 = []

for i in range(0, len(8)):
    jy_msm_m_1.append((jy_msm_m_1_1[i] + jy_msm_m_1_2[i] + jy_msm_m_1_3[i])/3)

# CUDA/2**17x1            time:   [14.054 ms 14.117 ms 14.176 ms]
# CUDA/2**18x1            time:   [15.434 ms 15.603 ms 15.754 ms]
# CUDA/2**19x1            time:   [19.406 ms 19.690 ms 20.081 ms]
# CUDA/2**20x1            time:   [25.420 ms 25.515 ms 25.593 ms]
# CUDA/2**21x1            time:   [38.937 ms 39.296 ms 39.536 ms]
# CUDA/2**22x1            time:   [63.520 ms 64.121 ms 64.703 ms]
# CUDA/2**23x1            time:   [112.74 ms 118.19 ms 125.91 ms]
# CUDA/2**24x1            time:   [220.31 ms 228.14 ms 241.22 ms]

# CUDA/2**17x1            time:   [14.336 ms 14.441 ms 14.553 ms]
# CUDA/2**18x1            time:   [15.537 ms 15.602 ms 15.712 ms]
# CUDA/2**19x1            time:   [18.763 ms 19.209 ms 20.036 ms]
# CUDA/2**20x1            time:   [25.858 ms 26.285 ms 26.649 ms]
# CUDA/2**21x1            time:   [38.197 ms 38.877 ms 39.510 ms]
# CUDA/2**22x1            time:   [65.280 ms 66.310 ms 67.080 ms]
# CUDA/2**23x1            time:   [116.33 ms 128.24 ms 150.89 ms]
# CUDA/2**24x1            time:   [218.66 ms 221.03 ms 223.44 ms]

# CUDA/2**17x1            time:   [14.498 ms 14.572 ms 14.674 ms]
# CUDA/2**18x1            time:   [16.384 ms 16.541 ms 16.659 ms]
# CUDA/2**19x1            time:   [18.972 ms 19.349 ms 20.071 ms]
# CUDA/2**20x1            time:   [25.334 ms 25.469 ms 25.603 ms]
# CUDA/2**21x1            time:   [38.680 ms 38.990 ms 39.236 ms]
# CUDA/2**22x1            time:   [65.742 ms 68.075 ms 70.464 ms]
# CUDA/2**23x1            time:   [117.51 ms 122.24 ms 129.61 ms]
# CUDA/2**24x1            time:   [219.94 ms 242.88 ms 272.80 ms]


jy_msm_m_2_1 = [14.117,15.603,19.690,25.515,39.296,64.121,118.19,228.14]
jy_msm_m_2_2 = [14.441,15.602,19.209,26.285,38.877,66.310,128.24,221.03]
jy_msm_m_2_3 = [14.572,16.541,19.349,25.469,38.990,68.075,122.24,242.88]

jy_msm_m_2 = []

for i in range(0, len(8)):
    jy_msm_m_2.append((jy_msm_m_2_1[i] + jy_msm_m_2_2[i] + jy_msm_m_2_3[i])/3)


# CUDA/2**17x1            time:   [12.882 ms 12.966 ms 13.048 ms]
# CUDA/2**18x1            time:   [14.194 ms 14.328 ms 14.576 ms]
# CUDA/2**19x1            time:   [16.760 ms 16.911 ms 17.072 ms]
# CUDA/2**20x1            time:   [23.107 ms 23.697 ms 24.123 ms]
# CUDA/2**21x1            time:   [36.643 ms 37.000 ms 37.271 ms]
# CUDA/2**22x1            time:   [59.782 ms 62.163 ms 64.072 ms]
# CUDA/2**23x1            time:   [113.05 ms 116.27 ms 120.48 ms]
# CUDA/2**24x1            time:   [216.45 ms 239.73 ms 274.68 ms]

# CUDA/2**17x1            time:   [12.571 ms 12.694 ms 12.751 ms]
# CUDA/2**18x1            time:   [14.607 ms 14.682 ms 14.723 ms]
# CUDA/2**19x1            time:   [17.061 ms 17.395 ms 17.884 ms]
# CUDA/2**20x1            time:   [23.713 ms 23.867 ms 23.970 ms]
# CUDA/2**21x1            time:   [36.652 ms 37.115 ms 37.421 ms]
# CUDA/2**22x1            time:   [62.859 ms 63.078 ms 63.362 ms]
# CUDA/2**23x1            time:   [115.19 ms 116.83 ms 119.73 ms]
# CUDA/2**24x1            time:   [214.72 ms 224.16 ms 237.64 ms]

# CUDA/2**17x1            time:   [12.339 ms 12.400 ms 12.466 ms]
# CUDA/2**18x1            time:   [13.709 ms 13.855 ms 13.936 ms]
# CUDA/2**19x1            time:   [16.605 ms 16.771 ms 16.917 ms]
# CUDA/2**20x1            time:   [23.769 ms 24.140 ms 24.583 ms]
# CUDA/2**21x1            time:   [36.488 ms 37.005 ms 37.558 ms]
# CUDA/2**22x1            time:   [62.531 ms 64.331 ms 65.180 ms]
# CUDA/2**23x1            time:   [113.17 ms 114.31 ms 115.47 ms]
# CUDA/2**24x1            time:   [219.61 ms 221.99 ms 224.20 ms]


jy_msm_m_4_1 = [12.966,14.328,16.911,23.697,37.000,62.163,116.27,239.73]
jy_msm_m_4_2 = [12.694,14.682,17.395,23.867,37.115,63.078,116.83,224.16]
jy_msm_m_4_3 = [12.400,13.855,16.771,24.140,37.005,64.331,114.31,221.99]


jy_msm_m_4 = []
for i in range(0, len(8)):
    jy_msm_m_4.append((jy_msm_m_4_1[i] + jy_msm_m_4_2[i] + jy_msm_m_4_3[i])/3)



# CUDA/2**17x1            time:   [12.895 ms 12.974 ms 13.099 ms]
# CUDA/2**18x1            time:   [13.685 ms 13.975 ms 14.571 ms]
# CUDA/2**19x1            time:   [16.587 ms 16.837 ms 16.960 ms]
# CUDA/2**20x1            time:   [24.078 ms 24.336 ms 24.706 ms]
# CUDA/2**21x1            time:   [36.738 ms 37.652 ms 38.380 ms]
# CUDA/2**22x1            time:   [63.277 ms 63.832 ms 64.260 ms]
# CUDA/2**23x1            time:   [113.77 ms 117.15 ms 123.66 ms]
# CUDA/2**24x1            time:   [223.16 ms 231.32 ms 241.16 ms]

# CUDA/2**17x1            time:   [12.329 ms 12.361 ms 12.422 ms]
# CUDA/2**18x1            time:   [14.094 ms 14.259 ms 14.430 ms]
# CUDA/2**19x1            time:   [17.012 ms 17.167 ms 17.271 ms]
# CUDA/2**20x1            time:   [23.477 ms 23.725 ms 23.944 ms]
# CUDA/2**21x1            time:   [38.244 ms 38.399 ms 38.680 ms]
# CUDA/2**22x1            time:   [65.642 ms 66.129 ms 66.626 ms]
# CUDA/2**23x1            time:   [113.85 ms 117.03 ms 119.69 ms]
# CUDA/2**24x1            time:   [219.23 ms 224.54 ms 232.08 ms]

# CUDA/2**17x1            time:   [12.700 ms 12.745 ms 12.823 ms]
# CUDA/2**18x1            time:   [14.726 ms 14.857 ms 14.956 ms]
# CUDA/2**19x1            time:   [17.263 ms 17.627 ms 17.978 ms]
# CUDA/2**20x1            time:   [23.635 ms 23.825 ms 23.986 ms]
# CUDA/2**21x1            time:   [36.489 ms 36.906 ms 37.366 ms]
# CUDA/2**22x1            time:   [63.547 ms 64.230 ms 65.051 ms]
# CUDA/2**23x1            time:   [117.19 ms 119.28 ms 123.00 ms]
# CUDA/2**24x1            time:   [225.43 ms 242.09 ms 267.09 ms]


jy_msm_m_8_1 = [12.974,13.975,16.837,24.336,37.652,63.832,117.15,231.32]
jy_msm_m_8_2 = [12.361,14.259,17.167,23.725,38.399,66.129,117.03,224.54]
jy_msm_m_8_3 = [12.745,14.857,17.627,23.825,36.906,64.230,119.28,242.09]


jy_msm_m_8 = []
for i in range(0, len(8)):
    jy_msm_m_8.append((jy_msm_m_8_1[i] + jy_msm_m_8_2[i] + jy_msm_m_8_3[i])/3)


# CUDA/2**17x1            time:   [12.558 ms 12.768 ms 12.954 ms]
# CUDA/2**18x1            time:   [14.193 ms 14.313 ms 14.556 ms]
# CUDA/2**19x1            time:   [17.646 ms 18.008 ms 18.640 ms]
# CUDA/2**20x1            time:   [23.592 ms 23.850 ms 23.986 ms]
# CUDA/2**21x1            time:   [37.357 ms 37.883 ms 38.208 ms]
# CUDA/2**22x1            time:   [63.953 ms 64.399 ms 65.179 ms]
# CUDA/2**23x1            time:   [113.47 ms 118.32 ms 121.30 ms]
# CUDA/2**24x1            time:   [219.60 ms 233.62 ms 258.98 ms]


# CUDA/2**17x1            time:   [12.950 ms 13.066 ms 13.247 ms]
# CUDA/2**18x1            time:   [14.642 ms 14.771 ms 14.895 ms]
# CUDA/2**19x1            time:   [17.329 ms 17.539 ms 17.739 ms]
# CUDA/2**20x1            time:   [23.784 ms 24.004 ms 24.171 ms]
# CUDA/2**21x1            time:   [37.109 ms 37.542 ms 37.907 ms]
# CUDA/2**22x1            time:   [63.753 ms 64.774 ms 65.853 ms]
# CUDA/2**23x1            time:   [115.10 ms 118.23 ms 121.95 ms]
# CUDA/2**24x1            time:   [231.62 ms 236.82 ms 241.62 ms]

# CUDA/2**17x1            time:   [13.075 ms 13.122 ms 13.170 ms]
# CUDA/2**18x1            time:   [14.716 ms 14.801 ms 14.894 ms]
# CUDA/2**19x1            time:   [17.231 ms 17.463 ms 17.798 ms]
# CUDA/2**20x1            time:   [23.331 ms 23.539 ms 23.855 ms]
# CUDA/2**21x1            time:   [37.220 ms 37.405 ms 37.570 ms]
# CUDA/2**22x1            time:   [59.997 ms 62.205 ms 63.885 ms]
# CUDA/2**23x1            time:   [113.71 ms 114.50 ms 114.97 ms]
# CUDA/2**24x1            time:   [219.50 ms 220.59 ms 221.68 ms]

jy_msm_12_1 = [12.768,14.313,18.008,23.850,37.883,64.399,118.32,233.62]
jy_msm_12_2 = [13.066,14.771,17.539,24.004,37.542,64.774,118.23,236.82]
jy_msm_12_3 = [13.122,14.801,17.463,23.539,37.405,62.205,114.50,220.59]


jy_msm_12 = []
for i in range(0, len(8)):
    jy_msm_12.append((jy_msm_12_1[i] + jy_msm_12_2[i] + jy_msm_12_3[i])/3)


# CUDA/2**17x1            time:   [14.806 ms 14.860 ms 14.902 ms]
# CUDA/2**18x1            time:   [16.280 ms 16.482 ms 16.622 ms]
# CUDA/2**19x1            time:   [19.589 ms 19.758 ms 19.943 ms]
# CUDA/2**20x1            time:   [25.527 ms 25.597 ms 25.671 ms]
# CUDA/2**21x1            time:   [38.657 ms 39.354 ms 39.760 ms]
# CUDA/2**22x1            time:   [66.280 ms 67.732 ms 69.277 ms]
# CUDA/2**23x1            time:   [119.27 ms 122.89 ms 125.52 ms]
# CUDA/2**24x1            time:   [217.09 ms 221.57 ms 226.47 ms]

# CUDA/2**17x1            time:   [14.765 ms 14.803 ms 14.836 ms]
# CUDA/2**18x1            time:   [16.365 ms 16.424 ms 16.485 ms]
# CUDA/2**19x1            time:   [19.309 ms 19.571 ms 19.784 ms]
# CUDA/2**20x1            time:   [25.139 ms 25.476 ms 25.709 ms]
# CUDA/2**21x1            time:   [38.358 ms 38.877 ms 39.701 ms]
# CUDA/2**22x1            time:   [65.938 ms 67.197 ms 68.325 ms]
# CUDA/2**23x1            time:   [117.30 ms 124.68 ms 130.11 ms]
# CUDA/2**24x1            time:   [215.97 ms 217.60 ms 219.10 ms]

# CUDA/2**17x1            time:   [14.353 ms 14.386 ms 14.431 ms]
# CUDA/2**18x1            time:   [15.845 ms 16.299 ms 16.579 ms]
# CUDA/2**19x1            time:   [18.814 ms 18.882 ms 18.967 ms]
# CUDA/2**20x1            time:   [25.284 ms 25.417 ms 25.570 ms]
# CUDA/2**21x1            time:   [38.293 ms 38.582 ms 38.732 ms]
# CUDA/2**22x1            time:   [62.320 ms 63.809 ms 64.544 ms]
# CUDA/2**23x1            time:   [115.22 ms 115.66 ms 116.09 ms]
# CUDA/2**24x1            time:   [211.41 ms 212.58 ms 213.74 ms]


jy_msm_16_1 = [14.860,16.482,19.758,25.597,39.354,67.732,122.89,221.57]
jy_msm_16_2 = [14.803,16.424,19.571,25.476,38.877,67.197,124.68,217.60]
jy_msm_16_3 = [14.386,16.299,18.882,25.417,38.582,63.809,115.66,212.58]


jy_msm_16 = []
for i in range(0, len(8)):
    jy_msm_16.append((jy_msm_16_1[i] + jy_msm_16_2[i] + jy_msm_16_3[i])/3)