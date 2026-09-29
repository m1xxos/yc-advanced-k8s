resource "yandex_cm_certificate" "le-certificate" {
  name    = "le-certificate-${local.dns_zone_name}"
  domains = [
    var.dns_zone,
    "*.${var.dns_zone}"
  ]

  managed {
    challenge_type = "DNS_CNAME"
    challenge_count = 1
  }
}

resource "cloudflare_dns_record" "le-cert" {
  count   = yandex_cm_certificate.le-certificate.managed[0].challenge_count
  zone_id = var.cloudflare_zone_id
  name    = yandex_cm_certificate.le-certificate.challenges[count.index].dns_name
  type    = yandex_cm_certificate.le-certificate.challenges[count.index].dns_type
  content = yandex_cm_certificate.le-certificate.challenges[count.index].dns_value
  ttl     = 60
}
