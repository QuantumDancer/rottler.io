# ==============================================================================
# Public DNS entry point
# ==============================================================================
#
# The alias A record lives with the distribution rather than in the dns module
# because it is meaningless without one: it points at a specific distribution's
# domain, so its lifecycle is the site's, not the zone's. The zone itself is
# passed in as `zone_id`, which is what lets the record be written into a zone
# owned by a different account after the restructure.
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record#alias-record
resource "aws_route53_record" "website" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = true
  }
}
