#!/bin/bash

#############################################
# YOU SHOULD ONLY NEED TO EDIT THIS SECTION #
#############################################


# Define the path to your inventory JSON file
inventory='../../inventory.json'

# Version of Kube-VIP to deploy
KVVERSION="v0.8.0"

# K3S Version, Rancher lags behind a bit so we need to specify the version
k3sVersion="v1.28.8+k3s1"

if [ ! -f "$inventory" ]; then
    echo "Inventory file not found at $inventory"
    exit 1
fi

master1_name=$(jq -r '.master1_name' "$inventory")

# Use jq to find the IP of the master1_name
master1=$(jq -r --arg vm_name "$master1_name" \
    '.nodes[].vms[] | select(.name == $vm_name) | .ip' "$inventory")

# User of remote machines
user=administrator

# Interface used on remotes
interface=eth0

# Set the virtual IP address (VIP)
vip=10.10.101.50

# Array of master nodes excluding master1
mapfile -t masters < <(jq -r --arg ip "$master1" '.nodes[].vms[] | select(.role == "master" and .ip != $ip) | .ip' "$inventory")

# Array of worker nodes
mapfile -t workers < <(jq -r '.nodes[].vms[] | select(.role != "master") | .ip' "$inventory")

# Array of storage nodes
mapfile -t storage < <(jq -r '.nodes[].vms[] | select(.role == "storage") | .ip' "$inventory")

# Array of all
mapfile -t all < <(jq -r '.nodes[].vms[].ip' "$inventory")

#Loadbalancer IP range
lbrange=10.10.101.60-10.10.101.100

#ssh certificate name variable
certName=id_rsa
SSH_KEY="$HOME/.ssh/$certName"

DOMAIN="techcasa.io"

#############################################
#            DO NOT EDIT BELOW              #
#############################################

intialize_nodes() {
  #add ssh keys for all nodes
  for node in "${all[@]}"; do
    ssh-keyscan -H $node >> ~/.ssh/known_hosts
    ssh-copy-id $user@$node
  done
}

add_policycoreutils() {
for newnode in "${all[@]}"; do
  ssh $user@$newnode -i ~/.ssh/$certName sudo su <<EOF
  NEEDRESTART_MODE=a apt install policycoreutils -y
  exit
EOF
  echo -e " \033[32;5mPolicyCoreUtils installed!\033[0m"
done
}

add_packages() {
for node in "${all[@]}"; do
  ssh $user@$node -i ~/.ssh/$certName sudo su <<EOF
  apt update
  apt install -y open-iscsi
  exit
EOF
  echo -e " \033[32;5mPolicyCoreUtils installed!\033[0m"
done
}

ask_to_intialize() {
  while true; do
      # Prompt the user. The colon after the question suggests a default value of 'yes'
      echo -n "Do you want to run intialize the environment? [Y/n]: "
      read -r user_input

      # Default to 'yes' if the input is empty
      if [[ -z "$user_input" ]]; then
        user_input="yes"
      fi

      # Convert to lowercase to simplify the comparison
      user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

      case "$user_input" in
        y|yes)
          intialize_nodes
          add_policycoreutils
          add_packages
          break
          ;;
        n|no)
          echo "Function will not run."
          break
          ;;
        *)
          echo "Invalid input, please type 'Y' for yes or 'n' for no."
          ask_to_intialize
          ;;
      esac
  done
}

# Check if the export statement already exists
check_export_statement() {
    grep -qF "export KUBECONFIG=$KUBECONFIG_PATH" "$1"
}

# Append the export statement to the appropriate shell configuration file
append_export_statement() {
    echo "export KUBECONFIG=$KUBECONFIG_PATH" >> "$1"
}

shell_config() {
  case "$SHELL_NAME" in
    "bash")
        CONFIG_FILE="/home/$CURRENT_USER/.bashrc"
        ;;
    "zsh")
        CONFIG_FILE="/home/$CURRENT_USER/.zshrc"
        ;;
    "fish")
        CONFIG_FILE="/home/$CURRENT_USER/.config/fish/config.fish"
        ;;
    *)
        echo "Unknown shell: $SHELL_NAME"
        exit 1
        ;;
  esac

  # Check if the export statement already exists in the configuration file
  if ! check_export_statement "$CONFIG_FILE"; then
      # If not, append the export statement
      append_export_statement "$CONFIG_FILE"
      echo "Export statement added to $CONFIG_FILE"
  else
      echo "Export statement already exists in $CONFIG_FILE"
  fi
}

