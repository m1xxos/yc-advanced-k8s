# Internet Gateway for k8s nodes subnets
# Интернет-шлюз для подсетей k8s-nodes
# Документация: https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_gateway
resource "yandex_vpc_gateway" "k8s_nodes" {
  name = "k8s-lesson-03-egress-gateway"

  # Shared egress gateway (NAT) for outbound traffic from subnets without public IPs
  shared_egress_gateway {}
}

# Route table for k8s nodes subnets
# Таблица маршрутизации для подсетей k8s-nodes
# Документация: https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_route_table
resource "yandex_vpc_route_table" "k8s_nodes" {
  name        = "k8s-lesson-03-egress-route-table"
  description = "Route table for k8s-nodes subnets (lesson 03)"
  network_id  = data.yandex_vpc_network.default.id

  # Default route to the Internet via the gateway
  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.k8s_nodes.id
  }
}

# K8s nodes subnets (lesson 03)
# Подсети для Kubernetes nodes (урок 03). Используем отдельные CIDR, чтобы не конфликтовать с другими уроками.
# Документация: https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_subnet
resource "yandex_vpc_subnet" "k8s_nodes_ru_central1_a" {
  name           = "k8s-nodes-lesson-03-ru-central1-a"
  description    = "K8s nodes subnet (lesson 03) in ru-central1-a"
  network_id     = data.yandex_vpc_network.default.id
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["10.21.0.0/24"]
  route_table_id = yandex_vpc_route_table.k8s_nodes.id
}

resource "yandex_vpc_subnet" "k8s_nodes_ru_central1_b" {
  name           = "k8s-nodes-lesson-03-ru-central1-b"
  description    = "K8s nodes subnet (lesson 03) in ru-central1-b"
  network_id     = data.yandex_vpc_network.default.id
  zone           = "ru-central1-b"
  v4_cidr_blocks = ["10.21.1.0/24"]
  route_table_id = yandex_vpc_route_table.k8s_nodes.id
}

resource "yandex_vpc_subnet" "k8s_nodes_ru_central1_d" {
  name           = "k8s-nodes-lesson-03-ru-central1-d"
  description    = "K8s nodes subnet (lesson 03) in ru-central1-d"
  network_id     = data.yandex_vpc_network.default.id
  zone           = "ru-central1-d"
  v4_cidr_blocks = ["10.21.2.0/24"]
  route_table_id = yandex_vpc_route_table.k8s_nodes.id
}


