provider "yandex" {}

# Helm provider configured to use the created cluster
provider "helm" {
  kubernetes = {
    host                   = module.kube.external_v4_endpoint
    cluster_ca_certificate = module.kube.cluster_ca_certificate
    token                  = data.yandex_client_config.client.iam_token
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
