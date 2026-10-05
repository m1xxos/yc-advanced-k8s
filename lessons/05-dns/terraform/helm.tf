# Install namespaces Helm chart
resource "helm_release" "namespaces" {
  name             = "namespaces"
  chart            = "${path.module}/../../../helm-charts/namespaces"
  namespace        = "default"
  create_namespace = false # Use default namespace
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
              id                 = yandex_iam_service_account_key.alb_controller_key.id
              service_account_id = yandex_iam_service_account_key.alb_controller_key.service_account_id
              created_at         = yandex_iam_service_account_key.alb_controller_key.created_at
              key_algorithm      = yandex_iam_service_account_key.alb_controller_key.key_algorithm
              public_key         = yandex_iam_service_account_key.alb_controller_key.public_key
              private_key        = yandex_iam_service_account_key.alb_controller_key.private_key
            }))
          }
        }
      }
    })
  ]
  depends_on = [
    module.kube,
    helm_release.namespaces
  ]
}

# Install gwin resources (YCCertificate and Gateway) Helm chart
resource "helm_release" "gwin_resources" {
  name             = "gwin-resources"
  chart            = "${path.module}/../../../helm-charts/gwin-resources"
  namespace        = local.namespaces.gwin_controller.name
  create_namespace = false
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
    })
  ]

  depends_on = [
    module.kube,
    helm_release.namespaces,
    helm_release.grafana-operator,
  ]
}

# Install netshoot Helm chart
resource "helm_release" "netshoot" {
  name             = "netshoot"
  chart            = "${path.module}/../../../helm-charts/netshoot"
  namespace        = local.namespaces.application.name
  create_namespace = false
  upgrade_install  = false

  values = [file("./helm-values/netshoot.yaml")]

  depends_on = [
    module.kube,
    helm_release.namespaces
  ]
}

# Install k6 Helm chart
resource "helm_release" "k6" {
  name             = "k6"
  chart            = "${path.module}/../../../helm-charts/k6"
  namespace        = local.namespaces.application.name
  create_namespace = false
  upgrade_install  = false

  values = [file("./helm-values/k6.yaml")]

  depends_on = [
    module.kube,
    helm_release.namespaces
  ]
}

# Install podinfo Helm chart
resource "helm_release" "podinfo" {
  name             = "podinfo"
  chart            = "${path.module}/../../../helm-charts/podinfo"
  namespace        = local.namespaces.application.name
  create_namespace = false
  upgrade_install  = false

  values = [file("./helm-values/podinfo.yaml")]

  depends_on = [
    module.kube,
    helm_release.namespaces
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
