variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_zone_id" {
  type = string
  sensitive = true
}

variable "dns_zone" {
  description = "DNS zone name (must be a valid FQDN without trailing dot)"
  type        = string

  validation {
    condition = can(regex("^([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$", var.dns_zone))
    error_message = "DNS zone must be a valid FQDN without trailing dot (e.g., 'example.com')."
  }
}
