# Install namespaces Helm chart
resource "helm_release" "namespaces" {
  name             = "namespaces"
  chart            = "${path.module}/../../../helm-charts/namespaces"
  namespace        = "default"
  create_namespace = false  # Use default namespace
  upgrade_install  = false

  values = [
    templatefile("${path.module}/helm-values/namespaces.yaml", {
      namespaces = local.namespaces
    })
  ]

  depends_on = [
    module.kube
  ]
}

# Install gwin ALB controller Helm chart
resource "helm_release" "gwin_controller" {
  name             = "gwin"
  chart            = "${path.module}/../../../helm-charts/gwin-chart"
  namespace        = local.namespaces.gwin_controller.name
  create_namespace = false
  upgrade_install  = false

  values = [
    yamlencode({
      controller = {
        folderId = local.folder_id
        ycServiceAccount = {
          secret = {
            value = tostring(jsonencode({
              id                = yandex_iam_service_account_key.alb_controller_key.id
              service_account_id = yandex_iam_service_account_key.alb_controller_key.service_account_id
              created_at        = yandex_iam_service_account_key.alb_controller_key.created_at
              key_algorithm     = yandex_iam_service_account_key.alb_controller_key.key_algorithm
              public_key        = yandex_iam_service_account_key.alb_controller_key.public_key
              private_key       = yandex_iam_service_account_key.alb_controller_key.private_key
            }))
          }
        }
      }
    })
  ]

  depends_on = [
    module.kube,
    helm_release.namespaces,
    yandex_resourcemanager_folder_iam_member.alb_controller_alb_editor,
    yandex_resourcemanager_folder_iam_member.alb_controller_cert_downloader,
    yandex_resourcemanager_folder_iam_member.alb_controller_cert_editor,
    yandex_resourcemanager_folder_iam_member.alb_controller_compute_viewer,
    yandex_resourcemanager_folder_iam_member.alb_controller_k8s_viewer,
    yandex_resourcemanager_folder_iam_member.alb_controller_logging_writer,
    yandex_resourcemanager_folder_iam_member.alb_controller_vpc_admin,
  ]
}

# Install gwin resources (YCCertificate and Gateway) Helm chart
resource "helm_release" "gwin_resources" {
  name             = "gwin-resources"
  chart            = "${path.module}/../../../helm-charts/gwin-resources"
  namespace        = local.namespaces.gwin_controller.name
  create_namespace = false  # Namespace already created by gwin chart
  upgrade_install  = false

  values = [
    templatefile("${path.module}/helm-values/gwin-resources.yaml", {
      dns_zone_name                  = local.dns_zone_name
      certificate_id                 = data.yandex_cm_certificate.le-certificate.id
      gwin_gateway_name              = local.gwin_gateway_name
      dns_zone                       = var.dns_zone
      gwin_controller_namespace_name = local.namespaces.gwin_controller.name
      gateway_ip_address             = yandex_vpc_address.gwin_gateway.external_ipv4_address[0].address
      log_group_id                   = data.yandex_logging_group.default.id
      podinfo_namespace_labels       = local.namespaces.podinfo.labels
    })
  ]

  depends_on = [
    time_sleep.wait_for_alb_deletion,
    helm_release.namespaces
  ]
}

# Install kube-prometheus-stack Helm chart
resource "helm_release" "kube-prometheus-stack" {
  name             = "kube-prometheus-stack"
  chart            = "${path.module}/../../../helm-charts/kube-prometheus-stack"
  namespace        = local.namespaces.monitoring.name
  create_namespace = false
  upgrade_install  = false

  values = [file("./helm-values/kube-prometheus-stack.yaml")]

  depends_on = [
    module.kube,
    helm_release.namespaces
  ]
}

# Install Grafana Operator Helm chart
resource "helm_release" "grafana-operator" {
  name             = "grafana-operator"
  chart            = "${path.module}/../../../helm-charts/grafana-operator"
  namespace        = local.namespaces.monitoring.name
  create_namespace = false
  upgrade_install  = false

  values = [file("./helm-values/grafana-operator.yaml")]

  depends_on = [
    module.kube,
    helm_release.namespaces
  ]
}

# Install Grafana Instance Helm chart
resource "helm_release" "grafana-instance" {
  name             = "grafana-instance"
  chart            = "${path.module}/../../../helm-charts/grafana-instance"
  namespace        = local.namespaces.monitoring.name
  create_namespace = false
  upgrade_install  = false

  values = [
    templatefile("${path.module}/helm-values/grafana-instance.yaml", {
      dns_zone                       = var.dns_zone
      lesson_number                  = local.lesson_number
      gwin_gateway_name              = local.gwin_gateway_name
      gwin_controller_namespace_name = local.namespaces.gwin_controller.name
      k8s_nodes_network_dashboard_json = base64encode(file("${path.module}/helm-values/grafana-dashboards/k8s-nodes-network.json"))
    })
  ]

  depends_on = [
    module.kube,
    helm_release.namespaces,
    helm_release.grafana-operator,
    helm_release.gwin_resources,
    time_sleep.wait_for_alb_deletion,
  ]
}

resource "time_sleep" "wait_for_alb_deletion" {
  # This duration defines how long Terraform will wait during the destroy operation
  # before moving on to dependent resources.
  destroy_duration = "120s" # Wait 2 minutes during destroy

  # Explicit dependency on the resource that needs time before destroy
  depends_on = [
    helm_release.gwin_controller,
    yandex_vpc_address.gwin_gateway,
  ]
}