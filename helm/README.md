Install monitoring stack:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/prometheus -f ./prometheus-grafana/prometheus-values.yaml
helm install grafana grafana/grafana -f ./prometheus-grafana/grafana-values.yaml
```
Access Grafana UI via the LoadBalancer EXTERNAL-IP and login with admin/admin.