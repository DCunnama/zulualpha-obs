#!/usr/bin/env bash
set -euo pipefail

TENANT_ID=${1:-A}
VLAN=${2:-101}
PHY_IF=${PHY_IF:-$(ip route | awk '/default/ {print $5; exit}')}
TENANT_NAME="tenant${TENANT_ID}"

# Detect mode
if kubectl get nodes &>/dev/null; then
    MODE="k3s"
else
    MODE="lab"
fi
echo "[*] Adding tenant ${TENANT_ID} on VLAN ${VLAN} (${MODE} mode) via ${PHY_IF}"

# VLAN setup
GW_IP="10.10.${VLAN}.1/24"
ip link add link ${PHY_IF} name ${PHY_IF}.${VLAN} type vlan id ${VLAN} 2>/dev/null || true
ip addr add ${GW_IP} dev ${PHY_IF}.${VLAN} 2>/dev/null || true
ip link set ${PHY_IF}.${VLAN} up

if [ "$MODE" = "lab" ]; then
  # DHCP scope for lab mode
  CONF_FILE="/etc/dnsmasq.d/vlan${VLAN}.conf"
  cat > ${CONF_FILE} <<EOF
interface=${PHY_IF}.${VLAN}
dhcp-range=10.10.${VLAN}.50,10.10.${VLAN}.200,12h
EOF
  systemctl restart dnsmasq || true
fi

# Ensure nftables zobs table and set exist; add this VLAN iface to set
nft add table inet zobs 2>/dev/null || true
nft list set inet zobs tenant_vlans >/dev/null 2>&1 || \
  nft add set inet zobs tenant_vlans '{ type ifname; flags interval; }'
nft add element inet zobs tenant_vlans { ${PHY_IF}.${VLAN} } 2>/dev/null || true
nft list chain inet zobs forward >/dev/null 2>&1 || \
  nft add chain inet zobs forward '{ type filter hook forward priority 100; policy accept; }'
nft list chain inet zobs forward | grep -q 'iifname @tenant_vlans oifname @tenant_vlans drop' || \
  nft add rule inet zobs forward iifname @tenant_vlans oifname @tenant_vlans drop

# WireGuard keys & server/client config
mkdir -p configs/wireguard/peers
umask 077
WG_DIR="configs/wireguard/peers/${TENANT_NAME}"
mkdir -p "${WG_DIR}"
wg genkey | tee "${WG_DIR}/server-privatekey" | wg pubkey > "${WG_DIR}/server-publickey"
wg genkey | tee "${WG_DIR}/${TENANT_NAME}-privatekey" | wg pubkey > "${WG_DIR}/${TENANT_NAME}-publickey"

SERVER_PRIV=$(cat "${WG_DIR}/server-privatekey")
PEER_PUB=$(cat "${WG_DIR}/${TENANT_NAME}-publickey")
WG_NAME="wg-${TENANT_NAME}"
WG_ADDR="10.255.${VLAN}.1/24"
PEER_ADDR="10.255.${VLAN}.10/32"
WG_PORT=$((51820 + VLAN))

# Server config
WG_SVR_CONF="/etc/wireguard/${WG_NAME}.conf"
cat > ${WG_SVR_CONF} <<EOF
[Interface]
Address = ${WG_ADDR}
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIV}

[Peer]
PublicKey = ${PEER_PUB}
AllowedIPs = ${PEER_ADDR}
EOF

wg-quick down ${WG_NAME} 2>/dev/null || true
wg-quick up ${WG_NAME}

# Client config
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

echo "[+] Tenant ${TENANT_ID} ready."
echo "    - VLAN iface: ${PHY_IF}.${VLAN} (gateway ${GW_IP}) added to nft set inet zobs tenant_vlans"
echo "    - WG: ${WG_NAME} on UDP ${WG_PORT}"
echo "    - Client: configs/wireguard/peers/${TENANT_NAME}.conf"
