locals {
  # lesson number
  lesson_number = "05"
  # lesson number integer
  lesson_number_int = tonumber(local.lesson_number)
  # Folder ID for the ALB controller
  folder_id = data.yandex_client_config.client.folder_id
  # Network name for the ALB controller
  k8s_network_name = "default"
  # k8s_master_subnet_name = "${local.k8s_network_name}-${get_env(YC_ZONE, "null")}"
  k8s_master_subnet_name = "${local.k8s_network_name}-${var.k8s_master_zone}"

  # DNS zone name (with dots replaced by dashes, trailing dot removed)
  dns_zone_name = replace(trimsuffix(var.dns_zone, "."), ".", "-")

  # Gateway name
  gwin_gateway_name = "gwin-gateway-${local.lesson_number}"
  # Map of zone to k8s nodes subnet ID

  # Map of zone -> k8s nodes subnet ID (lesson 05)
  k8s_nodes_subnets = {
    "ru-central1-a" = yandex_vpc_subnet.k8s_nodes_ru_central1_a.id
    "ru-central1-b" = yandex_vpc_subnet.k8s_nodes_ru_central1_b.id
    "ru-central1-d" = yandex_vpc_subnet.k8s_nodes_ru_central1_d.id
  }

  # Namespaces
  namespaces = {
    gwin_controller = {
      name = "gwin-system"
      labels = {
        project = "gwin"
      }
    }
    application = {
      name = "demo"
      labels = {
        project = "demo"
      }
    }
    monitoring = {
      name = "monitoring"
      labels = {
        project        = "monitoring"
        gateway-access = "enabled"
      }
    }
  }
}
