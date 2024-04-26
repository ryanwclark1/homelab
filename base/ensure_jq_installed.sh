#!/bin/bash

ensure_jq_installed() {
  if ! command -v jq &> /dev/null; then
    log_action "jq is not installed. Attempting to install..."
    case $(uname -s) in
      Linux)
        distro=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"')
        case $distro in
          debian|ubuntu) sudo apt-get update && sudo apt-get install -y jq ;;
          centos|fedora|rocky) sudo yum install -y jq ;;
          alpine) sudo apk add jq ;;
          arch) sudo pacman -Sy jq ;;
          *) log_action "Unsupported distribution: $distro" && exit 1 ;;
        esac
        ;;
      *)
        log_action "Unsupported OS" && exit 1 ;;
    esac
  fi
  log_action "jq is installed."
}

ensure_jq_installed