4
7
20
62
240
1100
4000

gzkp = [4, 7, 20, 62, 240, 1100, 4000]

25.527
28.821
35.804
62.706
170.780
598.200
2581.500
jy_msm = [25.527, 28.821, 35.804, 62.706, 170.780, 598.200, 2581.500]

for gzkp, jy in zip(gzkp, jy_msm):
    print(round(gzkp/jy, 2))