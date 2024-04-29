#!/bin/bash


#############################################
# YOU SHOULD ONLY NEED TO EDIT THIS SECTION #
#############################################
# Set the IP addresses of master1
master1=10.10.101.21

# Set the IP addresses of your Longhorn nodes
longhorn1=10.10.101.26
longhorn2=10.10.101.27
longhorn3=10.10.101.28

# User of remote machines
user=ubuntu

# Interface used on remotes
interface=eth0

# Set the virtual IP address (VIP)
vip=10.10.101.50

# Array of longhorn nodes
storage=($longhorn1 $longhorn2 $longhorn3)

#ssh certificate name variable
certName=id_rsa

#############################################
#            DO NOT EDIT BELOW              #
#############################################
# For testing purposes - in case time is wrong due to VM snapshots
sudo timedatectl set-ntp off
sudo timedatectl set-ntp on

# add ssh keys for all nodes
for node in "${storage[@]}"; do
  ssh-copy-id $user@$node
done

# Check if the open-iscsi service is available
if ! systemctl is-active --quiet open-iscsi
then
    echo -e " \033[31;5mOpen-ISCSI not found, installing...\033[0m"
    # Update apt package list
    sudo apt-get update
    # Install open-iscsi
    sudo apt-get install -y open-iscsi
    # Optionally start the service and enable it to start at boot
    sudo systemctl start open-iscsi
    sudo systemctl enable open-iscsi
else
    echo -e " \033[32;5mOpen-ISCSI is already installed and active.\033[0m"
fi

# Step 1: Add new longhorn nodes to cluster (note: label added)
for newnode in "${storage[@]}"; do
  k3sup join \
    --ip $newnode \
    --user $user \
    --sudo \
    --k3s-channel stable \
    --server-ip $master1 \
    --k3s-extra-args "--node-label \"longhorn=true\"" \
    --ssh-key $HOME/.ssh/$certName
  echo -e " \033[32;5mAgent node joined successfully!\033[0m"
done

# Step 2: Install Longhorn (using modified Official to pin to Longhorn Nodes)
kubectl apply -f https://raw.githubusercontent.com/ryanwclark1/homelab/main/kubernetes/longhorn/longhorn.yaml
kubectl get pods \
--namespace longhorn-system \
--watch

# Step 3: Print out confirmation

kubectl get nodes
kubectl get svc -n longhorn-system

echo -e " \033[32;5mHappy Kubing! Access Longhorn through Rancher UI\033[0m"
