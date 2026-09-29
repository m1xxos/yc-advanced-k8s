resource "yandex_dns_zone" "zone" {
  name        = local.dns_zone_name
  description = "DNS public zone"
  zone        = "${var.dns_zone}."

  public = true
}
