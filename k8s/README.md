This folder contains minimal Kubernetes manifests for the Services stack (Grafana, Prometheus, Uptime Kuma).

Quick start (k3s or microk8s):
1) Install k3s (single-node): https://k3s.io
   - e.g. curl -sfL https://get.k3s.io | sh -
2) Apply:
   kubectl apply -f namespace.yaml
   kubectl apply -f grafana-deploy.yaml
   kubectl apply -f prometheus-deploy.yaml
   kubectl apply -f uptime-kuma-deploy.yaml
3) Get NodePort URLs:
   kubectl -n zobs-services get svc

For production, replace emptyDir with PersistentVolumeClaims and add Ingress (TLS).
