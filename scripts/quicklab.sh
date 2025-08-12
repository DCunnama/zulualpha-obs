#!/usr/bin/env bash
set -euo pipefail

# Detect mode: lab or k3s
if kubectl get nodes &>/dev/null; then
    MODE="k3s"
else
    MODE="lab"
fi
echo "[*] Running in $MODE mode"

# Detect default interface if not set
PHY_IF=${PHY_IF:-$(ip route | awk '/default/ {print $5; exit}')}
echo "[*] Using physical interface: ${PHY_IF}"

# VLANs and addresses
declare -A VLAN_ADDR=(
  [10]="10.10.10.1/24"     # Mgmt
  [200]="10.10.200.1/24"   # Services
)

echo "[*] Creating VLAN subinterfaces on ${PHY_IF}"
for v in "${!VLAN_ADDR[@]}"; do
  ip link add link ${PHY_IF} name ${PHY_IF}.${v} type vlan id ${v} 2>/dev/null || true
  ip addr add ${VLAN_ADDR[$v]} dev ${PHY_IF}.${v} 2>/dev/null || true
  ip link set ${PHY_IF}.${v} up
done

echo "[*] Enabling IP forwarding"
sysctl -w net.ipv4.ip_forward=1 >/dev/null
sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null

if [ "$MODE" = "lab" ]; then
  echo "[*] Installing dnsmasq configs for lab DHCP"
  mkdir -p /etc/dnsmasq.d
  cp configs/dnsmasq/*.conf /etc/dnsmasq.d/ 2>/dev/null || true
  systemctl enable --now dnsmasq || true
fi

echo "[*] Configuring nftables rules"
if [ "$MODE" = "lab" ]; then
  # Lab can own /etc/nftables.conf safely
  cp configs/nftables/ruleset.nft /etc/nftables.conf
  systemctl enable --now nftables || true
else
  # k3s mode: create our own table/chain/set without touching k3s iptables-nft
  nft add table inet zobs 2>/dev/null || true
  # set for tenant VLAN interfaces
  nft list set inet zobs tenant_vlans >/dev/null 2>&1 || \
    nft add set inet zobs tenant_vlans '{ type ifname; flags interval; }'
  # forward chain with low priority (executes after kube rules)
  nft list chain inet zobs forward >/dev/null 2>&1 || \
    nft add chain inet zobs forward '{ type filter hook forward priority 100; policy accept; }'
  # east-west isolation rule (idempotent)
  nft list chain inet zobs forward | grep -q 'iifname @tenant_vlans oifname @tenant_vlans drop' || \
    nft add rule inet zobs forward iifname @tenant_vlans oifname @tenant_vlans drop
  echo "[*] k3s mode: nftables zobs table/chain/set ensured"
fi

echo "[*] Bringing up WireGuard (mgmt) if present"
mkdir -p /etc/wireguard
if [[ -f configs/wireguard/wg-mgmt.conf ]]; then
  cp configs/wireguard/wg-mgmt.conf /etc/wireguard/wg-mgmt.conf
  wg-quick down wg-mgmt 2>/dev/null || true
  wg-quick up wg-mgmt
else
  echo "[-] Missing configs/wireguard/wg-mgmt.conf (ok if not generated yet)"
fi

echo "[+] quicklab.sh complete."
