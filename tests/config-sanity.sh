#!/usr/bin/env bash
set -euo pipefail

# Basic checks to ensure lab configs enforce security baseline

fail=0

check() {
  desc=$1
  shift
  if "$@"; then
    echo "[PASS] $desc"
  else
    echo "[FAIL] $desc" >&2
    fail=1
  fi
}

check "nftables drops inbound by default" \
  grep -q 'counter drop' configs/nftables/ruleset.nft

check "nftables blocks east-west between tenant VLANs" \
  grep -q 'iifname @tenant_vlans oifname @tenant_vlans drop' configs/nftables/ruleset.nft

check "Mgmt and Services VLAN dnsmasq configs exist" \
  test -f configs/dnsmasq/mgmt.conf -a -f configs/dnsmasq/services.conf

check "WireGuard configs present" \
  test -f configs/wireguard/wg-mgmt.conf -a -f configs/wireguard/wg-tenantA.conf

if [ $fail -eq 0 ]; then
  echo "[+] Config sanity checks passed."
else
  echo "[!] One or more checks failed." >&2
fi

exit $fail
