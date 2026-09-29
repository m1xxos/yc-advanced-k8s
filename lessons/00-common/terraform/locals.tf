locals {
    # DNS zone name (with dots replaced by dashes, trailing dash removed)
  dns_zone_name = replace(trimsuffix(var.dns_zone, "."), ".", "-")
}
