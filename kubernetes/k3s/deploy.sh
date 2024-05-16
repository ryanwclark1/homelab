#!/bin/bash

#############################################
# YOU SHOULD ONLY NEED TO EDIT THIS SECTION #
#############################################


# Define the path to your inventory JSON file
inventory='../../inventory.json'

if [ ! -f "$inventory" ]; then
    echo "Inventory file not found at $inventory"
    exit 1
fi

k3s_version=$(jq -r '.k3s_version' "$inventory")
master1_name=$(jq -r '.master1_name' "$inventory")
master1=$(jq -r --arg vm_name "$master1_name" '.nodes[].vms[] | select(.name == $vm_name) | .ip' "$inventory")
lbrange=$(jq -r '.lbrange' "$inventory")
host_user=$(jq -r '.host_user' "$inventory")
interface=$(jq -r '.interface' "$inventory")
vip=$(jq -r '.vip' "$inventory")
cert_name=$(jq -r '.cert_name' "$inventory")

mapfile -t masters < <(jq -r --arg ip "$master1" '.nodes[].vms[] | select(.role == "master" and .ip != $ip) | .ip' "$inventory") # Arrays of masters ex master1
mapfile -t workers < <(jq -r '.nodes[].vms[] | select(.role != "master") | .ip' "$inventory") # Array of worker nodes
mapfile -t storage < <(jq -r '.nodes[].vms[] | select(.role == "storage") | .ip' "$inventory") # Array of storage nodes
mapfile -t all < <(jq -r '.nodes[].vms[].ip' "$inventory") # Array of all

SSH_KEY="$HOME/.ssh/$cert_name"
SHELL_NAME=$(basename "$SHELL")
CURRENT_USER=$(whoami)

#############################################
#            DO NOT EDIT BELOW              #
#############################################

