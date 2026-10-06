# Internet Gateway for gateway subnets
# Интернет-шлюз для gateway подсетей
# Документация: https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_gateway
resource "yandex_vpc_gateway" "default" {
  name = "default-gateway"
  # shared_egress_gateway создает интернет-шлюз для исходящего трафика
  # По умолчанию создается shared egress gateway
  shared_egress_gateway {}
}

# Route table for gateway subnets
# Таблица маршрутизации для gateway подсетей
# Документация: https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_route_table
resource "yandex_vpc_route_table" "gateway" {
  name        = "default-gateway-route-table"
  description = "Route table for gateway subnets"
  network_id  = data.yandex_vpc_network.default.id

  # Маршрут по умолчанию для исходящего трафика через интернет-шлюз
  # Все трафик (0.0.0.0/0) направляется через gateway
  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.default.id
  }
}

# K8s nodes subnets for ALB and K8s
# Подсети для Kubernetes nodes используются для размещения Application Load Balancer через gwin и для Kubernetes
# Документация: https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_subnet
# Эти подсети должны быть указаны в GatewayPolicy.subnets для работы ALB
# Также используются для размещения Kubernetes master и node groups
resource "yandex_vpc_subnet" "k8s_nodes_ru_central1_a" {
  name           = "k8s-nodes-ru-central1-a"
  description    = "K8s nodes subnet for ALB and K8s in ru-central1-a"
  network_id     = data.yandex_vpc_network.default.id
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["10.20.0.0/24"]
  route_table_id = yandex_vpc_route_table.gateway.id
}

resource "yandex_vpc_subnet" "k8s_nodes_ru_central1_b" {
  name           = "k8s-nodes-ru-central1-b"
  description    = "K8s nodes subnet for ALB and K8s in ru-central1-b"
  network_id     = data.yandex_vpc_network.default.id
  zone           = "ru-central1-b"
  v4_cidr_blocks = ["10.20.1.0/24"]
  route_table_id = yandex_vpc_route_table.gateway.id
}

resource "yandex_vpc_subnet" "k8s_nodes_ru_central1_d" {
  name           = "k8s-nodes-ru-central1-d"
  description    = "K8s nodes subnet for ALB and K8s in ru-central1-d"
  network_id     = data.yandex_vpc_network.default.id
  zone           = "ru-central1-d"
  v4_cidr_blocks = ["10.20.2.0/24"]
  route_table_id = yandex_vpc_route_table.gateway.id
}

