# Canary Strategy для podinfo-rollout

Canary развертывание с постепенным увеличением трафика: 20% → 40% → 60% → 80% → 100%

## Файлы конфигурации

Для canary стратегии используются три файла:

- **`values-canary-stable.yaml`** — стабильная версия (белый цвет UI)
- **`values-canary-new.yaml`** — canary версия (синий цвет UI)
- **`values-canary-new-bad.yaml`** — нерабочая canary версия (красный цвет UI, для демонстрации автоматического отката)

## Деплой

### Первоначальный деплой (стабильная версия)

```bash
# Перейти в директорию с values
cd ~/yc-k8s-advanced/lessons/07-alb-gwin/k8s/helm/podinfo-rollout

# Загрузить переменные окружения
source ~/yc-k8s-advanced/lessons/tf.env

helm install podinfo-rollout ../../../../../helm-charts/podinfo-rollout \
  --namespace demo \
  --create-namespace \
  --values values-canary-stable.yaml \
  --set httpRoutes[0].hostnames[0]=podinfo.${TF_VAR_dns_zone} \
  --set httpRoutes[1].hostnames[0]=podinfo.${TF_VAR_dns_zone}
```

**Что создается:**
- Rollout с canary strategy
- Сервис `podinfo-stable` (селектор автоматически управляется Argo Rollouts)
- Сервис `podinfo-canary` (селектор автоматически управляется Argo Rollouts)
- HTTPRoute для редиректа и основного трафика

### Обновление до canary версии

После деплоя стабильной версии, для развертывания canary версии:

```bash
# Перейти в директорию с values
cd ~/yc-k8s-advanced/lessons/07-alb-gwin/k8s/helm/podinfo-rollout

# Загрузить переменные окружения
source ~/yc-k8s-advanced/lessons/tf.env

# Обновление до canary версии
helm upgrade podinfo-rollout ../../../../../helm-charts/podinfo-rollout \
  --namespace demo \
  --values values-canary-new.yaml \
  --set httpRoutes[0].hostnames[0]=podinfo.${TF_VAR_dns_zone} \
  --set httpRoutes[1].hostnames[0]=podinfo.${TF_VAR_dns_zone}
```

После обновления Rollout автоматически начнет canary развертывание согласно настроенным шагам.

**Мониторинг развертывания:**
```bash
# Просмотр статуса Rollout в реальном времени
# Имя rollout: podinfo-rollout (из release name) или podinfo (если задан fullnameOverride)
kubectl argo rollouts get rollout podinfo-rollout -n demo -w
```

### Деплой нерабочей версии (для демонстрации автоматического отката)

После успешного деплоя рабочей canary версии, можно продемонстрировать автоматический откат, развернув нерабочую версию:

```bash
# Перейти в директорию с values
cd ~/yc-k8s-advanced/lessons/07-alb-gwin/k8s/helm/podinfo-rollout

# Загрузить переменные окружения
source ~/yc-k8s-advanced/lessons/tf.env

# Деплой нерабочей версии
helm upgrade podinfo-rollout ../../../../../helm-charts/podinfo-rollout \
  --namespace demo \
  --values values-canary-new-bad.yaml \
  --set httpRoutes[0].hostnames[0]=podinfo.${TF_VAR_dns_zone} \
  --set httpRoutes[1].hostnames[0]=podinfo.${TF_VAR_dns_zone}
```

**Что произойдет:**
- Rollout начнет canary развертывание нерабочей версии
- Нерабочая версия имеет `unready: true`, что делает readiness probe всегда падающей
- Поды не смогут стать ready
- **Автоматический откат включен** через настройки `progressDeadlineSeconds: 120` и `progressDeadlineAbort: true`
- Если pod'ы не станут ready в течение 120 секунд, Argo Rollouts автоматически выполнит откат к предыдущей (рабочей) версии
- Если автоматический откат не произошел, можно выполнить ручной откат

**Мониторинг и ручной откат:**
```bash
# Просмотр статуса Rollout в реальном времени
# Имя rollout: podinfo-rollout (из release name) или podinfo (если задан fullnameOverride)
kubectl argo rollouts get rollout podinfo-rollout -n demo -w

# Или через стандартный kubectl
kubectl get rollout podinfo-rollout -n demo -w

# Если автоматический откат не произошел, выполните ручной откат:
# Отмена текущего развертывания (возврат к stable версии)
kubectl argo rollouts abort podinfo-rollout -n demo

# Или откат к предыдущей версии
kubectl argo rollouts undo podinfo-rollout -n demo
```

