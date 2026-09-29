terraform {
  required_version = ">= 1.0.0"
  backend "s3" {
    endpoint                    = "https://storage.yandexcloud.net"
    region                      = "ru-central1"
    bucket                      = var.bucket
    key                         = "yc-advanced-k8s.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_lockfile                = true
  }
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.101.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.26.0"
    }
  }
}
