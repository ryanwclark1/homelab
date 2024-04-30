#!/bin/bash
WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

# Path to the inventory JSON file
inventory='../../inventory.json'

# Temporary file to hold IPs
temp_ips='temp_ips.txt'

# YAML file to update
yaml_file=$WORKING_DIR/helm/values.yaml

# Placeholder in the YAML file to replace
placeholder='$endpoints'

# Extract IP addresses and format them
mapfile -t all < <(jq -r '.nodes[].vms[].ip' "$inventory")
for ip in "${all[@]}"; do
    echo "- $ip"
done > "$temp_ips"

# Replace placeholder in the YAML file with the list of IPs
sed -i "/$placeholder/r $temp_ips" "$yaml_file"
sed -i "/$placeholder/d" "$yaml_file"

# Remove the temporary file
rm "$temp_ips"

echo "YAML file updated successfully."
