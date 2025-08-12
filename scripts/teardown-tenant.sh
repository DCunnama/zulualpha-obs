#!/usr/bin/env bash
set -euo pipefail

TENANT_ID=${1:-A}
VLAN=${2:-101}
PHY_IF=${PHY_IF:-$(ip route | awk '/default/ {print $5; exit}')}
TENANT_NAME="tenant${TENANT_ID}"
WG_NAME="wg-${TENANT_NAME}"

echo "[*] Tearing down tenant ${TENANT_ID} (VLAN ${VLAN})"

# Stop WireGuard and remove server config
wg-quick down ${WG_NAME} 2>/dev/null || true
rm -f /etc/wireguard/${WG_NAME}.conf

# Remove vlan interface from nft set and delete iface
nft delete element inet zobs tenant_vlans { ${PHY_IF}.${VLAN} } 2>/dev/null || true
ip link delete ${PHY_IF}.${VLAN} 2>/dev/null || true

# Remove DHCP scope (lab mode only; safe to attempt)
rm -f /etc/dnsmasq.d/vlan${VLAN}.conf 2>/dev/null || true
systemctl restart dnsmasq 2>/dev/null || true

echo "[+] Teardown complete for tenant ${TENANT_ID}."
