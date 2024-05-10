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
      # TODO: Check if this works
      echo "export PATH=\$PATH:\$HOME/go/bin" >> ~/.bashrc
  fi
  go version
  source ~/.bashrc
  echo -e " \033[32;5mGo installation complete\033[0m"
else
  go version
  echo -e " \033[32;5mGo already installed\033[0m"
fi

if ! command -v cmctl version &> /dev/null; then
  cd ~
  OS=$(go env GOOS); ARCH=$(go env GOARCH); curl -fsSL -o cmctl https://github.com/cert-manager/cmctl/releases/latest/download/cmctl_${OS}_${ARCH}
  chmod +x cmctl
  sudo mv cmctl /usr/local/bin
  cmctl version
  echo -e " \033[32;5mcmctl installation complete\033[0m"
else
  cmctl version
  echo -e " \033[32;5mcmctl already installed\033[0m"
fi