# Podinfo (ручной деплой через Helm) — Урок 07 ALB gwin

Этот каталог содержит набор values-файлов для деплоя `podinfo` с использованием базового чарта `helm-charts/podinfo`.

## Предварительные условия

- Инфраструктура создана через Terraform (Gateway/GatewayPolicy/YCCertificate/DNS и т.д.).
- Подключение к кластеру настроено:

```bash
# Настроить подключение к кластеру
cd ~/yc-k8s-advanced/lessons/07-alb-gwin/terraform
. ./tf.env
eval $(terraform output -raw external_cluster_cmd_str)
```

## Деплой podinfo с разными values

DNS зона передается через `--set`, поэтому `values*.yaml` редактировать не нужно.

### Вариант 1 — базовый (`values.yaml`)

```bash
# Загрузить переменные окружения
source ~/yc-k8s-advanced/lessons/tf.env

# Деплой с базовым values файлом
helm install podinfo ../../../../../helm-charts/podinfo \
  --namespace demo \
  --create-namespace \
  --values values.yaml \
  --set httpRoutes[0].hostnames[0]=podinfo.${TF_VAR_dns_zone} \
  --set httpRoutes[1].hostnames[0]=podinfo.${TF_VAR_dns_zone}
```

### Вариант 2 — stable (`values-stable.yaml`)

```bash
# Установить podinfo-stable
helm install podinfo-stable ../../../../../helm-charts/podinfo \
  --namespace demo \
  --create-namespace \
  --values values-stable.yaml
```

### Вариант 3 — canary (`values-canary.yaml`)

```bash
# Установить podinfo-canary
helm install podinfo-canary ../../../../../helm-charts/podinfo \
  --namespace demo \
  --create-namespace \
  --values values-canary.yaml
```

## Просмотр HTTPRoute

### Список HTTPRoute

```bash
# Показать все HTTPRoute в namespace demo
kubectl get httproute -n demo

# Показать все HTTPRoute во всех namespace'ах
kubectl get httproute --all-namespaces
```

### Получение манифестов HTTPRoute

```bash
# Получить манифест HTTPRoute podinfo-redirect
kubectl get httproute podinfo-redirect -n demo -o yaml

# Получить манифест HTTPRoute podinfo-https
kubectl get httproute podinfo-https -n demo -o yaml
```

## Удаление (uninstall)

```bash
helm uninstall podinfo --namespace demo
helm uninstall podinfo-stable --namespace demo
helm uninstall podinfo-canary --namespace demo
```

## Использование Argo Rollouts

Для развертывания с использованием Argo Rollouts (Canary или Blue-Green strategy) см. отдельный чарт:

- [`../podinfo-rollout/README.md`](../podinfo-rollout/README.md)

## Примечания

- `httpRoutes[0]` — HTTPRoute для редиректа (HTTP → HTTPS)
- `httpRoutes[1]` — HTTPRoute для HTTPS трафика
- Если вы используете `podinfo-stable.*` / `podinfo-canary.*`, убедитесь, что в DNS есть A-записи на IP Gateway (или используйте wildcard-зону).


