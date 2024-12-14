import matplotlib.pyplot as plt
import re

# Read the results from the file
with open('reports/bench_sys_avg.txt', 'r') as file:
    lines = file.readlines()

# Initialize dictionaries to store the results
results = {'jy-msm': {}, 'wlc-msm-con': {}, 'wlc-msm-bal': {}, 'sppark': {}}

# Parse the results
for line in lines:
    match = re.match(r'(\w\w+|\w+-\w+|\w+-\w+-\w+) 2\*\*(\d+): ([0-9.]+) ms',
                     line)

    if match:
        instance, power, time = match.groups()
        power = int(power)
        time = float(time)
        print(instance, power, time)
        results[instance][power] = time

# Plot the results
plt.figure(figsize=(10, 6))

for instance, data in results.items():
    powers = sorted(data.keys())
    times = [data[power] for power in powers]
    plt.plot(powers, times, marker='o', label=instance)

plt.xlabel('Power (2**N)')
plt.ylabel('Time (ms)')
plt.title('Benchmark Results')
plt.legend()
plt.grid(True)
plt.show()
