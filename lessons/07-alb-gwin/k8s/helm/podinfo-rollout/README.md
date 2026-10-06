# Podinfo Rollout (ручной деплой через Helm) — Урок 07 ALB gwin

Этот каталог содержит набор values-файлов для деплоя `podinfo` с использованием Argo Rollouts через базовый чарт `helm-charts/podinfo-rollout`.

## Особенности

- **Автономный деплой**: Сервисы для Rollout (stable/canary или active/preview) создаются автоматически
- **Canary strategy**: Постепенное развертывание с паузами для проверки
- **Blue-Green strategy**: Переключение между версиями с возможностью отката

## Предварительные условия

- Инфраструктура создана через Terraform (Gateway/GatewayPolicy/YCCertificate/DNS и т.д.)
- **Argo Rollouts controller установлен в кластере** (через `helm_release.argo_rollouts` в Terraform)
- **Плагин `kubectl-argo-rollouts` установлен** (см. [`../../../../../howtos/INSTALL_ARGO_ROLLOUTS_PLUGIN.md`](../../../../../howtos/INSTALL_ARGO_ROLLOUTS_PLUGIN.md))
- Подключение к кластеру настроено:

```bash
# Настроить подключение к кластеру
cd ~/yc-k8s-advanced/lessons/07-alb-gwin/terraform
. ./tf.env
eval $(terraform output -raw external_cluster_cmd_str)
```

## Деплой podinfo-rollout с разными стратегиями

DNS зона передается через `--set`, поэтому `values*.yaml` редактировать не нужно.

### Вариант 1 — Canary strategy

Canary развертывание с постепенным увеличением трафика: 20% → 40% → 60% → 80% → 100%

**Подробная инструкция:** см. [`CANARY.md`](CANARY.md)

**Файлы конфигурации:**
- `values-canary-stable.yaml` — стабильная версия (белый цвет UI)
- `values-canary-new.yaml` — canary версия (синий цвет UI)
- `values-canary-new-bad.yaml` — нерабочая canary версия (красный цвет UI, для демонстрации автоматического отката)

**Быстрый старт:**
```bash
# Загрузить переменные окружения
source ~/yc-k8s-advanced/lessons/tf.env

# Первоначальный деплой стабильной версии
helm install podinfo-rollout ../../../../../helm-charts/podinfo-rollout \
  --namespace demo \
  --create-namespace \
  --values values-canary-stable.yaml \
  --set httpRoutes[0].hostnames[0]=podinfo.${TF_VAR_dns_zone} \
  --set httpRoutes[1].hostnames[0]=podinfo.${TF_VAR_dns_zone}

# Обновление до canary версии
helm upgrade podinfo-rollout ../../../../../helm-charts/podinfo-rollout \
  --namespace demo \
  --values values-canary-new.yaml \
  --set httpRoutes[0].hostnames[0]=podinfo.${TF_VAR_dns_zone} \
  --set httpRoutes[1].hostnames[0]=podinfo.${TF_VAR_dns_zone}
```

### Вариант 2 — Blue-Green strategy

Blue-Green развертывание с переключением между версиями с возможностью отката

**Подробная инструкция:** см. [`BLUE-GREEN.md`](BLUE-GREEN.md)

**Файлы конфигурации:**
- `values-blue-green-stable.yaml` — стабильная версия (синий цвет UI)
- `values-blue-green-new.yaml` — новая версия (зеленый цвет UI)

**Быстрый старт:**
```bash
# Загрузить переменные окружения
source ~/yc-k8s-advanced/lessons/tf.env

# Первоначальный деплой стабильной версии
helm install podinfo-rollout ../../../../../helm-charts/podinfo-rollout \
  --namespace demo \
  --create-namespace \
  --values values-blue-green-stable.yaml \
  --set httpRoutes[0].hostnames[0]=podinfo.${TF_VAR_dns_zone} \
  --set httpRoutes[1].hostnames[0]=podinfo.${TF_VAR_dns_zone}

# Обновление до новой версии
helm upgrade podinfo-rollout ../../../../../helm-charts/podinfo-rollout \
  --namespace demo \
  --values values-blue-green-new.yaml \
  --set httpRoutes[0].hostnames[0]=podinfo.${TF_VAR_dns_zone} \
  --set httpRoutes[1].hostnames[0]=podinfo.${TF_VAR_dns_zone}
```

