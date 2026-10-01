data "yandex_vpc_network" "default" {
  name = local.k8s_network_name
}

data "yandex_vpc_subnet" "k8s_master_subnet" {
  name = local.k8s_master_subnet_name
}