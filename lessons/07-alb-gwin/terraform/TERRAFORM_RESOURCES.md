# Схема ресурсов Terraform для урока 07 (ALB Gwin)

## Mindmap схема ресурсов

```mermaid
mindmap
  root((Terraform Resources<br/>Lesson 07))
    Data Sources
      yandex_vpc_network.default
        VPC сеть "default"
      yandex_vpc_subnet.k8s_master_subnet
        Подсеть для K8s master
      yandex_vpc_subnet.default_ru_central1_*
        Подсети по умолчанию
        ru-central1-a
        ru-central1-b
        ru-central1-d
      yandex_dns_zone.zone
        DNS зона
      yandex_cm_certificate.le-certificate
        Сертификат из CM
      yandex_logging_group.default
        Лог-группа
      yandex_client_config.client
        folder_id
      yandex_kubernetes_cluster.cluster
        Созданный кластер
    VPC Resources
      yandex_vpc_gateway.default
        shared_egress_gateway
        Интернет-шлюз
      yandex_vpc_route_table.gateway
        0.0.0.0/0 → gateway
        Таблица маршрутизации
      yandex_vpc_subnet.k8s_nodes
        ru-central1-a
          10.20.0.0/24
        ru-central1-b
          10.20.1.0/24
        ru-central1-d
          10.20.2.0/24
    Kubernetes Cluster
      module.kube
        k8s-lesson-07
        Network: default
        Cluster IP: 10.10.0.0/16
        Service IP: 172.17.0.0/16
        Cilium: enabled
        Node Group
          yc-k8s-ng-lesson-07-01
          2 ноды
          NAT: disabled
    IAM Resources
      yandex_iam_service_account.alb_controller
        alb-controller
      yandex_iam_service_account_key.alb_controller_key
        Ключ для SA
      yandex_resourcemanager_folder_iam_member
        alb.editor
        vpc.publicAdmin
        certificate-manager.certificates.downloader
        certificate-manager.editor
        compute.viewer
        k8s.viewer
        logging.writer
    Network Address
      yandex_vpc_address.gwin_gateway
        Статический публичный IP
        Зона: ru-central1-b
    DNS
      yandex_dns_recordset.podinfo
        A-запись
        podinfo."dns_zone"
        → Gateway IP
    Helm Releases
      helm_release.namespaces
        gwin-system
          project=gwin
        demo
          project=podinfo
        argo-rollouts
          project=argo-rollouts
      helm_release.gwin_controller
        Chart: gwin-chart
        Namespace: gwin-system
        Использует IAM key
      helm_release.argo_rollouts
        Name: argo-rollouts
        Chart: argo-rollouts
        Namespace: argo-rollouts
        installCRDs: true
        clusterInstall: true
        Gateway API Plugin
          v0.5.0
          initContainer
      helm_release.gwin_resources
        Chart: gwin-resources
        Namespace: gwin-system
        YCCertificate
          Ссылка на CM сертификат
        Gateway
          Listener HTTP:80
            Редирект на HTTPS
          Listener HTTPS:443
            TLS termination
          Address: статический IP
        GatewayPolicy
          AutoScale
            minZoneSize: 2
            maxSize: 6
          Logging
            Лог-группа: default
          Zones
            ru-central1-a
            ru-central1-b
            ru-central1-d
      time_sleep.wait_for_alb_deletion
        Задержка: 120s
        При удалении
        Зависит от
          gwin_controller
          gwin_gateway
        Зависит от
          gwin_controller
          gwin_gateway
        Зависит от: gwin_controller, gwin_gateway
```

## Диаграмма ресурсов (граф зависимостей)

