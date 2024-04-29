#!/bin/bash

if ! command -v kubectl version &> /dev/null
then
  echo -e " \033[31;5mKubectl not found, installing\033[0m"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
  echo "$(<kubectl.sha256) kubectl" | sha256sum --check || {
    echo -e "\033[31;5mChecksum verification  for kubectl. Installation aborted.\033[0m"
    exit 1
  }
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  kubectl version --client --output=yaml
  echo -e "\033[32;5mKubectl installed successfully!\033[0m"
else
  echo -e " \033[32;5mKubectl already installed\033[0m"
fi