output "kube_cluster_id" {
  description = "Kubernetes cluster ID."
  value       = try(module.kube.cluster_id, null)
}

output "kube_cluster_name" {
  description = "Kubernetes cluster name."
  value       = try(module.kube.cluster_name, null)
}

output "external_cluster_cmd_str" {
  description = "Connection string to external Kubernetes cluster."
  value       = try(module.kube.external_cluster_cmd, null)
}

output "internal_cluster_cmd_str" {
  description = "Connection string to internal Kubernetes cluster."
  value       = try(module.kube.internal_cluster_cmd, null)
}

output "node_account_name" {
  description = "IAM node account name"
  value       = module.kube.node_account_name
}

output "service_account_name" {
  description = "IAM service account name"
  value       = module.kube.service_account_name
}

# output "gateway_ip" {
#   description = "Gateway static IP address"
#   value       = yandex_vpc_address.gwin_gateway.external_ipv4_address[0].address
# }

# output "podinfo_dns_name" {
#   description = "Podinfo DNS name"
#   value       = "podinfo.${var.dns_zone}"
# }

# output "podinfo_url" {
#   description = "Podinfo application URL"
#   value       = "https://podinfo.${var.dns_zone}"
# }

output "grafana_dns_name" {
  description = "Grafana DNS name"
  value       = "grafana-${local.lesson_number}.${var.dns_zone}"
}

output "grafana_url" {
  description = "Grafana application URL"
  value       = "https://grafana-${local.lesson_number}.${var.dns_zone}"
}
