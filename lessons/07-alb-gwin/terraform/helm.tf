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

# Install Argo Rollouts Helm chart
resource "helm_release" "argo_rollouts" {
  name             = "argo-rollouts"
  chart            = "${path.module}/../../../helm-charts/argo-rollouts"
  namespace        = local.namespaces.argo_rollouts.name
  create_namespace = false
  upgrade_install  = false

  values = [
    templatefile("${path.module}/helm-values/argo-rollouts.yaml", {})
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
    helm_release.gwin_controller,
    helm_release.namespaces,
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