# For testing purposes - in case time is wrong due to VM snapshots
sudo timedatectl set-ntp off
sudo timedatectl set-ntp on

# Move SSH certs to ~/.ssh and change permissions
# cp /home/$user/{$certName,$certName.pub} /home/$user/.ssh
chmod 600 $HOME/.ssh/$certName
chmod 644 $HOME/.ssh/$certName.pub

ask_to_intialize

# Install k3sup to local machine if not already present
if ! command -v k3sup version &> /dev/null
then
  echo -e " \033[31;5mk3sup not found, installing\033[0m"
  curl -sLS https://get.k3sup.dev | sh
  sudo install k3sup /usr/local/bin/
  rm k3sup
else
  echo -e " \033[32;5mk3sup already installed\033[0m"
fi

# Install Kubectl if not already present
source ../kubectl/deploy.sh

# TODO: Add fish and zsh support https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
# Add kubectl & alias to completions to bashrc
# SHELL_NAME=$(basename "$SHELL")

# # Check if the shell is Bash
# if [ "$SHELL_NAME" = "bash" ]; then
#   # Check if autocompletions are enabled
#   if type _init_completion &>/dev/null; then
#     echo "Autocompletions are enabled."
#     # Check if kubectl completions are already added to bashrc
#     if ! grep -q 'source <(kubectl completion bash)' ~/.bashrc; then
#       echo "Adding kubectl completions to ~/.bashrc"
#       echo 'source <(kubectl completion bash)' >> ~/.bashrc
#     if ! grep -q 'alias k=kubectl' ~/.bashrc; then
#       echo "Adding kubectl alias to ~/.bashrc"
#       echo 'alias k=kubectl' >> ~/.bashrc
#       echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
#     else
#       echo "kubectl completions are already added to ~/.bashrc. Skipping."
#     fi
#   else
#     # Reload bashrc
#     source ~/.bashrc
#     echo "Autocompletions are not enabled. Skipping kubectl completions setup."
#   fi
# else
#   echo "The shell is not Bash. Skipping kubectl completions setup."
# fi

# Create SSH Config file to ignore checking (don't use in production!)
# sed -i '1s/^/StrictHostKeyChecking no\n/' ~/.ssh/config




# Step 1: Bootstrap First k3s Node
mkdir ~/.kube
k3sup install \
  --ip $master1 \
  --user $user \
  --tls-san $vip \
  --cluster \
  --k3s-version $k3sVersion \
  --k3s-extra-args " \
    --disable traefik \
    --disable servicelb \
    --flannel-iface=$interface \
    --node-ip=$master1 \
    --node-taint node-role.kubernetes.io/master=true:NoSchedule" \
  --merge \
  --sudo \
  --local-path $HOME/.kube/config \
  --ssh-key $HOME/.ssh/$certName \
  --context k3s-ha

# Set the user & kubeconfig path
CURRENT_USER=$(whoami)
KUBECONFIG_PATH="/home/$CURRENT_USER/.kube/config"

# Determine the shell and the corresponding configuration file
SHELL_NAME=$(basename "$SHELL")

echo -e " \033[32;5mFirst Node bootstrapped successfully!\033[0m"
shell_config

# Test the cluster
echo "Test your cluster with:"
echo "export KUBECONFIG=/home/$CURRENT_USER/.kube/config"
export KUBECONFIG=/home/$CURRENT_USER/.kube/config
echo "kubectl config use-context k3s-ha"
kubectl config use-context k3s-ha
echo "kubectl get node -o wide"
kubectl get node -o wide

# Step 2: Install Kube-VIP for HA
# https://kube-vip.io/manifests/rbac.yaml
kubectl apply --validate=false --insecure-skip-tls-verify -f https://raw.githubusercontent.com/ryanwclark1/homelab/main/kubernetes/kube-vip/rbac.yaml

