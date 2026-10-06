###
# Общие переменные
###

variable "k8s_master_zone" {
  description = "k8s master zone"
  default = "ru-central1-a"
}

variable "dns_zone" {
  description = "DNS zone name (must be a valid FQDN without trailing dot)"
  type        = string

  validation {
    condition = can(regex("^([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$", var.dns_zone))
    error_message = "DNS zone must be a valid FQDN without trailing dot (e.g., 'example.com')."
  }
}
