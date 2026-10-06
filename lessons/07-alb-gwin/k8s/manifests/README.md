# HTTPRoute Manifests

Манифесты для настройки HTTPRoute с различными весами трафика для canary deployment.

## Файлы

- `00-podinfo-httproute-100-0.yaml` - 100% трафика на stable, 0% на canary
- `01-podinfo-httproute-90-10.yaml` - 90% трафика на stable, 10% на canary
- `02-podinfo-httproute-0-100.yaml` - 0% трафика на stable, 100% на canary

## Использование sed для правки файлов

Манифесты содержат плейсхолдер `<YOUR_DNS_ZONE>`, который необходимо заменить на значение переменной окружения `TF_VAR_dns_zone` в самих файлах на диске перед применением.

### Подготовка манифестов

1. **Загрузите переменные окружения:**

```bash
# Перейти в директорию манифестов
cd ~/yc-k8s-advanced/lessons/07-alb-gwin/k8s/manifests

# Загрузить переменные из tf.env (включая TF_VAR_dns_zone)
source ~/yc-k8s-advanced/lessons/tf.env
```

2. **Заменить плейсхолдеры в файлах на диске:**

```bash
# Заменить <YOUR_DNS_ZONE> на значение TF_VAR_dns_zone во всех манифестах
sed -i "s/<YOUR_DNS_ZONE>/${TF_VAR_dns_zone}/g" 00-podinfo-httproute-100-0.yaml
sed -i "s/<YOUR_DNS_ZONE>/${TF_VAR_dns_zone}/g" 01-podinfo-httproute-90-10.yaml
sed -i "s/<YOUR_DNS_ZONE>/${TF_VAR_dns_zone}/g" 02-podinfo-httproute-0-100.yaml
```

**Примечание:** Флаг `-i` в `sed` означает редактирование файла "на месте" (in-place). Файлы будут изменены на диске.

### Применение манифестов

После замены плейсхолдеров можно применить манифесты:

```bash
# Создать HTTPRoute с распределением трафика 100% на стабильную версию
kubectl apply -f 00-podinfo-httproute-100-0.yaml
# Создать HTTPRoute с распределением трафика 90% на стабильную версию 10% на canary версию
kubectl apply -f 01-podinfo-httproute-90-10.yaml
# Создать HTTPRoute с распределением трафика 100% на canary версию
kubectl apply -f 02-podinfo-httproute-0-100.yaml
```

### Восстановление плейсхолдеров (опционально)

Если нужно вернуть плейсхолдеры обратно в файлы:

```bash
# Восстановить плейсхолдеры во всех манифестах
sed -i "s/podinfo\.${TF_VAR_dns_zone}/podinfo.<YOUR_DNS_ZONE>/g" 00-podinfo-httproute-100-0.yaml
sed -i "s/podinfo\.${TF_VAR_dns_zone}/podinfo.<YOUR_DNS_ZONE>/g" 01-podinfo-httproute-90-10.yaml
sed -i "s/podinfo\.${TF_VAR_dns_zone}/podinfo.<YOUR_DNS_ZONE>/g" 02-podinfo-httproute-0-100.yaml
```

## Примеры использования

### Полный процесс: подготовка и применение

```bash
# Перейти в директорию манифестов
cd ~/yc-k8s-advanced/lessons/07-alb-gwin/k8s/manifests

# Загрузить переменные окружения
source ~/yc-k8s-advanced/lessons/tf.env

# Заменить плейсхолдеры в файлах
sed -i "s/<YOUR_DNS_ZONE>/${TF_VAR_dns_zone}/g" 00-podinfo-httproute-100-0.yaml
sed -i "s/<YOUR_DNS_ZONE>/${TF_VAR_dns_zone}/g" 01-podinfo-httproute-90-10.yaml
sed -i "s/<YOUR_DNS_ZONE>/${TF_VAR_dns_zone}/g" 02-podinfo-httproute-0-100.yaml

# Применить манифесты
kubectl apply -f 00-podinfo-httproute-100-0.yaml
kubectl apply -f 01-podinfo-httproute-90-10.yaml
kubectl apply -f 02-podinfo-httproute-0-100.yaml
```

### Применить только один манифест

Например, применить манифест с 100% трафика на stable:

```bash
cd ~/yc-k8s-advanced/lessons/07-alb-gwin/k8s/manifests
source ~/yc-k8s-advanced/lessons/tf.env

# Заменить плейсхолдер в файле
sed -i "s/<YOUR_DNS_ZONE>/${TF_VAR_dns_zone}/g" 00-podinfo-httproute-100-0.yaml

# Применить манифест
kubectl apply -f 00-podinfo-httproute-100-0.yaml
```

## Проверка перед применением

Проверить результат замены перед применением:

```bash
source ~/yc-k8s-advanced/lessons/tf.env

# Просмотреть результат замены (без изменения файла)
sed "s/<YOUR_DNS_ZONE>/${TF_VAR_dns_zone}/g" 00-podinfo-httproute-100-0.yaml
```

Или проверить с dry-run после замены:

```bash
source ~/yc-k8s-advanced/lessons/tf.env

# Заменить плейсхолдер
sed -i "s/<YOUR_DNS_ZONE>/${TF_VAR_dns_zone}/g" 00-podinfo-httproute-100-0.yaml

# Проверить с dry-run
kubectl apply --dry-run=client -f 00-podinfo-httproute-100-0.yaml
```

## Удаление ресурсов

```bash
# Удалить все HTTPRoute из namespace demo
kubectl delete httproute -n demo --all
```

## Примечания

- Убедитесь, что переменная `TF_VAR_dns_zone` установлена перед применением манифестов
- DNS зона должна соответствовать настройкам Gateway
- Веса трафика должны суммироваться до 100 для каждого правила