# Step 3: Download kube-vip
curl -sO https://raw.githubusercontent.com/ryanwclark1/homelab/main/kubernetes/k3s-deploy/kube-vip
cat kube-vip | sed 's/$interface/'$interface'/g; s/$vip/'$vip'/g' > $HOME/kube-vip.yaml

# Step 4: Copy kube-vip.yaml to master1
scp -i ~/.ssh/$certName $HOME/kube-vip.yaml $user@$master1:kube-vip.yaml


# Step 5: Connect to Master1 and move kube-vip.yaml
ssh -i ~/.ssh/$certName $user@$master1 sudo su <<- EOF
  mkdir -p /var/lib/rancher/k3s/server/manifests
  mv kube-vip.yaml /var/lib/rancher/k3s/server/manifests/kube-vip.yaml
EOF

# Step 6: Add new master nodes (servers) & workers
for newnode in "${masters[@]}"; do
  k3sup join \
  --ip $newnode \
  --user $user \
  --sudo \
  --k3s-version $k3sVersion \
  --server \
  --server-ip $master1 \
  --ssh-key $HOME/.ssh/$certName \
  --k3s-extra-args " \
    --disable traefik \
    --disable servicelb \
    --flannel-iface=$interface \
    --node-ip=$newnode \
    --node-taint node-role.kubernetes.io/master=true:NoSchedule" \
  --server-user $user
  echo -e " \033[32;5mMaster node joined successfully!\033[0m"
done

# add workers
for newagent in "${workers[@]}"; do
  k3sup join \
  --ip $newagent \
  --user $user \
  --sudo \
  --k3s-version $k3sVersion \
  --server-ip $master1 \
  --ssh-key $HOME/.ssh/$certName \
  --k3s-extra-args " \
    --node-label "worker=true""
  echo -e " \033[32;5mAgent node joined successfully!\033[0m"
done

# add storage nodes
for newstorage in "${storage[@]}"; do
  k3sup join \
  --ip $newstorage \
  --user $user \
  --sudo \
  --k3s-version $k3sVersion \
  --server-ip $master1 \
  --ssh-key $HOME/.ssh/$certName \
  --k3s-extra-args " \
    --node-label "longhorn=true""
  echo -e " \033[32;5mStorage node joined successfully!\033[0m"
done

# Install helm
if ! command -v helm version &> /dev/null
then
  echo -e " \033[31;5mHelm not found, installing\033[0m"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo -e " \033[32;5mHelm already installed\033[0m"
fi

# Step 7: Install kube-vip as network LoadBalancer - Install the kube-vip Cloud Provider
kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml

# Step 8: Install Metallb
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
# Download ipAddressPool and configure using lbrange above
curl -sO https://raw.githubusercontent.com/ryanwclark1/homelab/main/kubernetes/k3s-deploy/ipAddressPool
cat ipAddressPool | sed 's/$lbrange/'$lbrange'/g' > $HOME/ipAddressPool.yaml
kubectl apply -f $HOME/ipAddressPool.yaml

# Step 9: Test with Traefik
echo -e " \033[32;5mInstalling Traefik\033[0m"
source ../traefik/deploy.sh
echo -e " \033[32;5mWaiting for K3S to sync and LoadBalancer to come online\033[0m"

# Step 10: Deploy IP Pools and l2Advertisement
echo -e " \033[32;5mDeploying IP Pools and l2Advertisement\033[0m"
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=component=controller \
  --timeout=120s
kubectl apply -f $HOME/ipAddressPool.yaml
kubectl apply -f https://raw.githubusercontent.com/ryanwclark1/homelab/main/kubernetes/k3s-deploy/l2Advertisement.yaml


# Step 13: Install Cert-Manager
source ../cert-manager/deploy.sh

source ../longhorn/deploy.sh

# Step 14: Install Rancher
source ../rancher/deploy.sh

kubectl get nodes
kubectl get svc
kubectl get pods --all-namespaces -o wide

echo -e " \033[32;5mHappy Kubing!\033[0m"