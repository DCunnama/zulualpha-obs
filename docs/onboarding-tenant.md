# Tenant Onboarding

1. Receive tenant ID (e.g., `A`) and assigned VLAN (e.g., `101`).
2. Run:
   ```bash
   sudo bash scripts/mk-tenant.sh A 101
   ```
3. Provide the generated WireGuard client file to the tenant (found in `configs/wireguard/peers/tenantA.conf`).
4. Give RDP/CRD credentials for their pier PC in VLAN101.
5. Confirm monitoring checks are green in Uptime Kuma/Grafana.
