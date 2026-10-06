# DNS recordset for podinfo subdomain
# Creates A record pointing to the Gateway static IP address
resource "yandex_dns_recordset" "podinfo" {
  zone_id = data.yandex_dns_zone.zone.id
  name    = "podinfo.${var.dns_zone}."
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

