#!/bin/bash

# Path setup
WORKING_DIR=$(cd "$(dirname "$BASH_SOURCE")"; pwd)
inventory="$WORKING_DIR/../../inventory.json"
NAME_SPACE="monitoring"
temp_ips='temp_ips.txt'
yaml_file="$WORKING_DIR/helm/values.yaml"
backup_file="${yaml_file}.backup"
placeholder='\$endpoints'

# Repository details
REPO_OWNER="prometheus-community"
REPO_NAME="kube-prometheus-stack"
API_URL="https://artifacthub.io/api/v1/packages/helm/$REPO_OWNER/$REPO_NAME/feed/rss"

# Check for required files
if [ ! -f "$inventory" ]; then
    echo "Inventory file not found at $inventory"
    exit 1
fi

# Fetch the latest version number
get_artifacthub() {
    response=$(curl -s "$API_URL")
    if [ $? -eq 0 ] && echo "$response" | grep -q '<title>'; then
        latest_version=$(echo "$response" | xmllint --xpath 'string(//rss/channel/item[1]/title)' -)
        if [ -n "$latest_version" ]; then
            echo "Latest release version of $REPO_NAME: $latest_version"
        else
            echo "Failed to extract version, please check the XML structure and XPath."
            exit 1
        fi
    else
        echo "Failed to fetch the RSS feed or no <title> tags found."
        echo "$response"
        exit 1
    fi
}

# Create a Kubernetes secret
create_secret() {
    if [ -f "$WORKING_DIR/.env" ]; then
        kubectl create secret generic grafana-admin-credentials \
        --from-env-file="$WORKING_DIR/.env" \
        --namespace $NAME_SPACE
        echo "Grafana admin credentials created successfully."
    else
        echo "No .env file found at $WORKING_DIR."
        exit 1
    fi
}

# Backup YAML file
backup_file() {
    if [ -f "$yaml_file" ]; then
        cp "$yaml_file" "$backup_file"
        echo "Backup of values.yaml created."
    else
        echo "values.yaml does not exist. Exiting."
        exit 1
    fi
}

# Main operations
get_artifacthub
create_secret
backup_file

# Extract and format IP addresses
# mapfile -t all_ips < <(jq -r '.nodes[].vms[].ip' "$inventory")
# printf "    - %s\n" "${all_ips[@]}" > "$temp_ips"

# # Update YAML file with IPs
# if grep -q "$placeholder" "$yaml_file"; then
#     sed -i "/$placeholder/r $temp_ips" "$yaml_file"
#     sed -i "/$placeholder/d" "$yaml_file"
# else
#     echo "Placeholder '$placeholder' not found in values.yaml. Exiting."
#     exit 1
# fi

# Ensure the namespace exists before proceeding
if kubectl get ns "$NAME_SPACE" > /dev/null 2>&1; then
  echo -e "Namespace '$NAME_SPACE' namespace exists, checking installation status..."
else
  echo "Namespace '$NAME_SPACE' does not exist, creating it..."
  kubectl create namespace "$NAME_SPACE"
fi

# Helm operations
release_exists=$(helm list -n "$NAME_SPACE" | grep -q 'kube-prometheus-stack')
if [ $? -ne 0 ]; then
    echo "No active release found. Installing..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
    --namespace $NAME_SPACE \
    -f "$WORKING_DIR/helm/values.yaml"
    # --version "${latest_version}"
else
    echo "Release found, upgrading..."
    helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
    --namespace $NAME_SPACE \
    -f "$WORKING_DIR/helm/values.yaml"
    # --version "${latest_version}"
fi

# Restore original YAML file and apply ingress
# mv "$backup_file" "$yaml_file"
kubectl apply -f "$WORKING_DIR/helm/ingress.yaml" -n $NAME_SPACE