initialize_nodes() {
  # Add ssh keys for all nodes
  for node in "${all[@]}"; do
    ssh-keyscan -H $node >> ~/.ssh/known_hosts
    ssh-copy-id $host_user@$node
    ssh $host_user@$node -i ~/.ssh/$cert_name sudo su <<EOF
    NEEDRESTART_MODE=a
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -q
    apt-get install -yq policycoreutils open-iscsi nfs-common cryptsetup dmsetup jq
    exit
EOF

    # Check if the current node is in the storage array
    if [[ " ${storage[*]} " == *" $node "* ]]; then
        unset storage_disk_size
        storage_disk_size=$(jq -r --arg ip "$node" '.nodes[].vms[] | select(.ip == $ip) | .storage_disk_size' "$inventory")
        echo "Storage disk size: $storage_disk_size"

        ssh $host_user@$node -i ~/.ssh/$cert_name "storage_disk_size=$storage_disk_size sudo su <<'EOF'
          # Find the disk that matches the storage_disk_size
          BLK_ID=\$(lsblk --json | jq -r --arg size \"\$storage_disk_size\" '.blockdevices[] | select(.size == \$size and .type == \"disk\") | .name')
          BLK_ID=\"/dev/\$BLK_ID\"
          if [ -n \"\$BLK_ID\" ]; then
            MOUNT_POINT=/var/lib/longhorn
            echo 'label: gpt' | sudo sfdisk \$BLK_ID
            echo ',,L' | sudo sfdisk \$BLK_ID
            sudo mkfs.ext4 -F \${BLK_ID}1
            PART_UUID=\$(sudo blkid | grep \$BLK_ID | rev | cut -d ' ' -f -1 | tr -d '\"' | rev)
            if [ -n \"\$PART_UUID\" ]; then
              echo \$PART_UUID
              sudo mkdir -p \$MOUNT_POINT
              echo \"\$PART_UUID \$MOUNT_POINT ext4 defaults 0 2\" | sudo tee -a /etc/fstab
              # sudo systemctl daemon-reload
              # sudo reboot
            else
              echo 'PART_UUID is null, not updating /etc/fstab'
            fi
          else
            echo 'BLK_ID is null, not proceeding with disk setup'
          fi
EOF"
    fi
    echo -e " \033[32;5mNode: $node Initialized!\033[0m"
  done

  echo -e " \033[32;5mAll nodes initialized!\033[0m"
}



ask_to_initialize() {
  while true; do
      # Prompt the user. The colon after the question suggests a default value of 'yes'
      echo -n "Do you want to run intialize the environment? [Y/n]: "
      read -r user_input
      if [[ -z "$user_input" ]]; then
        user_input="yes"
      fi

      # Convert to lowercase to simplify the comparison
      user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

      case "$user_input" in
        y|yes)
          initialize_nodes
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

test_cluster() {
  echo "Test your cluster with:"
  echo "export KUBECONFIG=$HOME/.kube/config"
  export KUBECONFIG=$HOME/.kube/config
  echo "kubectl config use-context k3s-ha"
  kubectl config use-context k3s-ha
  echo "kubectl get node -o wide"
  kubectl get node -o wide
}

# Check if the export statement already exists
check_export_statement() {
    grep -qF "export KUBECONFIG=/home/$CURRENT_USER/.kube/config" "$1"
}

# Append the export statement to the appropriate shell configuration file
append_export_statement() {
    echo "export KUBECONFIG=/home/$CURRENT_USER/.kube/config" >> "$1"
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

chmod 600 $HOME/.ssh/$cert_name
chmod 644 $HOME/.ssh/$cert_name.pub

ask_to_initialize

echo -e " \033[32;5m**********************************************\033[0m"
echo -e " \033[32;5m***         Installing K3sup            ******\033[0m"
echo -e " \033[32;5m**********************************************\033[0m"
source ../k3sup/deploy.sh

echo -e " \033[32;5m**********************************************\033[0m"
echo -e " \033[32;5m***        Installing Kubectl           ******\033[0m"
echo -e " \033[32;5m**********************************************\033[0m"
source ../kubectl/deploy.sh

# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
# Add kubectl & alias to completions to bashrc

# # Check if the shell is Bash
# if [ "$SHELL_NAME" = "bash" ]; then
#   # Check if autocompletions are enabled
#   if type _init_completion &>/dev/null; then
#     echo "Autocompletions are enabled."
#     # Check if kubectl completions are already added to bashrc
#     if ! grep -q 'source <(kubectl completion bash)' ~/.bashrc; then
#       echo "Adding kubectl completions to ~/.bashrc"
#       echo 'source <(kubectl completion bash)' >> ~/.bashrc
#       source ~/.bashrc
#     if ! grep -q 'alias k=kubectl' ~/.bashrc; then
#       echo "Adding kubectl alias to ~/.bashrc"
#       echo 'alias k=kubectl' >> ~/.bashrc
#       echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
#       source ~/.bashrc
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

# Step 1: Bootstrap First k3s Node
mkdir ~/.kube
# Multiline echo with banner for better readability
echo -e " \033[32;5m**********************************************\033[0m"
echo -e " \033[32;5m***    Bootstrapping first node...      ******\033[0m"
echo -e " \033[32;5m**********************************************\033[0m"
k3sup install \
  --cluster \
  --ip $master1 \
  --user $host_user \
  --tls-san $vip \
  --k3s-version $k3s_version \
  --k3s-extra-args " \
    --disable traefik \
    --disable servicelb \
    --disable metrics-server \
    --flannel-iface=$interface \
    --node-name=$master1_name \
    --node-label master=true \
    --etcd-expose-metrics=true \
    --kube-controller-manager-arg bind-address=0.0.0.0 \
    --kube-proxy-arg bind-address=0.0.0.0 \
    --kube-scheduler-arg bind-address=0.0.0.0 \
    --node-taint node-role.kubernetes.io/control-plane:NoSchedule" \
  --merge \
  --sudo \
  --local-path $HOME/.kube/config \
  --ssh-key $HOME/.ssh/$cert_name \
  --context k3s-ha \
  --print-config

echo -e " \033[32;5mFirst Node bootstrapped successfully!\033[0m"

shell_config

test_cluster

# Install Kube-VIP for HA https://kube-vip.io/manifests/rbac.yaml
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml
curl -sO https://raw.githubusercontent.com/ryanwclark1/homelab/main/kubernetes/k3s/kube-vip
cat kube-vip | sed 's/$interface/'$interface'/g; s/$vip/'$vip'/g' > $HOME/kube-vip.yaml

# Copy kube-vip.yaml to master1 and move it to the correct location
scp -i ~/.ssh/$cert_name $HOME/kube-vip.yaml $host_user@$master1:kube-vip.yaml

ssh -i ~/.ssh/$cert_name $host_user@$master1 sudo su <<- EOF
  mkdir -p /var/lib/rancher/k3s/server/manifests
  mv kube-vip.yaml /var/lib/rancher/k3s/server/manifests/kube-vip.yaml
EOF

# Add new master nodes (servers) & workers
for newmaster in "${masters[@]}"; do
  newmaster_name=$(jq -r --arg ip "$newmaster" '.nodes[].vms[] | select(.ip == $ip) | .name' "$inventory")
  k3sup join \
  --ip $newmaster \
  --user $host_user \
  --sudo \
  --k3s-version $k3s_version \
  --server \
  --server-ip $master1 \
  --ssh-key $HOME/.ssh/$cert_name \
  --k3s-extra-args " \
    --disable traefik \
    --disable servicelb \
    --flannel-iface=$interface \
    --node-ip=$newmaster \
    --node-name=$newmaster_name \
    --node-label master=true \
    --etcd-expose-metrics=true \
    --kube-controller-manager-arg bind-address=0.0.0.0 \
    --kube-proxy-arg bind-address=0.0.0.0 \
    --kube-scheduler-arg bind-address=0.0.0.0 \
    --node-taint node-role.kubernetes.io/control-plane:NoSchedule" \
  --server-user $host_user
  echo -e " \033[32;5mMaster node joined successfully!\033[0m"
done
echo -e " \033[32;5mAll master nodes joined successfully!\033[0m"

# add workers
for newworker in "${workers[@]}"; do
  newworker_name=$(jq -r --arg ip "$newworker" '.nodes[].vms[] | select(.ip == $ip) | .name' "$inventory")
  k3sup join \
  --ip $newworker \
  --user $host_user \
  --sudo \
  --k3s-version $k3s_version \
  --server-ip $master1 \
  --ssh-key $HOME/.ssh/$cert_name \
  --k3s-extra-args " \
    --node-ip=$newworker \
    --node-name=$newworker_name \
    --node-label worker=true"
  echo -e " \033[32;5mAgent node joined successfully!\033[0m"
done
echo -e " \033[32;5mAll worker nodes joined successfully!\033[0m"

# add storage nodes
for newstorage in "${storage[@]}"; do
  newstorage_name=$(jq -r --arg ip "$newstorage" '.nodes[].vms[] | select(.ip == $ip) | .name' "$inventory")
  k3sup join \
  --ip $newstorage \
  --user $host_user \
  --sudo \
  --k3s-version $k3s_version \
  --server-ip $master1 \
  --ssh-key $HOME/.ssh/$cert_name \
  --k3s-extra-args " \
    --node-ip=$newstorage \
    --node-name=$newstorage_name \
    --node-label longhorn=true \
    --node-label node.longhorn.io/create-default-disk=true"
  echo -e " \033[32;5mStorage node joined successfully!\033[0m"
done
echo -e " \033[32;5mAll storage nodes joined successfully!\033[0m"

# Install Helm
source ../helm/deploy.sh

# Install kube-vip as network LoadBalancer - Install the kube-vip Cloud Provider
kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml

# Install Metallb
source ../metallb/deploy.sh

# Install Traefik
# source ../traefik/deploy.sh

# source ../cert-manager/deploy.sh

# source ../monitoring/deploy.sh

# source ../longhorn/deploy.sh

# source ../rancher/deploy.sh

kubectl get nodes
kubectl get svc
kubectl get pods --all-namespaces -o wide

echo -e " \033[32;5mHappy Kubing!\033[0m"