# Урок 00: Общая инфраструктура (Common Infrastructure)

## Описание

Этот урок создает общую инфраструктуру, которая используется в других уроках курса. Здесь создаются DNS зона и TLS сертификаты, необходимые для работы приложений.

## Что создается

Terraform автоматически создает следующие ресурсы:

1. **DNS зона** (`yandex_dns_zone.zone`) - публичная DNS зона в Yandex Cloud DNS
2. **TLS сертификат** (`yandex_cm_certificate.le-certificate`) - управляемый сертификат Let's Encrypt через Yandex Cloud Certificate Manager
3. **DNS записи для валидации сертификата** - CNAME записи для подтверждения владения доменом
4. **DNS запись для yc-toolbox** (пример) - A запись, указывающая на IP адрес виртуальной машины yc-toolbox

## Создание ресурсов

**Важно:** 
- Перед применением Terraform необходимо указать переменную `dns_zone` в файле [`tf.env.local`](../tf.env.local) (например: `export TF_VAR_dns_zone="example.com"`)
- DNS зона должна быть доступна для публичного доступа
- Сертификат создается с доменами: `example.com` и `*.example.com` (wildcard для всех поддоменов)

```bash
# Перейти в директорию с Terraform конфигурацией
cd ~/yc-k8s-advanced/lessons/00-common/terraform

# Загрузить переменные окружения
. ./tf.env

# Инициализировать Terraform
terraform init

# Применить конфигурацию
terraform apply
```

## Конфигурация DNS зоны

DNS зона создается как публичная зона с именем, сформированным из `dns_zone` (точки заменяются на дефисы).

**Пример:** Если `dns_zone = "example.com"`, то имя зоны будет `example-com`.

## Конфигурация сертификата

Сертификат создается через Yandex Cloud Certificate Manager с использованием Let's Encrypt:
- **Имя**: `le-certificate-<dns-zone-name>` (где `<dns-zone-name>` - имя DNS зоны с точками, замененными на дефисы)
- **Домены**: 
  - Основной домен: `example.com`
  - Wildcard домен: `*.example.com`
- **Тип валидации**: DNS CNAME (требует создания CNAME записей в DNS зоне)

Terraform автоматически создает необходимые CNAME записи для валидации сертификата.

### Валидация сертификата

После создания сертификата и CNAME записей начинается процесс валидации домена Let's Encrypt. Это асинхронный процесс, который может занять от нескольких десятков минут до суток.

**Важно:** Перед использованием сертификата в других уроках необходимо дождаться, пока сертификат получит статус `ISSUED`.

Статусы сертификата:
- `VALIDATING` - идет процесс валидации домена
- `ISSUED` - сертификат успешно выпущен и готов к использованию
- `INVALID` - валидация не прошла (проверьте CNAME записи)

Для проверки статуса сертификата:

```bash
# Проверить статус сертификата
yc certificate-manager certificate get le-certificate-<dns-zone-name> --format json | jq '.status'

# Или посмотреть полную информацию
yc certificate-manager certificate get le-certificate-<dns-zone-name>
```

**Рекомендация:** После применения Terraform подождите 10-20 минут и проверьте статус сертификата. Только после получения статуса `ISSUED` можно переходить к использованию сертификата в других уроках.

Если валидация затягивается, проверьте:
1. Правильность создания CNAME записей в DNS зоне
2. Доступность DNS зоны из интернета
3. Корректность доменных имен в сертификате

## Проверка создания ресурсов

```bash
# Проверить созданную DNS зону
yc dns zone list

# Проверить созданный сертификат
yc certificate-manager certificate list

# Проверить статус сертификата (должен быть ISSUED)
yc certificate-manager certificate get le-certificate-<dns-zone-name>

# Проверить только статус сертификата
yc certificate-manager certificate get le-certificate-<dns-zone-name> --format json | jq '.status'

# Проверить DNS записи в зоне (включая CNAME для валидации)
yc dns zone list-records --name <dns-zone-name>
```

**Важно:** Убедитесь, что сертификат имеет статус `ISSUED` перед использованием в других уроках. Если статус `VALIDATING`, подождите несколько минут и проверьте снова.

## Обновление конфигурации

```bash
cd ~/yc-k8s-advanced/lessons/00-common/terraform
. ./tf.env
terraform apply
```

## Удаление

```bash
# Удалить все ресурсы через Terraform
cd ~/yc-k8s-advanced/lessons/00-common/terraform
. ./tf.env
terraform destroy
```

**Внимание:** При удалении через `terraform destroy` будут удалены:
- DNS зона и все DNS записи в ней
- TLS сертификат
- Все связанные ресурсы

**Важно:** Убедитесь, что другие уроки не используют эти ресурсы перед удалением.

## Полезные команды

```bash
# Просмотр информации о DNS зоне
yc dns zone get --name <dns-zone-name>

# Просмотр всех записей в DNS зоне
yc dns zone list-records --name <dns-zone-name>

# Просмотр информации о сертификате
yc certificate-manager certificate get le-certificate-<dns-zone-name>

# Проверка статуса валидации сертификата
yc certificate-manager certificate get le-certificate-<dns-zone-name> --format json | jq '.status'
```

## Документация

- [Yandex Cloud DNS](https://yandex.cloud/ru/docs/dns/)
- [Yandex Cloud Certificate Manager](https://yandex.cloud/ru/docs/certificate-manager/)
- [Let's Encrypt](https://letsencrypt.org/)

