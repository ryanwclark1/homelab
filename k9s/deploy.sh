#!/bin/bash

# Stop execution on any error
set -e

# Update package list and install build essentials
sudo apt-get update
sudo apt-get install -y build-essential

# Go to the user's home directory
cd ~

# Download Go binary
curl -OL https://go.dev/dl/go1.22.2.linux-amd64.tar.gz

# Remove any existing Go installation and extract the new version
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz

# Add Go to PATH for all future terminal sessions
export PATH=$PATH:/usr/local/go/bin

# Check if Go PATH is already in .bashrc and add it if not
if ! grep -q '/usr/local/go/bin' ~/.bashrc; then
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
fi

# Load the new PATH into the current shell session
source ~/.bashrc

# Verify Go installation
go version

# Check if k9s repo is already cloned
if [ -d "~/k9s" ]; then
    # Repo exists, so pull any new changes
    cd k9s
    git pull
else
    # Repo does not exist, clone it
    git clone https://github.com/derailed/k9s.git
    cd k9s
fi


# Build k9s and run it
make build
sudo cp ./execs/k9s /usr/local/bin
