module "kube" {
  source = "../../../modules/terraform-yc-kubernetes"

  cluster_name = "k8s-${local.lesson_number}"

  network_id           = data.yandex_vpc_network.default.id
  cluster_ipv4_range   = "10.10.0.0/16"
  service_ipv4_range   = "172.17.0.0/16"
  enable_cilium_policy = true

  master_locations = [
    {
      zone      = var.k8s_master_zone
      subnet_id = data.yandex_vpc_subnet.k8s_master_subnet.id
    }
  ]

  node_groups = {
    "k8s-${local.lesson_number}-nodes-01" = {
      description = "Kubernetes nodes group lesson-${local.lesson_number}-01 with fixed size scaling"
      fixed_scale = {
        size = 1
      }
      nat = false

      # Используем подсети k8s-nodes (урок 05)
      node_locations = [
        for zone in ["ru-central1-a", "ru-central1-b", "ru-central1-d"] : {
          zone      = zone
          subnet_id = local.k8s_nodes_subnets[zone]
        }
      ]
    }
  }
}
