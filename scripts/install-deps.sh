#!/usr/bin/env bash
set -euo pipefail

# Install base packages required for the ZuluAlpha observatory lab
sudo apt update
sudo apt install -y \
  wireguard \
  nftables \
  dnsmasq \
  bridge-utils \
  docker.io \
  docker-compose-plugin \
  ansible

echo "[+] Packages installed. Review configs and run tests with: bash tests/config-sanity.sh"
