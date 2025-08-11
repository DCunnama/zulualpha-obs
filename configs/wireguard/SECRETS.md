# WireGuard Secrets

Generate server keys:
```bash
umask 077
wg genkey | tee server-privatekey | wg pubkey > server-publickey
```

Generate a tenant peer:
```bash
wg genkey | tee tenantA-privatekey | wg pubkey > tenantA-publickey
```

Fill the placeholders in `configs/wireguard/wg-mgmt.conf` and `configs/wireguard/wg-tenantA.conf`.
