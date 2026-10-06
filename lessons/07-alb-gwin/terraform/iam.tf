# IAM service account for the ALB controller gwin
resource "yandex_iam_service_account" "alb_controller" {
  name        = "alb-controller"
  description = "Service account for the ALB controller gwin"
}

# Role: alb.editor - для создания необходимых ресурсов Application Load Balancer
resource "yandex_resourcemanager_folder_iam_member" "alb_controller_alb_editor" {
  folder_id = local.folder_id
  role      = "alb.editor"
  member    = "serviceAccount:${yandex_iam_service_account.alb_controller.id}"
}

# Role: vpc.publicAdmin - для управления внешней сетевой связностью
resource "yandex_resourcemanager_folder_iam_member" "alb_controller_vpc_admin" {
  folder_id = local.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.alb_controller.id}"
}

# Role: certificate-manager.certificates.downloader - для доступа к облачным сертификатам в Certificate Manager
resource "yandex_resourcemanager_folder_iam_member" "alb_controller_cert_downloader" {
  folder_id = local.folder_id
  role      = "certificate-manager.certificates.downloader"
  member    = "serviceAccount:${yandex_iam_service_account.alb_controller.id}"
}

# Role: certificate-manager.editor - для сертификатов кластера Managed Service for Kubernetes
resource "yandex_resourcemanager_folder_iam_member" "alb_controller_cert_editor" {
  folder_id = local.folder_id
  role      = "certificate-manager.editor"
  member    = "serviceAccount:${yandex_iam_service_account.alb_controller.id}"
}

# Role: compute.viewer - для использования узлов кластера Managed Service for Kubernetes в целевых группах L7-балансировщика
resource "yandex_resourcemanager_folder_iam_member" "alb_controller_compute_viewer" {
  folder_id = local.folder_id
  role      = "compute.viewer"
  member    = "serviceAccount:${yandex_iam_service_account.alb_controller.id}"
}

# Role: k8s.viewer - чтобы контроллер мог определить, в какой сети нужно развернуть L7-балансировщик
resource "yandex_resourcemanager_folder_iam_member" "alb_controller_k8s_viewer" {
  folder_id = local.folder_id
  role      = "k8s.viewer"
  member    = "serviceAccount:${yandex_iam_service_account.alb_controller.id}"
}

# Role: logging.writer - опционально, для записи логов L7-балансировщика в Yandex Cloud Logging (если в Gateway указана лог-группа)
resource "yandex_resourcemanager_folder_iam_member" "alb_controller_logging_writer" {
  folder_id = local.folder_id
  role      = "logging.writer"
  member    = "serviceAccount:${yandex_iam_service_account.alb_controller.id}"
}

# Create a secret for the service account for the ALB controller gwin
resource "yandex_iam_service_account_key" "alb_controller_key" {
  service_account_id = yandex_iam_service_account.alb_controller.id
  description        = "Key for the ALB controller gwin"
}