## Обновление (upgrade)

### Пример для Canary strategy:

```bash
# Загрузить переменные окружения
source ~/yc-k8s-advanced/lessons/tf.env

# Обновление до canary версии
helm upgrade podinfo-rollout ../../../../../helm-charts/podinfo-rollout \
  --namespace demo \
  --values values-canary-new.yaml \
  --set httpRoutes[0].hostnames[0]=podinfo.${TF_VAR_dns_zone} \
  --set httpRoutes[1].hostnames[0]=podinfo.${TF_VAR_dns_zone}

# Возврат к стабильной версии
helm upgrade podinfo-rollout ../../../../../helm-charts/podinfo-rollout \
  --namespace demo \
  --values values-canary-stable.yaml \
  --set httpRoutes[0].hostnames[0]=podinfo.${TF_VAR_dns_zone} \
  --set httpRoutes[1].hostnames[0]=podinfo.${TF_VAR_dns_zone}
```

После обновления Rollout автоматически начнет canary развертывание согласно настроенным шагам. Используйте `kubectl argo rollouts promote` для продвижения после пауз.

**Подробная инструкция:** см. [`CANARY.md`](CANARY.md)

### Пример для Blue-Green strategy:

```bash
# Загрузить переменные окружения
source ~/yc-k8s-advanced/lessons/tf.env

# Обновление до новой версии
helm upgrade podinfo-rollout ../../../../../helm-charts/podinfo-rollout \
  --namespace demo \
  --values values-blue-green-new.yaml \
  --set httpRoutes[0].hostnames[0]=podinfo.${TF_VAR_dns_zone} \
  --set httpRoutes[1].hostnames[0]=podinfo.${TF_VAR_dns_zone}

# Возврат к стабильной версии
helm upgrade podinfo-rollout ../../../../../helm-charts/podinfo-rollout \
  --namespace demo \
  --values values-blue-green-stable.yaml \
  --set httpRoutes[0].hostnames[0]=podinfo.${TF_VAR_dns_zone} \
  --set httpRoutes[1].hostnames[0]=podinfo.${TF_VAR_dns_zone}
```

После обновления Rollout создаст preview версию. Используйте `kubectl argo rollouts promote` для переключения preview в active (если `autoPromotionEnabled: false`).

**Подробная инструкция:** см. [`BLUE-GREEN.md`](BLUE-GREEN.md)

## Удаление (uninstall)

```bash
helm uninstall podinfo-rollout --namespace demo
```

## Примечания

- **Имя Rollout**: Имя rollout формируется из release name Helm (в примерах используется `podinfo-rollout`). Если в values файле задан `fullnameOverride: podinfo`, то имя будет `podinfo`. Для определения имени используйте: `kubectl get rollout -n demo`
- `httpRoutes[0]` — HTTPRoute для редиректа (HTTP → HTTPS)
- `httpRoutes[1]` — HTTPRoute для HTTPS трафика
- Для Canary strategy: HTTPRoute настроен для распределения трафика между stable (90%) и canary (10%) сервисами
- Для Blue-Green strategy: HTTPRoute указывает на active сервис (100%)
- Сервисы создаются чартом и автоматически управляются Argo Rollouts контроллером (селекторы обновляются автоматически)
- Для управления Rollout используйте `kubectl argo rollouts` команды (см. [`CANARY.md`](CANARY.md) и [`BLUE-GREEN.md`](BLUE-GREEN.md) для примеров)

## Дополнительные ресурсы

- [Argo Rollouts документация](https://argoproj.github.io/argo-rollouts/)
- [Canary strategy](https://argoproj.github.io/argo-rollouts/features/canary/)
- [Blue-Green strategy](https://argoproj.github.io/argo-rollouts/features/bluegreen/)
