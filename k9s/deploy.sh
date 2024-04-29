#!/bin/bash

sudo apt install -y build-essentials
cd ~
curl -OL https://go.dev/dl/go1.22.2.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.2.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc
go version
cd ~
git clone https://github.com/derailed/k9s.git
cd k9s
make build && ./execs/k9s