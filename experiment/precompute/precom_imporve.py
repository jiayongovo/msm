# 不同预计算间隔下，不同MSM规模的计算时间
# M = 1  2 4 8 12 16  

msm_17 = [28.799, 19.813, 16.401, 16.612, 16.886, 20.877]
msm_18 = [30.214, 21.286, 17.834, 18.141, 18.235, 22.384]
msm_19 = [33.854, 24.692, 21.291, 21.474, 21.716, 25.712]
msm_20 = [40.851, 31.062, 27.639, 27.883, 28.385, 32.664]
msm_21 = [54.778, 45.167, 41.848, 41.621, 42.246, 46.368]
msm_22 = [81.963,71.284,68.212,68.471,69.007,73.223]
msm_23 = [132.485,123.61,119.51,121.15,120.685,124.68]
msm_24 = [0,233.905,219.07,220.665,225.375,225.375]
improve = []
for msm_list in [msm_17, msm_18, msm_19, msm_20, msm_21, msm_22, msm_23, msm_24]:
    for i in range(0, len(msm_list)):
        if msm_list[i] == 0:
            improve.append('0%')
            continue
        improve.append('{:.2%}'.format(msm_list[5]/msm_list[i]-1))
    print(improve)
    improve = []





# 15.675
# 29.431
# 57.776
# 110.66


# 27.883
# 41.621
# 68.471
# 121.15

# wlc_msm_con = [15.675, 29.431, 57.776, 110.66]
# jy_msm = [27.883, 41.621, 68.471, 121.15]
# for wlc, jy in zip(wlc_msm_con, jy_msm):
#     print(round(wlc/jy, 2))

# 2.76 + 2.85 + 2.66 + 2.89 + 2.87


# 27.29%
# 25.51%
# 20.76%
# 18.18%
# 10.80%


prove = [27.29, 25.51, 20.76, 18.18, 10.80]
print(sum(prove)/5)

# 25.67%
# 23.39%
# 19.74%
# 17.15%
# 11.41%


prove = [25.67, 23.39, 19.74, 17.15, 11.41]

print(sum(prove)/5)