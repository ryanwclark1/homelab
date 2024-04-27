#!/bin/bash

cat <<EOF > ./helm/test-resources.yaml
  apiVersion: v1
  kind: Namespace
  metadata:
    name: cert-manager-test
  ---
  apiVersion: cert-manager.io/v1
  kind: Issuer
  metadata:
    name: test-selfsigned
    namespace: cert-manager-test
  spec:
    selfSigned: {}
  ---
  apiVersion: cert-manager.io/v1
  kind: Certificate
  metadata:
    name: selfsigned-cert
    namespace: cert-manager-test
  spec:
    dnsNames:
      - example.com
    secretName: selfsigned-cert-tls
    issuerRef:
      name: test-selfsigned
EOF

WORKING_DIR=$(dirname "$BASH_SOURCE")
WORKING_DIR=$(cd "$WORKING_DIR"; pwd)

# Define the repository owner and name
REPO_OWNER="cert-manager"
REPO_NAME="cert-manager"

# GitHub API URL for the latest release
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"

# Use curl to fetch the latest release data
# Note: GitHub recommends setting a User-Agent
response=$(curl -s -H "User-Agent: MyClient/1.0.0" "$API_URL")

# Check if the request was successful
if echo "$response" | grep -q '"tag_name":'; then
  # Extract the tag name which typically is the version
  latest_version=$(echo "$response" | jq -r '.tag_name')
  echo "Latest release version of $REPO_NAME: $latest_version"
else
  echo "Failed to fetch the latest release version of $REPO_NAME."
  echo "$response"
fi


# Install Cert-Manager (should already have this with Rancher deployment)
# Check if we already have it by querying namespace
namespaceStatus=""
namespaceStatus=$(kubectl get ns cert-manager -o json | jq .status.phase -r)
if [ $namespaceStatus == "Active" ]; then
  echo -e " \033[32;5mCert-Manager already installed, upgrading with new values.yaml...\033[0m"
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${latest_version}/cert-manager.crds.yaml
  helm upgrade \
  cert-manager \
  jetstack/cert-manager \
  --namespace cert-manager \
  --values $WORKING_DIR/helm/test-resources.yaml \
  --version ${latest_version} \
  --set installCRDs=true
else
  echo "Cert-Manager is not present, installing..."
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${latest_version}/cert-manager.crds.yaml
  helm repo add jetstack https://charts.jetstack.io
  helm repo update
  helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version ${latest_version} \
  --set installCRDs=true
fi