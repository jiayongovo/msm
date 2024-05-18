jy_msm_m_1_1 = [18.375,20.732,23.513,30.084,42.657,71.295,129.81,0]
jy_msm_m_1_2 = [18.740,20.133,23.435,29.723,44.199,70.442,128.16,0]
jy_msm_m_1_3 = [18.348,20.511,24.010,30.108,43.292,69.974,128.20,0]

jy_msm_m_1 = []

for i in range(0, 8):
    jy_msm_m_1.append(round((jy_msm_m_1_1[i] + jy_msm_m_1_2[i] + jy_msm_m_1_3[i])/3,2))


jy_msm_m_2_1 = [14.117,15.603,19.690,25.515,39.296,64.121,118.19,228.14]
jy_msm_m_2_2 = [14.441,15.602,19.209,26.285,38.877,66.310,128.24,221.03]
jy_msm_m_2_3 = [14.572,16.541,19.349,25.469,38.990,68.075,122.24,242.88]

jy_msm_m_2 = []

for i in range(0, 8):
    jy_msm_m_2.append(round((jy_msm_m_2_1[i] + jy_msm_m_2_2[i] + jy_msm_m_2_3[i])/3,2))


jy_msm_m_4_1 = [12.966,14.328,16.911,23.697,37.000,62.163,116.27,239.73]
jy_msm_m_4_2 = [12.694,14.682,17.395,23.867,37.115,63.078,116.83,224.16]
jy_msm_m_4_3 = [12.400,13.855,16.771,24.140,37.005,64.331,114.31,221.99]


jy_msm_m_4 = []
for i in range(0, 8):
    jy_msm_m_4.append(round((jy_msm_m_4_1[i] + jy_msm_m_4_2[i] + jy_msm_m_4_3[i])/3,2))



jy_msm_m_8_1 = [12.974,13.975,16.837,24.336,37.652,63.832,117.15,231.32]
jy_msm_m_8_2 = [12.361,14.259,17.167,23.725,38.399,66.129,117.03,224.54]
jy_msm_m_8_3 = [12.745,14.857,17.627,23.825,36.906,64.230,119.28,242.09]


jy_msm_m_8 = []
for i in range(0, 8):
    jy_msm_m_8.append(round((jy_msm_m_8_1[i] + jy_msm_m_8_2[i] + jy_msm_m_8_3[i])/3,2))


jy_msm_12_1 = [12.768,14.313,18.008,23.850,37.883,64.399,118.32,233.62]
jy_msm_12_2 = [13.066,14.771,17.539,24.004,37.542,64.774,118.23,236.82]
jy_msm_12_3 = [13.122,14.801,17.463,23.539,37.405,62.205,114.50,220.59]


jy_msm_m_12 = []
for i in range(0, 8):
    jy_msm_m_12.append(round((jy_msm_12_1[i] + jy_msm_12_2[i] + jy_msm_12_3[i])/3,2))


jy_msm_16_1 = [14.860,16.482,19.758,25.597,39.354,67.732,122.89,221.57]
jy_msm_16_2 = [14.803,16.424,19.571,25.476,38.877,67.197,124.68,217.60]
jy_msm_16_3 = [14.386,16.299,18.882,25.417,38.582,63.809,115.66,212.58]


jy_msm_m_16 = []
for i in range(0, 8):
    jy_msm_m_16.append(round((jy_msm_16_1[i] + jy_msm_16_2[i] + jy_msm_16_3[i])/3,2))


print(jy_msm_m_1)
print(jy_msm_m_2)
print(jy_msm_m_4)
print(jy_msm_m_8)
print(jy_msm_m_12)
print(jy_msm_m_16)



jy_msm_m_1 = [18.49, 20.46, 23.65, 29.97, 43.38, 70.57, 128.72, 0.0]
jy_msm_m_2 = [14.38, 15.92, 19.42, 25.76, 39.05, 66.17, 122.89, 230.68]
jy_msm_m_4 = [12.69, 14.29, 17.03, 23.9, 37.04, 63.19, 115.8, 228.63]
jy_msm_m_8 = [12.69, 14.36, 17.21, 23.96, 37.65, 64.73, 117.82, 232.65]
jy_msm_m_12 = [12.99, 14.63, 17.67, 23.8, 37.61, 63.79, 117.02, 230.34]
jy_msm_m_16 = [14.68, 16.4, 19.4, 25.5, 38.94, 66.25, 121.08, 217.25]

msm_17 = [18.49, 14.38, 12.69, 12.69, 12.99, 14.68]
msm_18 = [20.46, 15.92, 14.29, 14.36, 14.63, 16.4]
msm_19 = [23.65, 19.42, 17.03, 17.21, 17.67, 19.4]
msm_20 = [29.97, 25.76, 23.9, 23.96, 23.8, 25.5]
msm_21 = [43.38, 39.05, 37.04, 37.65, 37.61, 38.94]
# msm_22 = [70.57, 66.17, 63.19, 64.73, 63.79, 66.25]
# msm_23 = [128.72, 122.89, 115.8, 117.82, 117.02, 121.08]
# msm_24 = [0.0, 230.68, 228.63, 232.65, 230.34, 217.25]

import matplotlib.pyplot as plt

# 设置中文字体
plt.rcParams['font.family'] = ['Times New Roman', 'SimHei']

M = [1, 2, 4, 8, 12, 16]



# 颜色
colors = ['dodgerblue', 'forestgreen', 'red', 'orange', 'purple']

# 绘图
plt.figure(figsize=(10, 6))

plt.plot(M, msm_17, marker='o', color=colors[0], label='$2^{17}$')
plt.plot(M, msm_18, marker='s', color=colors[1], label='$2^{18}$')
plt.plot(M, msm_19, marker='^', color=colors[2], label='$2^{19}$')
plt.plot(M, msm_20, marker='x', color=colors[3], label='$2^{20}$')
plt.plot(M, msm_21, marker='d', color=colors[4], label='$2^{21}$')

# plt.axvline(x=4, color='gray', linestyle='--')
# plt.axvline(x=8, color='gray', linestyle='--')

# 添加标题和标签
# plt.title('Impact of precomputation interval M on MSM performance')
plt.xlabel('预计算间隔 M', fontsize=16)
plt.ylabel('MSM 计算时间(ms)', fontsize=16)

# 添加图例
plt.legend()
plt.xticks(M,fontsize=12)
# plt.ylim(16, 55)
plt.yticks(fontsize=12)
plt.legend(loc=(0.7,0.7))
plt.grid(axis='y', which='major', linestyle='--')  # 只添加主要刻度的水平网格线

# 显示图表
plt.show()