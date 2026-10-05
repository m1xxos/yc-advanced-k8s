# Урок 05: DNS в Kubernetes

## Описание

Этот урок демонстрирует работу с DNS в Kubernetes кластере. Вы научитесь:
- Настраивать DNS конфигурацию для подов
- Использовать MutatingAdmissionWebhook для автоматической настройки DNS
- Понимать, как работает DNS резолюция в Kubernetes

## Создание кластера Kubernetes

Кластер создается через Terraform.

```bash
# Перейти в директорию с Terraform конфигурацией
cd ~/yc-k8s-advanced/lessons/05-dns/terraform

# Загрузить переменные окружения
. ./tf.env

# Инициализировать Terraform
terraform init

# Применить конфигурацию
terraform apply
```

**Важно:** Кластер создается с включенной поддержкой Cilium NetworkPolicy (`enable_cilium_policy = true`).

## Настройка подключения к k8s

```bash
cd ~/yc-k8s-advanced/lessons/05-dns/terraform
. ./tf.env

# Настроить подключение к кластеру
eval $(terraform output -raw external_cluster_cmd_str)

# Проверить подключение
kubectl cluster-info
```

## Что создается через Terraform

Terraform автоматически создает следующие ресурсы:

1. **Kubernetes кластер** (`k8s-lesson-05`) с 1 узлом
2. **IAM Service Account** для узлов кластера
3. **Приватные подсети для k8s нод** в трех зонах:
   - `k8s-nodes-lesson-05-ru-central1-a` (10.22.0.0/24)
   - `k8s-nodes-lesson-05-ru-central1-b` (10.22.1.0/24)
   - `k8s-nodes-lesson-05-ru-central1-d` (10.22.2.0/24)
4. **Internet Gateway** для исходящего трафика из приватных подсетей
5. **Route Table** с маршрутом через NAT Gateway

## Приватные подсети для k8s нод

Урок использует приватные подсети для Kubernetes нод:
- Ноды не имеют публичных IP адресов (`nat = false`)
- Исходящий трафик идет через NAT Gateway (Internet Gateway)
- Используются отдельные CIDR блоки (`10.22.x.0/24`), чтобы не конфликтовать с другими уроками

## Проверка установки

```bash
# Проверить статус кластера
kubectl cluster-info

# Проверить ноды
kubectl get nodes

# Проверить поды в системных namespace'ах
kubectl get pods -n kube-system

# Проверить DNS конфигурацию CoreDNS
kubectl get configmap coredns -n kube-system -o yaml
```

## Примеры использования

В директории [`../examples/dns-config-webhook/`](../examples/dns-config-webhook/) находится пример MutatingAdmissionWebhook для автоматической настройки DNS конфигурации подов.

### DNS Config Mutating Webhook

Этот webhook автоматически добавляет `dnsConfig` с кастомным `ndots` ко всем подам в кластере.

**Подробная инструкция:** см. [`../examples/dns-config-webhook/README.md`](../examples/dns-config-webhook/README.md)

## Обновление конфигурации

```bash
cd ~/yc-k8s-advanced/lessons/05-dns/terraform
. ./tf.env

# Обновить конфигурацию
terraform apply
```

## Удаление

```bash
cd ~/yc-k8s-advanced/lessons/05-dns/terraform
. ./tf.env

# Удалить все ресурсы
terraform destroy
```

**Внимание:** При удалении через `terraform destroy` будут удалены:
- Kubernetes кластер
- Приватные подсети для k8s нод
- Internet Gateway и Route Table
- IAM Service Account
- Все связанные ресурсы

## Полезные команды для работы с DNS

```bash
# Проверить DNS резолюцию из пода
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Проверить DNS конфигурацию пода
kubectl get pod <pod-name> -o jsonpath='{.spec.dnsConfig}'

# Проверить DNS политику пода
kubectl get pod <pod-name> -o jsonpath='{.spec.dnsPolicy}'

# Посмотреть логи CoreDNS
kubectl logs -n kube-system -l k8s-app=kube-dns

# Проверить конфигурацию CoreDNS
kubectl get configmap coredns -n kube-system -o yaml
```

## Документация

- [Kubernetes DNS](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [DNS для подов и сервисов](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [DNS конфигурация подов](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-dns-config)
- [MutatingAdmissionWebhook](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#mutatingadmissionwebhook)

