# ==============================================================================
# Delegated public hosted zone
# ==============================================================================
#
# Today this holds the `dev.rottler.io` subdomain zone, delegated from the apex
# `rottler.io` zone that the legacy prod stack still owns. The zone name is
# load-bearing: recreating the zone mints a fresh set of nameservers, which
# silently breaks that delegation until the parent's NS record is updated by
# hand. Any plan that shows this resource being replaced is a stop condition.
#
# The module is deliberately dev-agnostic. At the account restructure,
# `envs/shared-services` calls this same module to hold the consolidated apex
# zone, and the cert/static-site modules keep taking `zone_id` as an input.

resource "aws_route53_zone" "website" {
  name = var.domain_name
}
