
127.75
206.96
356.2
645.405

matter_lab = [0,0,127.75,206.96,356.2,645.405]


50.159
70.904
118.390
216.315
406.880
787.560

yarid = [50.159,70.904,118.390,216.315,406.880,787.560]


69.011
110.860
195.860
367.080
706.105
1469.750

jy_msm = [69.011,110.860,195.860,367.080,706.105,1469.750]

c_matter_lab_jy = [round(x / y, 2) for x, y in zip(matter_lab, jy_msm)]
c_yarid_jy = [round(x / y, 2) for x, y in zip(yarid, jy_msm)]
print(c_matter_lab_jy)
print(c_yarid_jy)


print(sum(c_matter_lab_jy)/4)
print(sum(c_yarid_jy)/len(c_yarid_jy))