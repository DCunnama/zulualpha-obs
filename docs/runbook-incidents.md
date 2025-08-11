# Incident Runbook

## Weather alarm (rain/wind/cloud)
- Roof controller closes automatically.
- Verify mount parked; if not, trigger park via Mgmt channel.
- Notify affected tenants.

## Power loss
- UPS keeps roof/PCs alive long enough to park/close.
- When power returns, verify auto-boot and reopen window as appropriate.

## VPN outage
- Use OOB LTE to reach roof/PDUs.
- Check upstream ISP; failover if possible.

## Compromised tenant PC
- Disable their VPN peer.
- Isolate VLAN at firewall.
- Reimage from gold Windows image.
