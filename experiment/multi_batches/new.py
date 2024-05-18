# CUDA/2**17x1            time:   [12.982 ms 13.041 ms 13.090 ms]
# CUDA/2**18x1            time:   [13.981 ms 14.198 ms 14.476 ms]
# CUDA/2**19x1            time:   [17.042 ms 17.184 ms 17.286 ms]
# CUDA/2**20x1            time:   [23.320 ms 23.465 ms 23.557 ms]
# CUDA/2**21x1            time:   [37.919 ms 38.072 ms 38.232 ms]
# CUDA/2**22x1            time:   [63.264 ms 63.431 ms 63.674 ms]
# CUDA/2**23x1            time:   [114.44 ms 115.16 ms 116.80 ms]

# CUDA/2**17x1            time:   [13.133 ms 13.151 ms 13.175 ms]
# CUDA/2**18x1            time:   [14.001 ms 14.144 ms 14.355 ms]
# CUDA/2**19x1            time:   [17.297 ms 17.303 ms 17.308 ms]
# CUDA/2**20x1            time:   [23.376 ms 23.518 ms 23.612 ms]
# CUDA/2**21x1            time:   [37.121 ms 37.976 ms 39.462 ms]
# CUDA/2**22x1            time:   [63.412 ms 64.448 ms 65.089 ms]
# CUDA/2**23x1            time:   [114.66 ms 114.83 ms 115.12 ms]


# CUDA/2**17x1            time:   [12.566 ms 12.628 ms 12.673 ms]
# CUDA/2**18x1            time:   [14.080 ms 14.140 ms 14.178 ms]
# CUDA/2**19x1            time:   [17.296 ms 17.370 ms 17.471 ms]
# CUDA/2**20x1            time:   [23.591 ms 23.625 ms 23.657 ms]
# CUDA/2**21x1            time:   [36.797 ms 36.895 ms 37.052 ms]
# CUDA/2**22x1            time:   [63.195 ms 64.291 ms 65.673 ms]
# CUDA/2**23x1            time:   [114.07 ms 114.50 ms 115.01 ms]


batch_1_1 = [13.041, 14.198, 17.184, 23.465, 38.072, 63.431, 115.16]
batch_1_2 = [13.151, 14.144, 17.303, 23.518, 37.976, 64.448, 114.83]
batch_1_3 = [12.628, 14.140, 17.296, 23.625, 36.895, 64.291, 114.50]

batch_1 = []
for i in range(0, 7):
    batch_1.append(round((batch_1_1[i] + batch_1_2[i] + batch_1_3[i])/3,2))


# CUDA/2**17x2            time:   [24.780 ms 24.861 ms 25.057 ms]
# CUDA/2**18x2            time:   [26.549 ms 26.702 ms 26.884 ms]
# CUDA/2**19x2            time:   [30.986 ms 31.104 ms 31.272 ms]
# CUDA/2**20x2            time:   [41.066 ms 41.083 ms 41.121 ms]
# CUDA/2**21x2            time:   [62.488 ms 63.909 ms 65.803 ms]
# CUDA/2**22x2            time:   [100.76 ms 101.02 ms 101.23 ms]
# CUDA/2**23x2            time:   [183.08 ms 183.62 ms 184.21 ms]

# CUDA/2**17x2            time:   [23.889 ms 23.993 ms 24.249 ms]
# CUDA/2**18x2            time:   [26.324 ms 26.767 ms 26.956 ms]
# CUDA/2**19x2            time:   [30.871 ms 31.010 ms 31.284 ms]
# CUDA/2**20x2            time:   [40.521 ms 40.723 ms 40.866 ms]
# CUDA/2**21x2            time:   [61.414 ms 62.439 ms 64.136 ms]
# CUDA/2**22x2            time:   [100.28 ms 100.71 ms 101.07 ms]
# CUDA/2**23x2            time:   [184.44 ms 184.73 ms 185.01 ms]


# CUDA/2**17x2            time:   [24.342 ms 24.359 ms 24.382 ms]
# CUDA/2**18x2            time:   [26.516 ms 26.580 ms 26.638 ms]
# CUDA/2**19x2            time:   [31.222 ms 31.355 ms 31.531 ms]
# CUDA/2**20x2            time:   [40.734 ms 40.785 ms 40.846 ms]
# CUDA/2**21x2            time:   [61.854 ms 62.651 ms 63.059 ms]
# CUDA/2**22x2            time:   [100.39 ms 100.59 ms 100.81 ms]
# CUDA/2**23x2            time:   [171.50 ms 172.45 ms 173.60 ms]

