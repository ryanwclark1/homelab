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
else
  echo -e " \033[32;5mGo already installed\033[0m"
fi

OS=$(go env GOOS); ARCH=$(go env GOARCH); curl -fsSL -o cmctl https://github.com/cert-manager/cmctl/releases/latest/download/cmctl_${OS}_${ARCH}
chmod +x cmctl
sudo mv cmctl /usr/local/bin