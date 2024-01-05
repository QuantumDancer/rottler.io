resource "aws_acm_certificate" "website_cert" {
  # dev:  dev.rottler.io
  # prod: rottler.io
  domain_name = var.environment == "prod" ? var.top_level_domain : local.domain_name
  # dev:  []
  # prod: www.rottler.io, prod.rottler.io
  subject_alternative_names = var.environment == "prod" ? ["www.${var.top_level_domain}", local.domain_name] : []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
