wlc_msm_bal_gb = [1.59, 2.72, 4.96, 9.43, 18.36,0]
wlc_msm_con_gb = [2.62, 4.74, 8.94, 17.34,0,0]
jy_msm_gb = [1.13, 1.67, 2.75, 4.9, 9.22, 17.84]

bal_jy = []
con_jy = []

for i in range(0, len(wlc_msm_bal_gb)):
    print(round(wlc_msm_bal_gb[i]/jy_msm_gb[i],2))
    bal_jy.append(round(wlc_msm_bal_gb[i]/jy_msm_gb[i],2))
    print(round(wlc_msm_con_gb[i]/jy_msm_gb[i],2))
    con_jy.append(round(wlc_msm_con_gb[i]/jy_msm_gb[i],2))
    print("\n")

print(bal_jy)
print(con_jy)


# 去除0的bal_jy
print(sum(bal_jy)/(len(bal_jy)-1))
print(sum(con_jy)/(len(con_jy)-2))


# import numpy as np
# import matplotlib.pyplot as plt


# plt.rcParams['font.family'] = ['Times New Roman','SimHei']




# # X轴数据，根据数组长度生成
# x = np.arange(max(len(bal_jy), len(con_jy)))

# # 绘制柱状图
# width = 0.3  # 柱子宽度
# plt.bar(x - width/2, bal_jy, width=width, color='dodgerblue', label='wlc_bal/jy_msm')
# plt.bar(x + width/2, con_jy, width=width, color='orange', label='wlc_con/jy_msm')

# # 添加图例
# plt.legend(loc='upper left', bbox_to_anchor=(0.03, 0.95))

# # 添加标题和标签
# # plt.title('RTX4090 机器下不同 MSM 设计下 GPU 内存占用')
# plt.xlabel('MSM 规模')
# plt.ylabel('RTX4090 上内存占用比')


# # 设置X轴刻度为指数形式
# x_ticks = [r'$2^{20}$', r'$2^{21}$', r'$2^{22}$', r'$2^{23}$', r'$2^{24}$', r'$2^{25}$']
# for i in range(len(x)):
#     if bal_jy[i] != 0:
#         plt.text(x[i] - width/2, bal_jy[i] + 0.01, str(bal_jy[i]), ha='center')
#     if con_jy[i] != 0:
#         plt.text(x[i] + width/2, con_jy[i] + 0.01, str(con_jy[i]), ha='center')


# plt.xticks(x, x_ticks)

# # 展示图表
# plt.show()
