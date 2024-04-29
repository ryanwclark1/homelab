#!/bin/bash

# Set the LH_URL of the YAML file
LH_URL="https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml"
# Set the file name to save the downloaded YAML
LH_FILE_NAME="longhorn.yaml"

# Download the file using curl
curl -s -o "$LH_FILE_NAME" "$LH_URL"
if [ $? -ne 0 ]; then
    echo "Error downloading the file."
    exit 1
fi

# Check if the replacement string exists in the file
grep -q "priority-class: longhorn-critical" "$LH_FILE_NAME"
if [ $? -ne 0 ]; then
    echo "Replacement string not found in the file."
    exit 1
fi

# Perform the find and replace
sed -i 's/priority-class: longhorn-critical/system-managed-components-node-selector: longhorn=true/' "$LH_FILE_NAME"
if [ $? -ne 0 ]; then
    echo "Error replacing the text."
    exit 1
fi

# Apply the configuration using kubectl
kubectl apply -f "$LH_FILE_NAME"
if [ $? -ne 0 ]; then
    echo "Error applying the configuration."
    exit 1
fi

echo "Configuration applied successfully."