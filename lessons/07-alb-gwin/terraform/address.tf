# Static public IP address for Gateway
resource "yandex_vpc_address" "gwin_gateway" {
  name = "gwin-gateway-static-ip-${local.dns_zone_name}-b"

  external_ipv4_address {
    # zone_id = var.k8s_master_zone
    zone_id = "ru-central1-b"
  }
}