batch_2_1 = [24.861, 26.702, 31.104, 41.083, 63.909, 101.02, 183.62]
batch_2_2 = [23.993, 26.767, 31.010, 40.723, 62.439, 100.71, 184.73]
batch_2_3 = [24.359, 26.580, 31.355, 40.785, 62.651, 100.59, 172.45]


batch_2 = []
for i in range(0, 7):
    batch_2.append(round((batch_2_1[i] + batch_2_2[i] + batch_2_3[i])/3,2))



# CUDA/2**17x4            time:   [48.127 ms 48.204 ms 48.254 ms]
# CUDA/2**18x4            time:   [51.142 ms 51.518 ms 51.891 ms]
# CUDA/2**19x4            time:   [59.223 ms 59.231 ms 59.245 ms]
# CUDA/2**20x4            time:   [75.563 ms 77.355 ms 78.545 ms]
# CUDA/2**21x4            time:   [109.28 ms 109.43 ms 109.66 ms]
# CUDA/2**22x4            time:   [175.85 ms 181.90 ms 193.39 ms]
# CUDA/2**23x4            time:   [322.00 ms 328.25 ms 336.49 ms]

# CUDA/2**17x4            time:   [46.922 ms 46.971 ms 47.016 ms]
# CUDA/2**18x4            time:   [51.633 ms 51.885 ms 52.083 ms]
# CUDA/2**19x4            time:   [58.442 ms 58.742 ms 59.042 ms]
# CUDA/2**20x4            time:   [74.167 ms 75.620 ms 77.443 ms]
# CUDA/2**21x4            time:   [109.58 ms 109.65 ms 109.71 ms]
# CUDA/2**22x4            time:   [180.97 ms 194.99 ms 211.77 ms]
# CUDA/2**23x4            time:   [323.54 ms 324.09 ms 324.57 ms]


# CUDA/2**17x4            time:   [47.164 ms 47.186 ms 47.207 ms]
# CUDA/2**18x4            time:   [51.046 ms 51.327 ms 51.607 ms]
# CUDA/2**19x4            time:   [59.177 ms 59.433 ms 59.770 ms]
# CUDA/2**20x4            time:   [75.811 ms 76.890 ms 77.585 ms]
# CUDA/2**21x4            time:   [109.73 ms 113.79 ms 119.07 ms]
# CUDA/2**22x4            time:   [178.56 ms 183.59 ms 189.39 ms]
# CUDA/2**23x4            time:   [323.00 ms 325.77 ms 329.54 ms]


batch_4_1 = [48.204, 51.518, 59.231, 77.355, 109.43, 181.90, 328.25]
batch_4_2 = [46.971, 51.885, 58.742, 75.620, 109.65, 194.99, 324.09]
batch_4_3 = [47.186, 51.327, 59.433, 76.890, 113.79, 183.59, 325.77]

batch_4 = []
for i in range(0, 7):
    batch_4.append(round((batch_4_1[i] + batch_4_2[i] + batch_4_3[i])/3,2))


# CUDA/2**17x8            time:   [94.137 ms 94.804 ms 95.343 ms]
# CUDA/2**18x8            time:   [100.26 ms 100.66 ms 101.34 ms]
# CUDA/2**19x8            time:   [114.88 ms 115.25 ms 115.70 ms]
# CUDA/2**20x8            time:   [143.82 ms 143.87 ms 143.93 ms]
# CUDA/2**21x8            time:   [204.83 ms 205.03 ms 205.27 ms]
# CUDA/2**22x8            time:   [336.70 ms 364.01 ms 401.04 ms]
# CUDA/2**23x8            time:   [599.19 ms 644.72 ms 712.67 ms]

# CUDA/2**17x8            time:   [93.087 ms 93.490 ms 93.919 ms]
# CUDA/2**18x8            time:   [101.14 ms 102.08 ms 102.78 ms]
# CUDA/2**19x8            time:   [114.49 ms 114.64 ms 114.76 ms]
# CUDA/2**20x8            time:   [143.74 ms 147.75 ms 152.37 ms]
# CUDA/2**21x8            time:   [205.72 ms 205.80 ms 205.88 ms]
# CUDA/2**22x8            time:   [337.59 ms 365.43 ms 403.00 ms]
# CUDA/2**23x8            time:   [608.55 ms 667.65 ms 751.02 ms]


