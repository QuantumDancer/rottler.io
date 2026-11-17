# ==============================================================================
# Public DNS entry points
# ==============================================================================
#
# The alias records live with the distribution rather than in the dns module
# because they are meaningless without one: they point at a specific
# distribution's domain, so their lifecycle is the site's, not the zone's. The
# zone itself is passed in as `zone_id` and written through the `aws.dns`
# provider, so it can belong to a different account from the distribution.
#
# One A and one AAAA record per name in `aliases`, keyed by name, and nothing
# else. That ties a record's existence to the distribution actually answering
# for the name: an empty `aliases` writes no records, which is what lets a site
# stand up before its names are moved onto it (the website root starts like
# that, while hand-copied records for the legacy distribution still hold the
# apex and www). It is also why `domain_name` gets no record of its own.
#
# AAAA because the distribution has IPv6 on: without it, IPv6-only clients
# can't reach a site CloudFront is already serving over IPv6.
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record#alias-record
resource "aws_route53_record" "website_a" {
  provider = aws.dns
  for_each = toset(var.aliases)

  zone_id = var.zone_id
  name    = each.key
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "website_aaaa" {
  provider = aws.dns
  for_each = toset(var.aliases)

  zone_id = var.zone_id
  name    = each.key
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = true
  }
}
