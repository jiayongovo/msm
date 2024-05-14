369.255
666.41  
1335.85     
2620.7       
3660.75       
5181.8    

msm = [369.255, 666.41, 1335.85, 2620.7, 3660.75, 5181.8]

index = [2,4,8,12,16]
for i in range(1, len(msm)):
    # print((index[i-1]*msm[0]))
    print(round(1- msm[i]/(index[i-1]*msm[0]),2))