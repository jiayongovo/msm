rm experiment/baseline/result/RTX4090/bls12-377/jy-msm21-26.txt
rm experiment/baseline/result/RTX4090/bls12-377/yrrid_21-26.txt
rm experiment/baseline/result/RTX4090/bls12-377/matter_lab_21-26.txt

for m in $(seq 1 3)
do 
   for i in $(seq 21 26)
   do
      BENCH_NPOW=$i cargo bench | grep time: >> experiment/baseline/result/RTX4090/bls12-377/jy-msm21-26.txt
   done
done 


cd experiment/baseline/submission-msm-gpu
for m in $(seq 1 3)
do 
   for i in $(seq 21 26)
   do
      BENCH_NPOW=$i cargo bench | grep time: >> experiment/baseline/result/RTX4090/bls12-377/yrrid_21-26.txt
   done
done 

cd ../z-prize-msm-gpu
for m in $(seq 1 3)
do 
   for i in $(seq 21 26)
   do
      BENCH_NPOW=$i cargo bench | grep time: >> experiment/baseline/result/RTX4090/bls12-377/matter_lab_21-26.txt
   done
done 