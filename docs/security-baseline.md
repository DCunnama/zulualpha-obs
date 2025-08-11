# Security Baseline

- No inbound port forwards from the internet.
- All remote access via WireGuard (or brokered remote desktop with MFA).
- Per-tenant VLANs; deny east-west.
- Mgmt VLAN restricted to staff VPN.
- BitLocker on Windows imaging PCs; auto-update staged; limited user rights.
- Central logs to Services; 30-day retention.
- Backup: per-tenant NAS shares; rsync nightly; off-site snapshot for 30 days.
