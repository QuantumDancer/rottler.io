variable "domain_name" {
  description = "Primary domain the site is served from, e.g. dev.rottler.io. Also forms the website bucket name and the CloudFront log prefix."
  type        = string
  nullable    = false
}

# Distinct from `domain_name` on purpose: the log bucket is per-account rather
# than per-site, so its name must not move when the site's domain does.
variable "project_name" {
  description = "Short project slug used to name the shared CloudFront log bucket"
  type        = string
  nullable    = false
}

# The legacy config computed this from a `var.environment == "prod"` conditional.
# Passing it explicitly keeps environment names out of the module, which is what
# lets `envs/prod` later reuse it with the apex and www names.
variable "aliases" {
  description = "CNAMEs served by the distribution, each also given A and AAAA alias records in `zone_id`. Every entry must be covered by the certificate. Empty means no aliases and no records."
  type        = list(string)
  nullable    = false
}

variable "acm_certificate_arn" {
  description = "Viewer certificate for the distribution. Must be issued in us-east-1."
  type        = string
  nullable    = false
}

variable "zone_id" {
  description = "Hosted zone the alias records are written into, through the `aws.dns` provider"
  type        = string
  nullable    = false
}
