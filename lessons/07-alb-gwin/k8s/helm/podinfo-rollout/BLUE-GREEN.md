# Blue-Green Strategy для podinfo-rollout

Blue-Green развертывание с переключением между версиями с возможностью отката.

## Файлы конфигурации

Для blue-green стратегии используются два файла:

- **`values-blue-green-stable.yaml`** — стабильная версия (синий цвет UI #34577c)
- **`values-blue-green-new.yaml`** — новая версия (зеленый цвет UI #2ecc71)

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
  --values values-blue-green-stable.yaml \
  --set httpRoutes[0].hostnames[0]=podinfo.${TF_VAR_dns_zone} \
  --set httpRoutes[1].hostnames[0]=podinfo.${TF_VAR_dns_zone}
```

**Что создается:**
- Rollout с blue-green strategy
- Сервис `podinfo-active` (селектор автоматически управляется Argo Rollouts)
- Сервис `podinfo-preview` (селектор автоматически управляется Argo Rollouts)
- HTTPRoute для редиректа и основного трафика

### Обновление до новой версии

После деплоя стабильной версии, для развертывания новой версии:

```bash
# Перейти в директорию с values
cd ~/yc-k8s-advanced/lessons/07-alb-gwin/k8s/helm/podinfo-rollout

# Загрузить переменные окружения
source ~/yc-k8s-advanced/lessons/tf.env

# Обновление до новой версии
helm upgrade podinfo-rollout ../../../../../helm-charts/podinfo-rollout \
  --namespace demo \
  --values values-blue-green-new.yaml \
  --set httpRoutes[0].hostnames[0]=podinfo.${TF_VAR_dns_zone} \
  --set httpRoutes[1].hostnames[0]=podinfo.${TF_VAR_dns_zone}
```

После обновления Rollout создаст preview версию. Используйте `kubectl argo rollouts promote` для переключения preview в active (если `autoPromotionEnabled: false`).

**Мониторинг развертывания:**
```bash
# Просмотр статуса Rollout в реальном времени
# Имя rollout: podinfo-rollout (из release name) или podinfo (если задан fullnameOverride)
kubectl argo rollouts get rollout podinfo-rollout -n demo -w
```

## Параметры Blue-Green

Blue-Green стратегия настроена со следующими параметрами:

- **`activeService`**: `podinfo-active` (обязателен)
- **`previewService`**: `podinfo-preview` (опционален)
- **`autoPromotionEnabled`**: `false` (требует ручного продвижения)
- **`autoPromotionSeconds`**: `30` (если бы autoPromotionEnabled был true)
- **`scaleDownDelaySeconds`**: `30` (задержка перед масштабированием preview до нуля после продвижения)

**Примечание:** В текущей конфигурации `autoPromotionEnabled: false`, поэтому требуется ручное продвижение через `kubectl argo rollouts promote` после тестирования preview версии.

## Управление развертыванием

**Примечание:** Имя rollout формируется из release name Helm (в примерах используется `podinfo-rollout`). Если в values файле задан `fullnameOverride: podinfo`, то имя будет `podinfo`. Для определения имени используйте:
```bash
kubectl get rollout -n demo
```

```bash
# Просмотр манифеста Rollout
kubectl get rollout podinfo-rollout -n demo -o yaml

# Продвижение preview в active (если autoPromotionEnabled: false)
# Используется для переключения preview версии в active после успешного тестирования
kubectl argo rollouts promote podinfo-rollout -n demo

# Полное продвижение (пропустить все проверки)
kubectl argo rollouts promote podinfo-rollout -n demo --full

# Откат Rollout к предыдущей версии
kubectl argo rollouts undo podinfo-rollout -n demo

# Откат к конкретной ревизии
kubectl argo rollouts undo podinfo-rollout -n demo --to-revision=3

# Просмотр детального статуса (включая историю версий)
kubectl argo rollouts get rollout podinfo-rollout -n demo

# Просмотр статуса с отслеживанием в реальном времени
kubectl argo rollouts get rollout podinfo-rollout -n demo -w

# Или через стандартный kubectl
kubectl get rollout podinfo-rollout -n demo -w
```

## Процесс развертывания

1. **Деплой стабильной версии** — создается Rollout с active сервисом, указывающим на стабильную версию
2. **Обновление до новой версии** — создается preview версия с preview сервисом
3. **Тестирование preview** — можно протестировать новую версию через preview сервис
4. **Продвижение** — при успешном тестировании выполняется `kubectl argo rollouts promote`, который переключает active сервис на новую версию
5. **Масштабирование** — через 30 секунд после продвижения preview версия масштабируется до нуля

## Распределение трафика

HTTPRoute настроен для указания на active сервис (100% трафика). Во время blue-green развертывания:
- **Active сервис** — получает весь трафик (100%)
- **Preview сервис** — используется для тестирования новой версии (не получает трафик через HTTPRoute)

Argo Rollouts автоматически управляет селекторами сервисов, переключая их между версиями при продвижении.

## Примечания

- Для Blue-Green стратегии `activeService` обязателен, `previewService` опционален (см. [спецификацию](https://argo-rollouts.readthedocs.io/en/stable/features/specification/))
- Argo Rollouts автоматически управляет селекторами сервисов, переключая их между версиями при продвижении
- В нашем случае используется HTTPRoute, который указывает на active сервис
- После обновления до новой версии требуется ручное продвижение через `kubectl argo rollouts promote` (если `autoPromotionEnabled: false`)
- Preview версия автоматически масштабируется до нуля через 30 секунд после продвижения
- Blue-Green стратегия позволяет полностью протестировать новую версию через preview сервис перед переключением трафика
- При продвижении происходит мгновенное переключение всего трафика с одной версии на другую (100% переключение)

## Дополнительные ресурсы

- [Argo Rollouts Blue-Green strategy](https://argoproj.github.io/argo-rollouts/features/bluegreen/)
- [Rollout Specification](https://argo-rollouts.readthedocs.io/en/stable/features/specification/)

