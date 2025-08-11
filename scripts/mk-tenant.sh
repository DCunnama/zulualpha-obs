#!/usr/bin/env bash
set -euo pipefail

TENANT_ID=${1:-A}
VLAN=${2:-101}
PHY_IF=${PHY_IF:-eth0}

TENANT_NAME="tenant${TENANT_ID}"
SUBNET="10.10.${VLAN}.0/24"
GW_IP="10.10.${VLAN}.1/24"
WG_NAME="wg-tenant${TENANT_ID}"
WG_PORT=$((51820 + 1 + (RANDOM % 100)))  # pick a port > 51820

echo "[*] Creating VLAN ${VLAN} on ${PHY_IF}"
sudo ip link add link ${PHY_IF} name ${PHY_IF}.${VLAN} type vlan id ${VLAN} 2>/dev/null || true
sudo ip addr add ${GW_IP} dev ${PHY_IF}.${VLAN} 2>/dev/null || true
sudo ip link set ${PHY_IF}.${VLAN} up

echo "[*] Adding dnsmasq scope for VLAN${VLAN}"
CONF_FILE="/etc/dnsmasq.d/vlan${VLAN}.conf"
sudo bash -c "cat > ${CONF_FILE}" <<EOF
interface=${PHY_IF}.${VLAN}
dhcp-range=10.10.${VLAN}.50,10.10.${VLAN}.200,12h
EOF
sudo systemctl restart dnsmasq

echo "[*] Generating WireGuard server keys for ${WG_NAME}"
mkdir -p configs/wireguard/peers
umask 077
WG_DIR="configs/wireguard/peers/${WG_NAME}"
mkdir -p "${WG_DIR}"
wg genkey | tee "${WG_DIR}/server-privatekey" | wg pubkey > "${WG_DIR}/server-publickey"
wg genkey | tee "${WG_DIR}/${TENANT_NAME}-privatekey" | wg pubkey > "${WG_DIR}/${TENANT_NAME}-publickey"

SERVER_PRIV=$(cat "${WG_DIR}/server-privatekey")
PEER_PUB=$(cat "${WG_DIR}/${TENANT_NAME}-publickey")

WG_SVR_CONF="/etc/wireguard/${WG_NAME}.conf"
WG_ADDR="10.255.${VLAN}.1/24"
PEER_ADDR="10.255.${VLAN}.10/32"

echo "[*] Writing WireGuard server config ${WG_SVR_CONF}"
sudo bash -c "cat > ${WG_SVR_CONF}" <<EOF
[Interface]
Address = ${WG_ADDR}
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIV}

[Peer]
# ${TENANT_NAME}
PublicKey = ${PEER_PUB}
AllowedIPs = ${PEER_ADDR}
EOF

echo "[*] Bringing up ${WG_NAME}"
sudo wg-quick down ${WG_NAME} 2>/dev/null || true
sudo wg-quick up ${WG_NAME}

echo "[*] Writing tenant client file configs/wireguard/peers/${TENANT_NAME}.conf"
SVR_PUB=$(cat "${WG_DIR}/server-publickey")
PEER_PRIV=$(cat "${WG_DIR}/${TENANT_NAME}-privatekey")
SVR_ENDPOINT="<<<PUBLIC_IP>>>:${WG_PORT}"

cat > "configs/wireguard/peers/${TENANT_NAME}.conf" <<EOF
[Interface]
PrivateKey = ${PEER_PRIV}
Address = ${PEER_ADDR}
DNS = 10.10.200.1

[Peer]
PublicKey = ${SVR_PUB}
AllowedIPs = 10.10.${VLAN}.0/24,10.10.200.0/24
Endpoint = ${SVR_ENDPOINT}
PersistentKeepalive = 25
EOF

echo "[*] Updating nftables ACLs (deny east-west, allow tenant -> Services)"
sudo nft add element inet filter tenant_vlans { "${PHY_IF}.${VLAN}" } 2>/dev/null || true
sudo systemctl reload nftables || sudo systemctl restart nftables

echo "[+] Tenant ${TENANT_ID} ready."
echo "    - VLAN: ${VLAN} (${PHY_IF}.${VLAN}, gateway ${GW_IP})"
echo "    - WireGuard server: ${WG_NAME} on UDP ${WG_PORT}"
echo "    - Client file: configs/wireguard/peers/${TENANT_NAME}.conf"
echo ">>> Remember to set your public IP in the Endpoint field."
