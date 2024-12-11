cat reports/bench_inner.txt | grep "time:" > reports/bench_sys.txt

# Define the input file
input_file="reports/bench_sys.txt"

# Define the instances
instances=("jy-msm" "wlc-msm-con" "wlc-msm-bal" "sppark")

# Initialize associative arrays to store the results
declare -A results
declare -A counts

# Initialize line number
line_number=0

# Count the total number of lines in the input file
total_lines=$(wc -l < "$input_file")

# Calculate the number of lines per instance
lines_per_instance=$((total_lines / 4))

# Check if the input file exists and is readable
if [[ ! -f "$input_file" || ! -r "$input_file" ]]; then
    echo "Error: Input file does not exist or is not readable."
    exit 1
fi

# Read the input file line by line
while IFS= read -r line; do
    if [[ $line =~ CUDA/2\*\*([0-9]+)x1[[:space:]]+time:[[:space:]]+\[([0-9.]+)[[:space:]]+ms[[:space:]]+([0-9.]+)[[:space:]]+ms[[:space:]]+([0-9.]+)[[:space:]]+ms ]]; then
        power=${BASH_REMATCH[1]}
        middle_time=${BASH_REMATCH[3]}        
        # Determine the instance based on the line number
        line_number=$((line_number + 1))
        if (( line_number <= lines_per_instance )); then
            instance="jy-msm"
        elif (( line_number <= 2 * lines_per_instance )); then
            instance="wlc-msm-con"
        elif (( line_number <= 3 * lines_per_instance )); then
            instance="wlc-msm-bal"
        else
            instance="sppark"
        fi
        # Store the result and count
        results["$instance,$power"]=$(echo "${results["$instance,$power"]:-0} + $middle_time" | bc)
        counts["$instance,$power"]=$((counts["$instance,$power"] + 1))
        # echo "Matched line: $line -> Instance: $instance, Power: $power, Middle Time: $middle_time"  # Debugging line
    else
        no_match_lines+=("$line")  # Collect lines that do not match for debugging
    fi
done < "$input_file"

echo > reports/bench_sys_avg.txt
# Print the results in the desired format
for instance in "${instances[@]}"; do
    echo "--------------------"
    for power in $(echo "${!results[@]}" | tr ' ' '\n' | cut -d',' -f2 | sort -u); do
        total_time=${results["$instance,$power"]:-0}
        count=${counts["$instance,$power"]:-0}
        if [ "$count" -gt 0 ]; then
            average_time=$(echo "scale=3; $total_time / $count" | bc)
            echo "$instance 2**$power: $average_time ms" >> reports/bench_sys_avg.txt
        else
            echo "$instance 2**$power: No results"
        fi
    done
done

# Print lines that did not match for debugging
if [ ${#no_match_lines[@]} -gt 0 ]; then
    echo "--------------------"
    echo "Lines that did not match:"
    for line in "${no_match_lines[@]}"; do
        echo "$line"
    done
fi