```mermaid
graph TB
    %% Data Sources
    subgraph DS["Data Sources (внешние ресурсы)"]
        DS_NET["yandex_vpc_network<br/>default"]
        DS_MASTER_SUBNET["yandex_vpc_subnet<br/>k8s_master_subnet"]
        DS_DEFAULT_SUBNETS["yandex_vpc_subnet<br/>default_ru_central1_*"]
        DS_DNS_ZONE["yandex_dns_zone<br/>zone"]
        DS_CERT["yandex_cm_certificate<br/>le-certificate"]
        DS_LOGGING["yandex_logging_group<br/>default"]
        DS_CLIENT["yandex_client_config<br/>client"]
        DS_CLUSTER["yandex_kubernetes_cluster<br/>cluster"]
    end

    %% VPC Resources
    subgraph VPC["VPC Resources"]
        VPC_GW["yandex_vpc_gateway<br/>default<br/>(shared_egress_gateway)"]
        VPC_RT["yandex_vpc_route_table<br/>gateway<br/>(0.0.0.0/0 → gateway)"]
        VPC_SUBNET_A["yandex_vpc_subnet<br/>k8s_nodes_ru_central1_a<br/>(10.20.0.0/24)"]
        VPC_SUBNET_B["yandex_vpc_subnet<br/>k8s_nodes_ru_central1_b<br/>(10.20.1.0/24)"]
        VPC_SUBNET_D["yandex_vpc_subnet<br/>k8s_nodes_ru_central1_d<br/>(10.20.2.0/24)"]
    end

    %% Kubernetes Module
    subgraph K8S["Kubernetes Cluster"]
        K8S_MODULE["module.kube<br/>(terraform-yc-kubernetes)<br/>k8s-lesson-07"]
    end

    %% IAM Resources
    subgraph IAM["IAM Resources"]
        IAM_SA["yandex_iam_service_account<br/>alb_controller"]
        IAM_KEY["yandex_iam_service_account_key<br/>alb_controller_key"]
        IAM_ROLES["yandex_resourcemanager_folder_iam_member<br/>alb.editor, vpc.publicAdmin,<br/>certificate-manager.*,<br/>compute.viewer, k8s.viewer,<br/>logging.writer"]
    end

    %% Network Address
    subgraph NET["Network Address"]
        NET_ADDR["yandex_vpc_address<br/>gwin_gateway<br/>(static public IP)"]
    end

    %% DNS
    subgraph DNS["DNS"]
        DNS_RECORD["yandex_dns_recordset<br/>podinfo<br/>(A record → Gateway IP)"]
    end

    %% Helm Releases
    subgraph HELM["Helm Releases"]
        HELM_NS["helm_release.namespaces<br/>(gwin-system, demo, argo-rollouts)"]
        HELM_GWIN["helm_release.gwin_controller<br/>(gwin ALB controller)"]
        HELM_ARGO["helm_release.argo_rollouts<br/>(Argo Rollouts<br/>Gateway API Plugin)"]
        HELM_GWIN_RES["helm_release.gwin_resources<br/>(Gateway, GatewayPolicy,<br/>YCCertificate)"]
        HELM_WAIT["time_sleep<br/>wait_for_alb_deletion"]
    end

    %% Dependencies - Data Sources
    DS_NET --> VPC_GW
    DS_NET --> VPC_RT
    DS_NET --> VPC_SUBNET_A
    DS_NET --> VPC_SUBNET_B
    DS_NET --> VPC_SUBNET_D
    DS_NET --> K8S_MODULE
    DS_MASTER_SUBNET --> K8S_MODULE
    DS_CLIENT --> IAM_ROLES
    DS_DNS_ZONE --> DNS_RECORD
    DS_CERT --> HELM_GWIN_RES
    DS_LOGGING --> HELM_GWIN_RES
    K8S_MODULE --> DS_CLUSTER

    %% Dependencies - VPC
    VPC_GW --> VPC_RT
    VPC_RT --> VPC_SUBNET_A
    VPC_RT --> VPC_SUBNET_B
    VPC_RT --> VPC_SUBNET_D
    VPC_SUBNET_A --> K8S_MODULE
    VPC_SUBNET_B --> K8S_MODULE
    VPC_SUBNET_D --> K8S_MODULE

    %% Dependencies - IAM
    IAM_SA --> IAM_ROLES
    IAM_SA --> IAM_KEY
    IAM_KEY --> HELM_GWIN

    %% Dependencies - Network Address
    NET_ADDR --> DNS_RECORD
    NET_ADDR --> HELM_GWIN_RES
    NET_ADDR --> HELM_WAIT

    %% Dependencies - Kubernetes
    K8S_MODULE --> HELM_NS
    K8S_MODULE --> HELM_GWIN
    K8S_MODULE --> HELM_ARGO

    %% Dependencies - Helm
    HELM_NS --> HELM_GWIN
    HELM_NS --> HELM_ARGO
    HELM_NS --> HELM_GWIN_RES
    HELM_GWIN --> HELM_WAIT
    HELM_WAIT --> HELM_GWIN_RES

    %% Styling
    classDef dataSource fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef vpc fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef k8s fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef iam fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef network fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef dns fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    classDef helm fill:#e0f2f1,stroke:#004d40,stroke-width:2px

    class DS_NET,DS_MASTER_SUBNET,DS_DEFAULT_SUBNETS,DS_DNS_ZONE,DS_CERT,DS_LOGGING,DS_CLIENT,DS_CLUSTER dataSource
    class VPC_GW,VPC_RT,VPC_SUBNET_A,VPC_SUBNET_B,VPC_SUBNET_D vpc
    class K8S_MODULE k8s
    class IAM_SA,IAM_KEY,IAM_ROLES iam
    class NET_ADDR network
    class DNS_RECORD dns
    class HELM_NS,HELM_GWIN,HELM_ARGO,HELM_GWIN_RES,HELM_WAIT helm
```

