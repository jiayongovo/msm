import pandas as pd
import re

# Read the results from the file
with open('reports/bench_sys_avg.txt', 'r') as file:
    lines = file.readlines()

# Initialize dictionaries to store the results
results = {'jy-msm': {}, 'wlc-msm-con': {}, 'wlc-msm-bal': {}, 'sppark': {}}

# Set to store all unique power values
all_powers = set()

# Parse the results
for line in lines:
    match = re.match(r'(\w\w+|\w+-\w+|\w+-\w+-\w+) 2\*\*(\d+): ([0-9.]+) ms',
                     line)
    if match:
        instance, power, time = match.groups()
        power = int(power)
        time = float(time)
        print(f"Parsed: {instance}, 2**{power}, {time} ms")
        results[instance][power] = time
        all_powers.add(power)

# Convert the set of all powers to a sorted list
all_powers = sorted(all_powers)

# Prepare the data for the table
table_data = {'Power': [f'2**{p}' for p in all_powers]}
table_data['Speedup (jy-msm vs wlc-msm-con)'] = []
table_data['Speedup (jy-msm vs wlc-msm-bal)'] = []
table_data['Speedup (jy-msm vs sppark)'] = []

# Calculate the speedup
for power in all_powers:
    jy_msm_time = results['jy-msm'].get(power, float('inf'))
    wl_msm_con_time = results['wlc-msm-con'].get(power, float('inf'))
    wlc_msm_bal_time = results['wlc-msm-bal'].get(power, float('inf'))
    sppark_time = results['sppark'].get(power, float('inf'))

    if jy_msm_time == 0:
        jy_msm_time = float('inf')

    speedup_wlc_msm_con = wl_msm_con_time / jy_msm_time if jy_msm_time != 0 else float(
        'inf')
    speedup_wlc_msm_bal = wlc_msm_bal_time / jy_msm_time if jy_msm_time != 0 else float(
        'inf')
    speedup_sppark = sppark_time / jy_msm_time if jy_msm_time != 0 else float(
        'inf')

    table_data['Speedup (jy-msm vs wlc-msm-con)'].append(speedup_wlc_msm_con)
    table_data['Speedup (jy-msm vs wlc-msm-bal)'].append(speedup_wlc_msm_bal)
    table_data['Speedup (jy-msm vs sppark)'].append(speedup_sppark)

# Create a DataFrame
df = pd.DataFrame(table_data)

# Print the DataFrame
print(df)

# Optionally, save the DataFrame to a CSV file
df.to_csv('reports/speedup_table.csv', index=False)
