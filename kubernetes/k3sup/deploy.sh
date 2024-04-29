#!/bin/bash


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