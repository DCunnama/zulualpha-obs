#!/usr/bin/env bash
set -euo pipefail

WITH_K3S=0
PURGE_NFT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-k3s) WITH_K3S=1; shift ;;
    --purge-nft) PURGE_NFT=1; shift ;;
    *) echo "Usage: $0 [--with-k3s] [--purge-nft]"; exit 1 ;;
  esac
done

cd "$(dirname "$0")/.."

PHY_IF=${PHY_IF:-$(ip route | awk '/default/ {print $5; exit}')}
echo "[*] Using physical interface: ${PHY_IF}"

TENANTS_FILE="configs/tenants.list"
if [[ -f "$TENANTS_FILE" ]]; then
  echo "[*] Tearing down tenants from $TENANTS_FILE"
  # read in reverse so highest VLANs go first (cosmetic)
  tac "$TENANTS_FILE" | while read -r TID VLAN || [[ -n "$TID" ]]; do
    [[ -z "${TID:-}" || "${TID:0:1}" = "#" ]] && continue
    echo "   - Tenant $TID (VLAN $VLAN)"
    sudo PHY_IF="$PHY_IF" bash scripts/teardown-tenant.sh "$TID" "$VLAN" || true
  done
else
  echo "[!] No $TENANTS_FILE found; skipping tenant teardown."
fi

echo "[*] Bringing down WireGuard mgmt (wg-mgmt)"
sudo wg-quick down wg-mgmt 2>/dev/null || true

echo "[*] Removing base VLAN interfaces (10 and 200)"
sudo ip link delete ${PHY_IF}.10 2>/dev/null || true
sudo ip link delete ${PHY_IF}.200 2>/dev/null || true

if [[ $PURGE_NFT -eq 1 ]]; then
  echo "[*] Deleting nftables table inet zobs"
  sudo nft delete table inet zobs 2>/dev/null || true
else
  echo "[*] Keeping nftables zobs table (use --purge-nft to delete)"
fi

if [[ $WITH_K3S -eq 1 ]]; then
  echo "[*] Stopping k3s"
  sudo systemctl stop k3s
fi

echo "[+] Stop complete."
