# Architecture

- **Private LAN with per-tenant VLANs** for piers; east-west blocked.
- **Mgmt VLAN** for roof controller, weather, PDUs, CCTV.
- **Services VLAN** for Grafana, Prometheus, Uptime Kuma, syslog, NTP.
- **WireGuard** for remote access (staff and tenants).
- **Out-of-band LTE** path for emergency control of roof/PDUs.

See `diagrams/zulualpha-network.drawio` for a visual layout.
