data "yandex_client_config" "client" {}

data "yandex_vpc_network" "default" {
  name = local.k8s_network_name
}

data "yandex_vpc_subnet" "k8s_master_subnet" {
  name = local.k8s_master_subnet_name
}

# Default subnets - могут использоваться для ALB/HTTPRoute ресурсов
# если не потребуется - удалить
data "yandex_vpc_subnet" "default_ru_central1_a" {
  name = "default-ru-central1-a"
}

data "yandex_vpc_subnet" "default_ru_central1_b" {
  name = "default-ru-central1-b"
}

data "yandex_vpc_subnet" "default_ru_central1_d" {
  name = "default-ru-central1-d"
}


data "yandex_kubernetes_cluster" "cluster" {
  cluster_id = module.kube.cluster_id
}

# DNS zone - может использоваться для создания DNS записей для ALB/HTTPRoute
# если не потребуется - удалить
data "yandex_dns_zone" "zone" {
  name = local.dns_zone_name
}

# TLS certificate - может использоваться для HTTPS в ALB/HTTPRoute
# если не потребуется - удалить
data "yandex_cm_certificate" "le-certificate" {
  name = "le-certificate-${local.dns_zone_name}"
}

# Logging group - может использоваться для логирования ALB
# если не потребуется - удалить
data "yandex_logging_group" "default" {
  name = "default"
}
