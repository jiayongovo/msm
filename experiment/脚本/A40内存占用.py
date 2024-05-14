1523
2667
4955
9531
18683
36991

wlc_msm_bal_mem = [1523, 2667, 4955, 9531, 18683, 36991]


2577
4729
9033
17641
34857


wlc_msm_con_mem = [2577, 4729, 9033, 17641, 34857,0]


1031
1583
2687
4895
9311
18147

jy_msm_mem = [1031, 1583, 2687, 4895, 9311, 18147]


wlc_msm_bal_gb = []
wlc_msm_con_gb = []
jy_msm_gb = []
for i in wlc_msm_bal_mem:
 
    wlc_msm_bal_gb.append(round(i/1024,2))

for i in wlc_msm_con_mem:

    wlc_msm_con_gb.append(round(i/1024,2))


for i in jy_msm_mem:

    jy_msm_gb.append(round(i/1024,2))

print(wlc_msm_bal_gb)
print(wlc_msm_con_gb)
print(jy_msm_gb)



import numpy as np
import matplotlib.pyplot as plt


plt.rcParams['font.family'] = ['Times New Roman','SimHei']



# X轴数据，根据数组长度生成
x = np.arange(max(len(wlc_msm_bal_gb), len(wlc_msm_con_gb), len(jy_msm_gb)))

# 绘制柱状图
width = 0.3  # 柱子宽度
plt.bar(x - width, wlc_msm_bal_gb, width=width, color='dodgerblue', label='wlc_bal')
plt.bar(x, wlc_msm_con_gb, width=width, color='orange', label='wlc_con')
plt.bar(x + width, jy_msm_gb, width=width, color='red', label='jy_msm')

# 添加图例
plt.legend(loc='upper left', bbox_to_anchor=(0.03, 0.95))

# 添加标题和标签
# plt.title('A40 机器下不同 MSM 设计下 GPU 内存占用')
plt.xlabel('MSM 规模')
plt.ylabel('GPU 内存占用 (GB)')

plt.axhline(y=48, color='k', linestyle='--', label='A40 48GB')

# 设置X轴刻度为指数形式
x_ticks = [r'$2^{20}$', r'$2^{21}$', r'$2^{22}$', r'$2^{23}$', r'$2^{24}$', r'$2^{25}$']
plt.text(2.5, 46, 'A40 48GB', color='k', fontsize=12, verticalalignment='center')
for i in range(len(x)):
    if wlc_msm_bal_gb[i] != 0:
        plt.text(x[i] - width, wlc_msm_bal_gb[i] + 0.1, str(wlc_msm_bal_gb[i]), ha='center')
    if wlc_msm_con_gb[i] != 0:
        plt.text(x[i], wlc_msm_con_gb[i] + 0.1, str(wlc_msm_con_gb[i]), ha='center')
    if jy_msm_gb[i] != 0:
        plt.text(x[i] + width, jy_msm_gb[i] + 0.1, str(jy_msm_gb[i]), ha='center')


plt.xticks(x, x_ticks)

# 展示图表
plt.show()
