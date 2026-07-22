variable "domain_name" {
  description = "Primary subject of the certificate, e.g. dev.rottler.io"
  type        = string
  nullable    = false
}

# The legacy config derived this from a `var.environment == "prod"` conditional.
# Per-env roots now pass it explicitly, so the module stays free of environment
# names — which is what lets `envs/prod` reuse it unchanged later.
variable "subject_alternative_names" {
  description = "Additional names on the certificate. Empty for single-name environments like dev."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "zone_id" {
  description = "Hosted zone the DNS validation records are written into"
  type        = string
  nullable    = false
}
