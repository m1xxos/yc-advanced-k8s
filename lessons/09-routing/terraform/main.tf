module "kube" {
  source = "../../../modules/terraform-yc-kubernetes"

  cluster_name = "k8s-${local.lesson_number}"

  network_id = data.yandex_vpc_network.default.id
  cluster_ipv4_range = "10.10.0.0/16"
  service_ipv4_range = "172.17.0.0/16"
  enable_cilium_policy = true

  master_locations = [
    {
      zone      = var.k8s_master_zone
      # Используем существующую подсеть default-${var.k8s_master_zone} для master
      # если будем переносить master в другую зону - нужно будет использовать local.k8s_nodes_subnets[var.k8s_master_zone]
      # subnet_id = local.k8s_nodes_subnets[var.k8s_master_zone]
      subnet_id = data.yandex_vpc_subnet.k8s_master_subnet.id
    }
  ]

  node_groups = {
    "yc-k8s-ng-${local.lesson_number}-01" = {
      description = "Kubernetes nodes group lesson-${local.lesson_number}-01 with fixed size scaling"
      node_cores    = 2
      node_memory   = 4
      fixed_scale = {
        size = 4
      }
      nat = false
      # Используем k8s-nodes подсети для node groups
      node_locations = [
        for zone, subnet_id in local.k8s_nodes_subnets : {
          zone      = zone
          subnet_id = subnet_id
        }
      ]
    }
  }
}
