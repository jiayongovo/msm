
# wlc_msm_bal
39.522
75.635
148.265
289.390
558.085

wlc_msm_bal = [39.522, 75.635, 148.265, 289.390, 558.085,0]

15.675
29.431
57.776
110.660

wlc_msm_con = [15.675, 29.431, 57.776, 110.660,0,0]


77.037
118.462
182.032
350.480
632.381

cuzk = [77.037, 118.462, 182.032, 350.480, 632.381,0]

27.883
41.621
68.471
121.150
220.655
421.907


jy_msm = [27.883, 41.621, 68.471, 121.150, 220.655, 421.907]


c_wlc_bal_jy = [round(x / y, 2) for x, y in zip(wlc_msm_bal, jy_msm)]
c_wlc_con_jy = [round(x / y, 2) for x, y in zip(wlc_msm_con, jy_msm)]
c_cuzk_jy = [round(x / y, 2) for x, y in zip(cuzk, jy_msm)]


print(c_wlc_bal_jy)
print(c_wlc_con_jy)
print(c_cuzk_jy)



# jy_msm M = 8
# 21.474
# 27.883
# 41.621
# 68.471
# 121.150
# 220.655

# cuzk
# 48.832
# 77.037
# 118.462
# 182.032
# 350.480
# 632.381

# wlc_msm_bal = [21.041, 39.522, 75.635, 148.265, 289.390, 558.085]
# jy_msm = [21.474, 27.883, 41.621, 68.471, 121.150, 220.655]
# cuzk = [48.832, 77.037, 118.462, 182.032, 350.480, 632.381]
# c_wlc_jy = [round(x / y, 2) for x, y in zip(wlc_msm_bal, jy_msm)]
# c_cuzk_jy = [round(x / y, 2) for x, y in zip(cuzk, jy_msm)]

# print(c_wlc_jy)
# print(c_cuzk_jy)





# import matplotlib.pyplot as plt
# import numpy as np
# wlc_msm_bal = [21.041, 39.522, 75.635, 148.265, 289.390, 558.085]
# jy_msm = [21.474, 27.883, 41.621, 68.471, 121.150, 220.655]

# acceleration_wlc = [0.98, 1.42, 1.82, 2.17, 2.39, 2.53]
# acceleration_jy = [2.27, 2.76, 2.85, 2.66, 2.89, 2.87]


# # 数据
# x = np.arange(len(acceleration_wlc))  # x 轴数据
# width = 0.35  # 柱子宽度

# # 绘图
# fig, ax = plt.subplots(figsize=(10, 6))
# rects1 = ax.bar(x - width/2, acceleration_wlc, width, label='WLC_MSM_BAL')
# rects2 = ax.bar(x + width/2, acceleration_jy, width, label='JY_MSM')

# # 添加标签
# ax.set_xlabel('数据点')
# ax.set_ylabel('加速比')
# ax.set_title('两组加速比')
# ax.set_xticks(x)
# ax.set_xticklabels(['数据点{}'.format(i+1) for i in range(len(x))])
# ax.legend()

# # 显示图表
# plt.show()
