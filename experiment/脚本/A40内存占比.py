wlc_bal = [1.49, 2.6, 4.84, 9.31, 18.25, 36.12]
wlc_con = [2.52, 4.62, 8.82, 17.23, 34.04, 0.0]
jy_msm = [1.01, 1.55, 2.62, 4.78, 9.09, 17.72]

bal_jy = []
con_jy = []

for i in range(0, len(wlc_bal)):
    print(round(wlc_bal[i]/jy_msm[i],2))
    bal_jy.append(round(wlc_bal[i]/jy_msm[i],2))
    print(round(wlc_con[i]/jy_msm[i],2))
    con_jy.append(round(wlc_con[i]/jy_msm[i],2))
    print("\n")

print(bal_jy)
print(con_jy)

# 去除0的bal_jy
print(sum(bal_jy)/(len(bal_jy)))
print(sum(con_jy)/(len(con_jy)-1))

import numpy as np
import matplotlib.pyplot as plt

