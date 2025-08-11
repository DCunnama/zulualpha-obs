#!/usr/bin/env bash
set -euo pipefail

# VLANs and addresses
declare -A VLAN_ADDR=(
  [10]="10.10.10.1/24"
  [101]="10.10.101.1/24"
  [200]="10.10.200.1/24"
)

PHY_IF=${PHY_IF:-eth0}

echo "[*] Creating VLAN subinterfaces on ${PHY_IF}"
for v in 10 101 200; do
  sudo ip link add link ${PHY_IF} name ${PHY_IF}.${v} type vlan id ${v} || true
  sudo ip addr add ${VLAN_ADDR[$v]} dev ${PHY_IF}.${v} || true
  sudo ip link set ${PHY_IF}.${v} up
done

echo "[*] Enabling IP forwarding"
sudo sysctl -w net.ipv4.ip_forward=1 >/dev/null
sudo sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null

echo "[*] Installing dnsmasq configs"
sudo mkdir -p /etc/dnsmasq.d
sudo cp configs/dnsmasq/*.conf /etc/dnsmasq.d/
sudo systemctl enable --now dnsmasq

echo "[*] Installing nftables rules"
sudo cp configs/nftables/ruleset.nft /etc/nftables.conf
sudo systemctl enable --now nftables

echo "[*] Installing WireGuard configs"
sudo mkdir -p /etc/wireguard
for f in wg-mgmt.conf wg-tenantA.conf; do
  if [[ -f configs/wireguard/$f ]]; then
    sudo cp configs/wireguard/$f /etc/wireguard/$f
    sudo wg-quick down /etc/wireguard/$f 2>/dev/null || true
    sudo wg-quick up /etc/wireguard/$f
  else
    echo "[-] Missing configs/wireguard/$f (ok for first run)"
  fi
done

echo "[*] (Optional) NAT for outbound internet"
sudo nft list tables | grep -q '^table ip nat$' || sudo nft add table ip nat
sudo nft list chains ip nat | grep -q '^chain postrouting' || sudo nft add chain ip nat postrouting '{ type nat hook postrouting priority 100 ; }'
sudo nft list ruleset | grep -q 'masquerade' || sudo nft add rule ip nat postrouting oifname "${PHY_IF}" ip saddr 10.10.0.0/16 masquerade

echo "[*] Lab bring-up complete."
