import matplotlib.pyplot as plt

# 设置中文字体
plt.rcParams['font.family'] = ['Times New Roman', 'SimHei']

M = [1, 2, 4, 8, 12, 16]

msm_17 = [28.799, 19.813, 16.401, 16.612, 16.886, 20.877]
msm_18 = [30.214, 21.286, 17.834, 18.141, 18.235, 22.384]
msm_19 = [33.854, 24.692, 21.291, 21.474, 21.716, 25.712]
msm_20 = [40.851, 31.062, 27.639, 27.883, 28.385, 32.664]
msm_21 = [54.778, 45.167, 41.848, 41.621, 42.246, 46.368]
# msm_22 = [81.963,71.284,68.212,68.471,69.007,73.223]
# msm_23 = [132.485,123.61,119.51,121.15,120.685,124.68]
# msm_24 = [0,233.905,219.07,220.665,225.375,225.375]

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