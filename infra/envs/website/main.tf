# ==============================================================================
# website: rottler.io's final home
# ==============================================================================
#
# The main root of the website account: certificate, buckets, distribution,
# and the site's own records in the rottler.io zone. Deploy CI plans and
# applies it. The identities CI assumes live in `website-bootstrap`
# (docs/adr/0003-each-account-has-a-locally-applied-bootstrap-root.md).
#
# The zone lives in the shared-services account, not here. Everything Route 53
# goes through the `aws.dns` provider, which assumes a role there that can write
# only the apex/www alias records and `_*` validation CNAMEs.
#
# The distribution starts with no aliases, so the root writes no apex/www
# records: until the alias move, the legacy distribution holds both names, and
# CloudFront won't let two distributions claim the same alias. The alias move
# adds them to `aliases` below, and static-site writes their records with them.
# The cert covers both from the start.

terraform {
  # 1.10 is the floor for S3 native locking (`use_lockfile`).
  required_version = "~> 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
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

  default_tags {
    tags = local.default_tags
  }
}

# Assumes `website-dns` (applies) or `website-dns-read` (plans in CI) in
# shared-services. The ARN comes from `var.dns_role_arn` instead of being
# committed, since it names the shared-services account.
provider "aws" {
  alias  = "dns"
  region = "us-east-1"

  assume_role {
    role_arn     = var.dns_role_arn
    session_name = "website-terraform"
  }

  default_tags {
    tags = local.default_tags
  }
}

locals {
  domain_name = "rottler.io"

  # Names the CloudFront log bucket, as on dev.
  project_name = "rottler-io"

  default_tags = {
    managed-by = "terraform"
    repository = "rottler.io"
    stack      = "website"
  }
}

# Looked up by name, so no zone ID is committed. The zone is shared-services'
# to create and delete. This root only reads it.
data "aws_route53_zone" "rottler_io" {
  provider = aws.dns

  name = local.domain_name
}

# ==============================================================================
# Module wiring: cert → site
# ==============================================================================

# The apex plus `*.rottler.io`, so www (and any later subdomain) is covered
# without reissuing. Both names validate through one shared CNAME.
module "cert" {
  source = "../../modules/cert"

  providers = {
    aws     = aws
    aws.dns = aws.dns
  }

  domain_name               = local.domain_name
  subject_alternative_names = ["*.${local.domain_name}"]
  zone_id                   = data.aws_route53_zone.rottler_io.zone_id
}

module "site" {
  source = "../../modules/static-site"

  providers = {
    aws     = aws
    aws.dns = aws.dns
    random  = random
  }

  domain_name  = local.domain_name
  project_name = local.project_name

  # Empty until the alias move, which sets it to the apex and www (see the
  # header).
  aliases = []

  acm_certificate_arn = module.cert.certificate_arn
  zone_id             = data.aws_route53_zone.rottler_io.zone_id
}
