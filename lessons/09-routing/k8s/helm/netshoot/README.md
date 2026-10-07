# Установка Netshoot

```bash
# Перейти в директорию с Helm конфигурациями
cd ~/yc-k8s-advanced/lessons/09-routing/k8s/helm/netshoot

# Установить Netshoot
helm install netshoot ../../../../../helm-charts/netshoot \
  --namespace frontend \
  --values <NN-values.yaml>
```

# Удалить Netshoot
```bash
helm uninstall netshoot -n frontend
```