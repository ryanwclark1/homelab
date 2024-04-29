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
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc

# Load the new PATH into the current shell session
source ~/.bashrc

# Verify Go installation
go version

# Clone the k9s repository and build it
git clone https://github.com/derailed/k9s.git
cd k9s

# Build k9s and run it
make build
./execs/k9s
