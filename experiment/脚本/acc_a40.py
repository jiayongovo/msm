66.858
130.765
253.560
492.790
983.045
1958.250

wlc_bal = [66.858, 130.765, 253.560, 492.790, 983.045, 1958.250]


29.3735
51.651
95.314
184.665
384.030

wlc_con = [29.3735, 51.651, 95.314, 184.665, 384.030]


123.657
200.194
349.521
687.308
1248.96
2380.58

cuzk = [123.657, 200.194, 349.521, 687.308, 1248.96,2380.58]



46.077
67.996
111.640
198.040
398.610
795.110

jy_msm = [46.077, 67.996, 111.640, 198.040, 398.610, 795.110]



c_wlc_bal_jy = [round(x / y, 2) for x, y in zip(wlc_bal, jy_msm)]
c_wlc_con_jy = [round(x / y, 2) for x, y in zip(wlc_con, jy_msm)]
c_cuzk_jy = [round(x / y, 2) for x, y in zip(cuzk, jy_msm)]

print(c_wlc_bal_jy)
print(c_wlc_con_jy)
print(c_cuzk_jy)

print(sum(c_cuzk_jy)/len(c_cuzk_jy))
