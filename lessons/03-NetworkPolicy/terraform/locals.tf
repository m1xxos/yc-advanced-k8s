locals {
  k8s_network_name       = "default"
  # k8s_master_subnet_name = "${local.k8s_network_name}-${get_env(YC_ZONE, "null")}"
  k8s_master_subnet_name = "${local.k8s_network_name}-${var.k8s_master_zone}"

  # Map of zone -> k8s nodes subnet ID (lesson 03)
  k8s_nodes_subnets = {
    "ru-central1-a" = yandex_vpc_subnet.k8s_nodes_ru_central1_a.id
    "ru-central1-b" = yandex_vpc_subnet.k8s_nodes_ru_central1_b.id
    "ru-central1-d" = yandex_vpc_subnet.k8s_nodes_ru_central1_d.id
  }
}