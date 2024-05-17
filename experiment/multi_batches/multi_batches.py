# CUDA/2**17x1            time:   [16.578 ms 16.603 ms 16.640 ms]
# CUDA/2**18x1            time:   [18.270 ms 18.311 ms 18.362 ms]
# CUDA/2**19x1            time:   [21.322 ms 21.424 ms 21.553 ms]
# CUDA/2**20x1            time:   [27.529 ms 27.655 ms 27.878 ms]
# CUDA/2**21x1            time:   [40.944 ms 41.215 ms 41.588 ms]
# CUDA/2**22x1            time:   [67.135 ms 67.488 ms 67.917 ms]
# CUDA/2**23x1            time:   [118.91 ms 121.54 ms 124.89 ms]


16.603
18.311
21.424
27.655
41.215
67.488
121.54

batch_1 = [16.603, 18.311, 21.424, 27.655, 41.215, 67.488, 121.54]

# CUDA/2**17x2            time:   [31.985 ms 32.091 ms 32.207 ms]
# CUDA/2**18x2            time:   [34.525 ms 34.619 ms 34.698 ms]
# CUDA/2**19x2            time:   [39.632 ms 39.782 ms 39.968 ms]
# CUDA/2**20x2            time:   [49.072 ms 49.402 ms 49.885 ms]
# CUDA/2**21x2            time:   [71.213 ms 72.130 ms 73.029 ms]
# CUDA/2**22x2            time:   [109.41 ms 109.63 ms 109.83 ms]
# CUDA/2**23x2            time:   [194.24 ms 194.61 ms 195.04 ms]


32.091
34.619
39.782
49.402
72.130
109.63
194.61

batch_2 = [32.091, 34.619, 39.782, 49.402, 72.130, 109.63, 194.61]


# CUDA/2**17x4            time:   [63.275 ms 63.449 ms 63.687 ms]
# CUDA/2**18x4            time:   [67.244 ms 67.468 ms 67.678 ms]
# CUDA/2**19x4            time:   [75.636 ms 76.056 ms 76.581 ms]
# CUDA/2**20x4            time:   [91.701 ms 92.316 ms 93.255 ms]
# CUDA/2**21x4            time:   [126.38 ms 126.63 ms 126.88 ms]
# CUDA/2**22x4            time:   [195.35 ms 202.74 ms 212.13 ms]
# CUDA/2**23x4            time:   [343.02 ms 343.40 ms 343.75 ms]

batch_4 = [63.449, 67.468, 76.056, 92.316, 126.63, 202.74, 343.40]



# CUDA/2**17x8            time:   [125.15 ms 125.33 ms 125.45 ms]
# CUDA/2**18x8            time:   [131.75 ms 131.97 ms 132.42 ms]
# CUDA/2**19x8            time:   [147.25 ms 147.88 ms 148.41 ms]
# CUDA/2**20x8            time:   [177.08 ms 178.51 ms 180.31 ms]
# CUDA/2**21x8            time:   [239.70 ms 243.64 ms 248.62 ms]
# CUDA/2**22x8            time:   [366.01 ms 395.23 ms 435.98 ms]
# CUDA/2**23x8            time:   [641.64 ms 648.69 ms 658.53 ms]

batch_8 = [125.33, 131.97, 147.88, 178.51, 243.64, 395.23, 648.69]


# CUDA/2**17x16           time:   [249.28 ms 249.69 ms 250.21 ms]
# CUDA/2**18x16           time:   [262.92 ms 263.63 ms 264.41 ms]
# CUDA/2**19x16           time:   [290.68 ms 293.21 ms 296.95 ms]
# CUDA/2**20x16           time:   [345.42 ms 346.77 ms 349.22 ms]
# CUDA/2**21x16           time:   [463.92 ms 466.12 ms 470.00 ms]
# CUDA/2**22x16           time:   [705.08 ms 732.67 ms 775.05 ms]
# CUDA/2**23x16           time:   [1.2710 s 1.5300 s 1.8862 s]

batch_16 = [249.69, 263.63, 293.21, 346.77, 466.12, 732.67, 1530.0]

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