## Шаги развертывания

Canary стратегия настроена с следующими шагами:

1. **20% трафика** → пауза 300 секунд (автоматическое продвижение)
2. **40% трафика** → пауза 240 секунд
3. **60% трафика** → пауза 240 секунд
4. **80% трафика** → пауза 240 секунд
5. **100% трафика** → автоматическое завершение

**Примечание:** Все паузы имеют указанную продолжительность, поэтому развертывание продвигается автоматически без ручного вмешательства.

## Управление развертыванием

**Примечание:** Имя rollout формируется из release name Helm (в примерах используется `podinfo-rollout`). Если в values файле задан `fullnameOverride: podinfo`, то имя будет `podinfo`. Для определения имени используйте:
```bash
kubectl get rollout -n demo
```

```bash
# Просмотр манифеста Rollout
kubectl get rollout podinfo-rollout -n demo -o yaml

# Продвижение canary развертывания
# Используется для ручного продвижения, если нужно пропустить паузу
# В текущей конфигурации все паузы автоматические (с duration),
# поэтому команда обычно не требуется, но может быть полезна для ускорения
kubectl argo rollouts promote podinfo-rollout -n demo

# Полное продвижение (пропустить все паузы и шаги)
kubectl argo rollouts promote podinfo-rollout -n demo --full

# Откат Rollout к предыдущей версии
kubectl argo rollouts undo podinfo-rollout -n demo

# Откат к конкретной ревизии
kubectl argo rollouts undo podinfo-rollout -n demo --to-revision=3

# Просмотр детального статуса (включая историю версий)
kubectl argo rollouts get rollout podinfo-rollout -n demo

# Просмотр статуса с отслеживанием в реальном времени
kubectl argo rollouts get rollout podinfo-rollout -n demo -w
```

## Распределение трафика

HTTPRoute настроен для распределения трафика между сервисами:
- `podinfo-stable` — 90% трафика
- `podinfo-canary` — 10% трафика

Во время canary развертывания Argo Rollouts автоматически управляет селекторами сервисов, добавляя метку `rollouts-pod-template-hash` для выбора правильных подов.

## Автоматический откат

Для включения автоматического отката при проблемах с развертыванием используются следующие параметры:

- **`progressDeadlineSeconds`** — время в секундах для ожидания готовности pod'ов перед автоматическим откатом (по умолчанию 600 секунд для Rollout)
- **`progressDeadlineAbort`** — флаг для включения автоматического отката при превышении `progressDeadlineSeconds` (по умолчанию `false`)

**Пример настройки в values файле:**
```yaml
rollout:
  progressDeadlineSeconds: 120  # Откат через 120 секунд, если pod'ы не готовы
  progressDeadlineAbort: true  # Включить автоматический откат
  strategy:
    canary:
      # ... остальная конфигурация
```

**Как это работает:**
1. При развертывании новой версии Argo Rollouts отслеживает состояние pod'ов
2. Если pod'ы не проходят readiness probe и не становятся ready в течение `progressDeadlineSeconds`, развертывание считается неудачным
3. При `progressDeadlineAbort: true` Argo Rollouts автоматически выполняет откат к предыдущей стабильной версии
4. Если `progressDeadlineAbort: false` или не указан, развертывание остается в состоянии ожидания до ручного вмешательства

**В файле `values-canary-new-bad.yaml` автоматический откат настроен:**
- `progressDeadlineSeconds: 120` — откат через 120 секунд
- `progressDeadlineAbort: true` — включен автоматический откат

Подробнее см. [Argo Rollouts: Rollback](https://argoproj.github.io/argo-rollouts/features/rollback/).

## Примечания

- Для базового canary (без `trafficRouting`) Argo Rollouts может работать с одним сервисом, распределяя трафик через количество реплик
- В нашем случае используются два сервиса, так как HTTPRoute требует их для распределения трафика через веса (90/10)
- Argo Rollouts автоматически управляет селекторами сервисов, добавляя метку `rollouts-pod-template-hash` для выбора правильных подов
- Все шаги имеют автоматическое продвижение через указанные паузы (не требуется ручное продвижение)
- Нерабочая версия (`values-canary-new-bad.yaml`) демонстрирует автоматический откат при проблемах с readiness probe (настроен через `progressDeadlineSeconds` и `progressDeadlineAbort`)

## Дополнительные ресурсы

- [Argo Rollouts Canary strategy](https://argoproj.github.io/argo-rollouts/features/canary/)
- [Rollout Specification](https://argo-rollouts.readthedocs.io/en/stable/features/specification/)