## Описание ресурсов

### Data Sources (внешние ресурсы)

- **yandex_vpc_network.default** - существующая VPC сеть "default"
- **yandex_vpc_subnet.k8s_master_subnet** - существующая подсеть для Kubernetes master
- **yandex_vpc_subnet.default_ru_central1_*** - существующие подсети по умолчанию в трех зонах
- **yandex_dns_zone.zone** - существующая DNS зона
- **yandex_cm_certificate.le-certificate** - сертификат из Certificate Manager
- **yandex_logging_group.default** - лог-группа по умолчанию
- **yandex_client_config.client** - конфигурация клиента (folder_id)
- **yandex_kubernetes_cluster.cluster** - созданный Kubernetes кластер

### VPC Resources

- **yandex_vpc_gateway.default** - интернет-шлюз (shared egress gateway) для исходящего трафика
- **yandex_vpc_route_table.gateway** - таблица маршрутизации (0.0.0.0/0 → gateway)
- **yandex_vpc_subnet.k8s_nodes_ru_central1_*** - три подсети для Kubernetes nodes:
  - `ru-central1-a`: 10.20.0.0/24
  - `ru-central1-b`: 10.20.1.0/24
  - `ru-central1-d`: 10.20.2.0/24

### Kubernetes Cluster

- **module.kube** - модуль создания Kubernetes кластера:
  - Имя: `k8s-lesson-07`
  - Network: `default`
  - Cluster IP range: `10.10.0.0/16`
  - Service IP range: `172.17.0.0/16`
  - Cilium policy: включена
  - Node group: `yc-k8s-ng-lesson-07-01` (2 ноды, фиксированный размер)
  - NAT: отключен (используется gateway через route table)

### IAM Resources

