# ==============================================================================
# dev.rottler.io — interim home of the rebuilt Astro site
# ==============================================================================
#
# This root adopts the Cloud Resume Challenge-era dev stack: same AWS account,
# same state, same resources, restructured into modules. The visitor-counter
# backend (Lambda / API Gateway / DynamoDB) is deliberately absent from the
# config, which is how it gets destroyed on the first apply.
#
# Directory-per-environment rather than workspaces: the environments this grows
# into live in *different accounts with different resource sets* — shared
# services will hold only the zone, prod only the cert and site — so the roots
# have to be able to diverge. They will be new directories calling these same
# modules.
#
# Prod is not here and never will be. The legacy repo remains the operational
# tool for rottler.io until the www migration, so this repo's blast radius on
# prod is structurally zero: it contains no prod root and no prod backend config.

terraform {
  # 1.9 rather than the legacy 1.6 floor; the state format is unchanged between
  # them, so the legacy checkout can still read state written from here during
  # the rollback window.
  required_version = "~> 1.9"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # The same major as every other root. Until the 6.x upgrade this root
      # stayed on the legacy lockfile's 5.x, so the migration plan's "0 add,
      # 0 replace" check could not pick up provider behaviour changes. The
      # upgrade was then gated on its own before and after plans.
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# us-east-1 is not a preference: CloudFront only accepts viewer certificates
# issued there.
provider "aws" {
  region = "us-east-1"

  # Carried over from the legacy provider config unchanged. These tags are on
  # every existing resource, so dropping or renaming either key would show up as
  # a tag diff on all 18 of them during the migration plan.
  default_tags {
    tags = {
      created-by  = "terraform"
      environment = "dev"
    }
  }
}

# ==============================================================================
# Module wiring: dns → cert → site
# ==============================================================================

module "dns" {
  source = "../../modules/dns"

  domain_name = local.domain_name
}

module "cert" {
  source = "../../modules/cert"

  domain_name = local.domain_name
  zone_id     = module.dns.zone_id

  # dev serves exactly one name. prod will pass the apex and www here.
  subject_alternative_names = []
}

module "site" {
  source = "../../modules/static-site"

  domain_name         = local.domain_name
  project_name        = local.project_name
  aliases             = [local.domain_name]
  acm_certificate_arn = module.cert.certificate_arn
  zone_id             = module.dns.zone_id
}

locals {
  domain_name = "dev.rottler.io"

  # Names the shared CloudFront log bucket. Must stay "rottler-io": it is baked
  # into the existing bucket's name, and a change means a new bucket.
  project_name = "rottler-io"
}
