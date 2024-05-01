#!/bin/bash

GOVERSION="1.22.2"

# Stop execution on any error
set -e

# Update package list and install build essentials
sudo apt-get update
sudo apt-get install -y build-essential

if ! command -v go version &> /dev/null; then
  cd ~
  curl -OL https://go.dev/dl/go${GOVERSION}.linux-amd64.tar.gz
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf go${GOVERSION}.linux-amd64.tar.gz
  export PATH=$PATH:/usr/local/go/bin
  if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
      echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
  fi
  go version
  source ~/.bashrc
  echo -e " \033[32;5mGo installation complete\033[0m"
else
  go version
  echo -e " \033[32;5mGo already installed\033[0m"
fi

# Check if k9s repo is already cloned
if [ -d "~/k9s" ]; then
    # Repo exists, so pull any new changes
    cd ~/k9s
    git pull
else
    # Repo does not exist, clone it
    git clone https://github.com/derailed/k9s.git
    cd ~/k9s
fi

# Build k9s and run it
cd ~/k9s
make build
sudo cp ./execs/k9s /usr/local/bin
