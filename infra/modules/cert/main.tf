# ==============================================================================
# ACM certificate and its DNS validation records
# ==============================================================================
#
# CloudFront only accepts viewer certificates issued in us-east-1, which is why
# the whole stack pins that region rather than this module doing anything
# region-aware.
#
# `zone_id` is an input rather than a lookup because of where the account
# restructure is heading: the apex zone will live in a shared-services account
# while the certificate lives in prod. Taking the zone as a plain input means
# that split becomes a wiring change (a cross-account provider alias supplied by
# the caller) instead of a rewrite of this module.

resource "aws_acm_certificate" "website_cert" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  # A certificate cannot be deleted while a distribution still references it, so
  # any change that forces replacement must mint the new cert before releasing
  # the old one — otherwise the distribution is wedged mid-apply.
  lifecycle {
    create_before_destroy = true
  }
}

# The CNAME records ACM checks to prove domain control.
#
# The for_each key is `dvo.domain_name` — keep it exactly as-is. The migration's
# `moved` block carries instance keys across verbatim, so changing the key
# expression would turn a rename into a destroy-and-create of the validation
# records, and a cert whose validation records vanish eventually goes INVALID.
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation#dns-validation-with-route-53
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.website_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

# Intentionally omitted: `aws_acm_certificate_validation`. The legacy stack never
# had one, and introducing it here would be a resource *add* inside a migration
# whose entire safety gate is "0 add, 0 replace". ACM validates from the records
# above regardless; that resource exists only to make Terraform *block* until
# validation completes. Worth adding in a later commit if a first-apply race
# between certificate issuance and the distribution ever actually bites.