# CUDA/2**17x8            time:   [94.696 ms 95.448 ms 96.039 ms]
# CUDA/2**18x8            time:   [100.19 ms 100.72 ms 101.25 ms]
# CUDA/2**19x8            time:   [114.53 ms 114.91 ms 115.31 ms]
# CUDA/2**20x8            time:   [141.56 ms 144.77 ms 148.48 ms]
# CUDA/2**21x8            time:   [205.29 ms 206.23 ms 208.00 ms]
# CUDA/2**22x8            time:   [327.18 ms 327.89 ms 328.82 ms]
# CUDA/2**23x8            time:   [604.38 ms 657.60 ms 728.69 ms]

batch_8_1 = [94.804, 100.66, 115.25, 143.87, 205.03, 364.01, 644.72]
batch_8_2 = [93.490, 102.08, 114.64, 147.75, 205.80, 365.43, 667.65]
batch_8_3 = [95.448, 100.72, 114.91, 144.77, 206.23, 327.89, 657.60]

batch_8 = []
for i in range(0, 7):
    batch_8.append(round((batch_8_1[i] + batch_8_2[i] + batch_8_3[i])/3,2))

# CUDA/2**17x16           time:   [187.82 ms 188.74 ms 189.49 ms]
# CUDA/2**18x16           time:   [200.16 ms 201.02 ms 201.83 ms]
# CUDA/2**19x16           time:   [225.13 ms 225.40 ms 225.62 ms]
# CUDA/2**20x16           time:   [280.45 ms 280.63 ms 280.83 ms]
# CUDA/2**21x16           time:   [398.19 ms 402.82 ms 408.83 ms]
# CUDA/2**22x16           time:   [631.68 ms 677.49 ms 742.40 ms]
# CUDA/2**23x16           time:   [1.1563 s 1.4789 s 1.8148 s]

# CUDA/2**17x16           time:   [185.24 ms 185.84 ms 186.46 ms]
# CUDA/2**18x16           time:   [199.90 ms 200.52 ms 201.04 ms]
# CUDA/2**19x16           time:   [225.65 ms 227.59 ms 230.53 ms]
# CUDA/2**20x16           time:   [281.39 ms 281.46 ms 281.53 ms]
# CUDA/2**21x16           time:   [397.56 ms 397.67 ms 397.78 ms]
# CUDA/2**22x16           time:   [631.64 ms 632.87 ms 634.17 ms]
# CUDA/2**23x16           time:   [1.1640 s 1.1827 s 1.2019 s]


# CUDA/2**17x16           time:   [186.36 ms 187.56 ms 188.80 ms]
# CUDA/2**18x16           time:   [199.41 ms 200.05 ms 200.76 ms]
# CUDA/2**19x16           time:   [225.83 ms 226.83 ms 227.92 ms]
# CUDA/2**20x16           time:   [280.01 ms 280.40 ms 280.75 ms]
# CUDA/2**21x16           time:   [397.38 ms 399.05 ms 402.17 ms]
# CUDA/2**22x16           time:   [631.36 ms 644.61 ms 659.52 ms]
# CUDA/2**23x16           time:   [1.2303 s 1.3671 s 1.5269 s]

batch_16_1 = [188.74, 201.02, 225.40, 280.63, 402.82, 677.49, 1478.9]
batch_16_2 = [185.84, 200.52, 227.59, 281.46, 397.67, 632.87, 1182.7]
batch_16_3 = [187.56, 200.05, 226.83, 280.40, 399.05, 644.61, 1367.1]

batch_16 = []
for i in range(0, 7):
    batch_16.append(round((batch_16_1[i] + batch_16_2[i] + batch_16_3[i])/3,2))

batch_2_impro = []
batch_4_impro = []
batch_8_impro = []
batch_16_impro = []

for i in range(7):
    batch_2_impro.append(round(2*batch_1[i]/batch_2[i]-1,2))
for i in range(7):
    batch_4_impro.append(round(4*batch_1[i]/batch_4[i]-1,2))
for i in range(7):
    batch_8_impro.append(round(8*batch_1[i]/batch_8[i]-1,2))
for i in range(7):
    batch_16_impro.append(round(16*batch_1[i]/batch_16[i]-1,2))

print(batch_2_impro)
print(batch_4_impro)
print(batch_8_impro)
print(batch_16_impro)