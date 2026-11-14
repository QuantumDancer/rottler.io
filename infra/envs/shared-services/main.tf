# ==============================================================================
# shared-services: the consolidated rottler.io zone
# ==============================================================================
#
# The main root of the shared-services account. Holds the one public zone for
# rottler.io, the records that aren't the website's, the zone's DNSSEC signing
# (dnssec.tf) and the account's alerting (alerts.tf). Applied locally; the
# identities other accounts assume live in `shared-services-bootstrap`
# (docs/adr/0003-each-account-has-a-locally-applied-bootstrap-root.md).
#
# Creating the zone is harmless while the registrar still delegates to the
# management account's zone: nothing resolves through it until the cutover's
# NS switch.
#
# Deliberately absent:
# - apex/www aliases and ACM validation records: the website root writes those
#   through the `website-dns` role.
# - the `dev.` and `prod.` delegations: dev.rottler.io is retired at the NS
#   switch and prod.rottler.io is dropped.
# - the DS record at .io: it lands in a follow-up PR, applied only once the NS
#   switch has fully propagated. That PR boundary is the timing gate.

terraform {
  # 1.10 is the floor for S3 native locking (`use_lockfile`).
  required_version = "~> 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# us-east-1 is required, not chosen: DNSSEC KSKs only accept KMS keys there,
# and Route 53 publishes its CloudWatch metrics only there.
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      managed-by = "terraform"
      repository = "rottler.io"
      stack      = "shared-services"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  domain_name = "rottler.io"
}

module "dns" {
  source = "../../modules/dns"

  domain_name = local.domain_name
}

# Route 53 creates the apex NS record itself, at TTL 172800. Lowered to 300
# for the cutover so a rollback of the NS switch isn't stuck behind a two-day
# cache. `allow_overwrite` adopts the existing record instead of failing on it.
#
# TODO: raised back to 172800 by the same follow-up PR that publishes the DS.
resource "aws_route53_record" "apex_ns" {
  zone_id         = module.dns.zone_id
  name            = local.domain_name
  type            = "NS"
  ttl             = 300
  records         = module.dns.name_servers
  allow_overwrite = true
}
