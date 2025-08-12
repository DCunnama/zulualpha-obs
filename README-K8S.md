# Kubernetes pack + secrets helper

- `k8s/`: Minimal manifests for Grafana, Prometheus, Uptime Kuma (NodePort).
- `scripts/generate_secrets.sh`: Generates WireGuard keypairs and patches placeholders into configs.

## Use with the main repo
Place this folder's contents into the root of your `zulualpha-obs` repo (merge `k8s/` and `scripts/`).

## Install k3s (single node)
```bash
curl -sfL https://get.k3s.io | sh -
# kubeconfig: /etc/rancher/k3s/k3s.yaml (symlinked to ~/.kube/config by installer)
kubectl get nodes
```

## Deploy services
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/grafana-deploy.yaml
kubectl apply -f k8s/prometheus-deploy.yaml
kubectl apply -f k8s/uptime-kuma-deploy.yaml
kubectl -n zobs-services get svc
```

## Generate WireGuard secrets
```bash
chmod +x scripts/generate_secrets.sh
./scripts/generate_secrets.sh
```

## Notes
- Manifests use `emptyDir:` for simplicity in lab; switch to PersistentVolumeClaims for durability.
- For clean URLs + TLS, add an Ingress (Traefik is bundled with k3s).
