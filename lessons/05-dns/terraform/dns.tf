# Creates A record pointing to the Gateway static IP address
resource "yandex_dns_recordset" "grafana" {
  zone_id = data.yandex_dns_zone.zone.id
  name    = "grafana-${local.lesson_number}.${var.dns_zone}."
  type    = "A"
  ttl     = 300
  data    = [yandex_vpc_address.gwin_gateway.external_ipv4_address[0].address]

  depends_on = [
    yandex_vpc_address.gwin_gateway
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_dns_record" "grafana" {
  zone_id = var.cloudflare_zone_id
  name    = "grafana-${local.lesson_number}.${var.dns_zone}."
  type    = "A"
  ttl     = 300
  content = yandex_vpc_address.gwin_gateway.external_ipv4_address[0].address

  depends_on = [
    yandex_vpc_address.gwin_gateway
  ]

  lifecycle {
    create_before_destroy = true
  }
}
