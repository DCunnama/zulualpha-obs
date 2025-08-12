# ZuluAlpha Observatory Platform (Lab)

An end-to-end, *lab-ready* reference for ZuluAlpha’s remote observatory network, security, and automation.
Built to run on a single Linux laptop first, then lifted into production hardware with the same subnets, ACLs, and playbooks.

> Status: Lab scaffolding complete. Replace placeholders marked `<<<FILL>>>` before use.

## Contents
- **docs/**: Architecture, onboarding, security baseline, incident runbook.
- **diagrams/**: Network diagrams (Draw.io) + ASCII.
- **infra/**: Ansible playbooks/roles and Docker services.
- **configs/**: Opinionated defaults for WireGuard, dnsmasq, nftables.
- **scripts/**: Helper scripts to spin up the lab, add tenants, and manage config.
- **.gitignore**: Sensible defaults for Linux/Ansible/Docker/WireGuard.

## Quick start (lab on a single Linux host)
1. Install dependencies:
   ```bash
   sudo bash scripts/install-deps.sh
   ```
2. Run basic config sanity tests:
   ```bash
   bash tests/config-sanity.sh
   ```
3. Review and fill secrets in `configs/wireguard/SECRETS.md`.
4. Bring up VLANs/DHCP/VPN/ACLs:
   ```bash
   sudo bash scripts/quicklab.sh
   ```
5. Start monitoring stack:
   ```bash
   docker compose -f infra/docker/compose.services.yml up -d
   ```
6. Add a tenant:
   ```bash
   sudo bash scripts/mk-tenant.sh A 101
   ```

## Network sketch
```
                           Internet
                               │
                      [Edge FW/Router]
                 (WireGuard server, NAT, ACLs)
                     /                       OOB LTE (Mgmt)       Primary WAN
                 │
        ┌───────────────────────────────────────┐
        │        L3 Switch (VLAN trunk)         │
        └───────────────────────────────────────┘
             │        │         │         │
             │        │         │         │
        VLAN10    VLAN101   VLAN102   VLAN200
        Mgmt      Pier A    Pier B    Services
   10.10.10.0/24 10.10.101.0 10.10.102.0 10.10.200.0
        │            │          │          │
  ┌────────────┐  ┌────────┐  ┌────────┐  ┌─────────────────────────┐
  │ Roof ctrl  │  │ A PC   │  │ B PC   │  │ NAS / Monitoring / NTP  │
  │ Wx sensor  │  │ PDU    │  │ PDU    │  │ (Grafana/Prom/Uptime)   │
  │ IP cams    │  │ Mount  │  │ Mount  │  └─────────────────────────┘
  └────────────┘  └────────┘  └────────┘
        ▲             ▲          ▲
        │             │          │
   Staff VPN    Tenant A VPN  Tenant B VPN
 (Mgmt/Services)  (VLAN101)     (VLAN102)
```

## Production migration notes
- Move VLAN gateways to your firewall/router. Import the same subnets and ACLs.
- Terminate WireGuard on your firewall or a dedicated VPN appliance.
- Keep per-tenant isolation (one VLAN each) and deny east-west by default.
- Keep Services (Grafana/Prometheus/Uptime/NAS) on a separate VLAN.
- Use the Ansible inventory to switch from `lab` to `prod` targets without changing roles.

## License
MIT (see LICENSE)
