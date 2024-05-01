#!/bin/bash

# Install helm
if ! command -v helm version &> /dev/null
then
  echo -e " \033[31;5mHelm not found, installing\033[0m"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  echo -e " \033[31;5mHelm installed\033[0m"
else
  echo -e " \033[32;5mHelm already installed\033[0m"
fi
