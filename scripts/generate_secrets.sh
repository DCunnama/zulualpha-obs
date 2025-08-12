#!/usr/bin/env bash
set -euo pipefail

OUT_DIR=${OUT_DIR:-configs/wireguard}
mkdir -p "${OUT_DIR}/peers"
umask 077

echo "[*] Generating server keys (Mgmt)"
wg genkey | tee "${OUT_DIR}/server-privatekey" | wg pubkey > "${OUT_DIR}/server-publickey"
echo "[*] Generating server keys (TenantA)"
wg genkey | tee "${OUT_DIR}/serverA-privatekey" | wg pubkey > "${OUT_DIR}/serverA-publickey"

echo "[*] Generating example Tenant A peer keys"
wg genkey | tee "${OUT_DIR}/peers/tenantA-privatekey" | wg pubkey > "${OUT_DIR}/peers/tenantA-publickey"

SVR_PRIV=$(cat "${OUT_DIR}/server-privatekey")
SVR_PRIV_A=$(cat "${OUT_DIR}/serverA-privatekey")

echo "[*] Patching placeholder keys into wg-mgmt.conf and wg-tenantA.conf (in-place)"
sed -i "s|<<<SERVER_PRIVATEKEY>>>|${SVR_PRIV}|g" configs/wireguard/wg-mgmt.conf || true
sed -i "s|<<<SERVER_PRIVATEKEY_TENANT_A>>>|${SVR_PRIV_A}|g" configs/wireguard/wg-tenantA.conf || true

echo "[*] Done."
echo "    - Server public (Mgmt): $(cat ${OUT_DIR}/server-publickey)"
echo "    - Server public (TenantA): $(cat ${OUT_DIR}/serverA-publickey)"
echo "    - TenantA public: $(cat ${OUT_DIR}/peers/tenantA-publickey)"
echo ""
echo "Next steps:"
echo "  1) Edit configs/wireguard/wg-tenantA.conf and add [Peer] with TenantA public key and AllowedIPs."
echo "  2) Set your public IP/port in Endpoint fields (scripts/mk-tenant.sh also outputs a ready client file)."
