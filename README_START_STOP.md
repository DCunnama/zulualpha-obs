# Start/Stop shortcuts

## Start everything
```bash
# optional: export PHY_IF if auto-detection is wrong
# export PHY_IF=eth0
bash scripts/start-lab.sh --with-k3s
```
- Starts k3s (optional flag)
- Runs `quicklab.sh` (base VLANs, mgmt WG, nftables zobs)
- Creates tenants from `configs/tenants.list` via `mk-tenant.sh`

## Stop everything
```bash
bash scripts/stop-lab.sh --with-k3s --purge-nft
```
- Tears down tenants from `configs/tenants.list`
- Brings down `wg-mgmt`, deletes base VLANs
- Deletes `table inet zobs` if `--purge-nft` given
- Stops k3s (optional flag)

## Configure tenants
Edit `configs/tenants.list`:
```
A 101
B 102
# C 103
```
Then run `bash scripts/start-lab.sh` again.
