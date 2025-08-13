#!/usr/bin/env bash
set -euo pipefail

WITH_K3S=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-k3s) WITH_K3S=1; shift ;;
    *) echo "Usage: $0 [--with-k3s]"; exit 1 ;;
  endac
done || true

cd "$(dirname "$0")/.."

PHY_IF=${PHY_IF:-$(ip route | awk '/default/ {print $5; exit}')}
echo "[*] Using physical interface: ${PHY_IF}"

if [[ $WITH_K3S -eq 1 ]]; then
  echo "[*] Starting k3s"
  sudo systemctl start k3s
fi

echo "[*] Bringing up base networking and mgmt WG"
sudo PHY_IF="$PHY_IF" bash scripts/quicklab.sh

TENANTS_FILE="configs/tenants.list"
if [[ -f "$TENANTS_FILE" ]]; then
  echo "[*] Bringing up tenants from $TENANTS_FILE"
  while read -r TID VLAN || [[ -n "$TID" ]]; do
    [[ -z "${TID:-}" || "${TID:0:1}" = "#" ]] && continue
    echo "   - Tenant $TID (VLAN $VLAN)"
    sudo PHY_IF="$PHY_IF" bash scripts/mk-tenant.sh "$TID" "$VLAN"
  done < "$TENANTS_FILE"
else
  echo "[!] No $TENANTS_FILE found; skipping tenants."
fi

echo "[+] Start complete."