- **yandex_iam_service_account.alb_controller** - сервисный аккаунт для ALB контроллера
- **yandex_iam_service_account_key.alb_controller_key** - ключ для сервисного аккаунта
- **yandex_resourcemanager_folder_iam_member** - роли для сервисного аккаунта:
  - `alb.editor` - создание ресурсов ALB
  - `vpc.publicAdmin` - управление сетевой связностью
  - `certificate-manager.certificates.downloader` - доступ к сертификатам
  - `certificate-manager.editor` - управление сертификатами
  - `compute.viewer` - просмотр узлов кластера
  - `k8s.viewer` - просмотр кластера
  - `logging.writer` - запись логов

### Network Address

- **yandex_vpc_address.gwin_gateway** - статический публичный IPv4 адрес для Gateway (зона: ru-central1-b)

### DNS

- **yandex_dns_recordset.podinfo** - A-запись `podinfo.{dns_zone}` → статический IP Gateway

### Helm Releases

1. **helm_release.namespaces** - создание namespace'ов:
   - `gwin-system` (project=gwin)
   - `demo` (project=podinfo)
   - `argo-rollouts` (project=argo-rollouts)

2. **helm_release.gwin_controller** - установка gwin ALB контроллера:
   - Chart: `gwin-chart`
   - Namespace: `gwin-system`
   - Использует ключ сервисного аккаунта для доступа к Yandex Cloud API

3. **helm_release.argo_rollouts** - установка Argo Rollouts:
   - Name: `argo-rollouts`
   - Chart: `argo-rollouts`
   - Namespace: `argo-rollouts`
   - CRDs: устанавливаются автоматически (`installCRDs: true`)
   - Cluster install: включен (`clusterInstall: true`)
   - Gateway API Plugin: установлен через initContainer (v0.5.0)

4. **helm_release.gwin_resources** - создание ресурсов Gateway:
   - Chart: `gwin-resources`
   - Namespace: `gwin-system`
   - Ресурсы:
     - `YCCertificate` - ссылка на сертификат из Certificate Manager
     - `Gateway` - настройка Application Load Balancer:
       - Listener HTTP (порт 80) - редирект на HTTPS
       - Listener HTTPS (порт 443) - терминация TLS
       - Address: статический IP из `yandex_vpc_address.gwin_gateway`
     - `GatewayPolicy` - политика для Gateway:
       - AutoScale: minZoneSize=2, maxSize=6
       - Logging: в лог-группу `default`
       - Zones: ru-central1-a, ru-central1-b, ru-central1-d

5. **time_sleep.wait_for_alb_deletion** - задержка при удалении (120 секунд) для корректного удаления ALB перед удалением Gateway:
   - Зависит от: `helm_release.gwin_controller`, `yandex_vpc_address.gwin_gateway`
   - Используется для обеспечения корректного порядка удаления ресурсов

## Порядок создания ресурсов

1. **Data Sources** - чтение существующих ресурсов
2. **VPC Resources** - создание gateway, route table, subnets
3. **Kubernetes Cluster** - создание кластера с использованием VPC ресурсов
4. **IAM Resources** - создание сервисного аккаунта и назначение ролей
5. **Network Address** - резервирование статического IP
6. **Helm: namespaces** - создание namespace'ов
7. **Helm: gwin_controller** - установка ALB контроллера
8. **Helm: argo_rollouts** - установка Argo Rollouts
9. **Helm: gwin_resources** - создание Gateway ресурсов (после задержки)
10. **DNS** - создание A-записи для podinfo

## Порядок удаления ресурсов

1. **DNS** - удаление A-записи
2. **Helm: gwin_resources** - удаление Gateway ресурсов
3. **Helm: wait_for_alb_deletion** - ожидание удаления ALB (120 секунд)
4. **Helm: gwin_controller** - удаление ALB контроллера
5. **Helm: argo_rollouts** - удаление Argo Rollouts
6. **Helm: namespaces** - удаление namespace'ов
7. **Network Address** - освобождение статического IP
8. **IAM Resources** - удаление ключа, ролей, сервисного аккаунта
9. **Kubernetes Cluster** - удаление кластера
10. **VPC Resources** - удаление subnets, route table, gateway

