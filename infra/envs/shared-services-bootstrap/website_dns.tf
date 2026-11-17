# ==============================================================================
# Cross-account DNS roles for the website root
# ==============================================================================
#
# The website root creates its own apex/www alias records and ACM validation
# records, so the site stays one self-contained apply instead of handing
# CloudFront and validation values over to this account by hand. It does that
# through these two roles:
#
# - `website-dns-read`: read-only, for plans. A PR plan runs the PR's own
#   provider code, so the identity that plans must not be able to reach a role
#   that rewrites apex/www.
# - `website-dns`: the read set plus narrowly scoped writes, for applies.
#
# Why here and not in the main root: these are identities another account's
# automation assumes, and ADR 0003 keeps every such identity in the locally
# applied bootstrap layer, so no CI apply can widen its own access.
#
# Why `hostedzone/*` rather than the zone's ARN: this root is applied before
# the main root creates the zone, so the zone ID doesn't exist yet. The
# account holds only the rottler.io zone, and the record-name conditions below
# do the narrowing that a zone ARN would otherwise do.
#
# Each role trusts the website account's SSO AdministratorAccess role, for
# local plans and applies, plus one deploy CI role from `website-bootstrap`:
# `ci-plan` may become only `website-dns-read`, `ci-apply` only `website-dns`.
#
# The read set (both roles together) is what the website root's plans and
# applies call against provider 6.x, checked against the provider source.

locals {
  website_sso_admin_arn_pattern = "arn:aws:iam::${var.website_account_id}:role/aws-reserved/sso.amazonaws.com/*AWSReservedSSO_AdministratorAccess_*"

  # Shared by both roles so they can't drift apart.
  website_dns_read_statements = [
    {
      # `data "aws_route53_zone"` reads the zone's details and tags once it
      # has found it, and the record resources read their record sets.
      Sid      = "ReadZone"
      Effect   = "Allow"
      Action   = ["route53:GetHostedZone", "route53:ListResourceRecordSets", "route53:ListTagsForResource"]
      Resource = "arn:aws:route53:::hostedzone/*"
    },
    {
      # Polled after every record change until it reports INSYNC.
      Sid      = "ReadChange"
      Effect   = "Allow"
      Action   = "route53:GetChange"
      Resource = "arn:aws:route53:::change/*"
    },
    {
      # The website root finds the zone by name, so no zone ID is ever
      # committed. Provider 6.x's `data "aws_route53_zone"` does that by
      # paging `ListHostedZones`, not `ListHostedZonesByName`. The action
      # has no resource scope.
      Sid      = "FindZoneByName"
      Effect   = "Allow"
      Action   = "route53:ListHostedZones"
      Resource = "*"
    },
  ]
}

# Principal is the whole website account, narrowed to the SSO admin role and
# the role's one CI role by `aws:PrincipalArn`. Naming the SSO role's ARN as
# the principal directly would break whenever Identity Center reprovisions it
# under a new suffix. Naming the CI role there would break if it were ever
# recreated: IAM stores a named role principal as the role's unique ID.
# No external ID (there is no third party) and no source identity (the
# CloudTrail session name already says who).
#
# Keyed by this account's role name. The value is the CI role allowed in.
data "aws_iam_policy_document" "website_dns_trust" {
  for_each = {
    website-dns-read = "ci-plan"
    website-dns      = "ci-apply"
  }

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.website_account_id}:root"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values = [
        local.website_sso_admin_arn_pattern,
        "arn:aws:iam::${var.website_account_id}:role/${each.value}",
      ]
    }
  }
}

# ------------------------------------------------------------------------------
# website-dns-read
# ------------------------------------------------------------------------------

resource "aws_iam_role" "website_dns_read" {
  name               = "website-dns-read"
  description        = "Read-only access to the rottler.io zone for website root plans"
  assume_role_policy = data.aws_iam_policy_document.website_dns_trust["website-dns-read"].json
}

resource "aws_iam_role_policy" "website_dns_read" {
  name = "read-zone"
  role = aws_iam_role.website_dns_read.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.website_dns_read_statements
  })
}

# ------------------------------------------------------------------------------
# website-dns
# ------------------------------------------------------------------------------

resource "aws_iam_role" "website_dns" {
  name               = "website-dns"
  description        = "Writes the website root's apex/www aliases and ACM validation records into the rottler.io zone"
  assume_role_policy = data.aws_iam_policy_document.website_dns_trust["website-dns"].json
}

# Two write statements, each pairing names with types. Terraform's Route 53
# provider sends one record per change batch, so a single change never has to
# satisfy both statements at once. With names and types in one statement, the
# website root could write a CNAME at the apex or an A at a `_` name.
#
# Out of reach by name or type: MX, the SPF/DMARC/_atproto TXT records, the
# DKIM CNAMEs (`mbo000N._domainkey`, which don't start with `_`), and any NS
# delegation. No TXT at all: the www move is remove-then-add, so the website
# root never needs a TXT ownership record.
#
# No `ActionTypes` condition: Terraform needs DELETE as well as UPSERT/CREATE
# to replace and destroy its own records.
#
# `ForAllValues` is vacuously true when a key is absent, but Route 53 always
# populates both keys for ChangeResourceRecordSets, so that gap doesn't apply
# to the only action these statements allow.
resource "aws_iam_role_policy" "website_dns" {
  name = "write-website-records"
  role = aws_iam_role.website_dns.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(local.website_dns_read_statements, [
      {
        Sid      = "WriteSiteAliases"
        Effect   = "Allow"
        Action   = "route53:ChangeResourceRecordSets"
        Resource = "arn:aws:route53:::hostedzone/*"
        Condition = {
          "ForAllValues:StringEquals" = {
            "route53:ChangeResourceRecordSetsNormalizedRecordNames" = ["rottler.io", "www.rottler.io"]
            "route53:ChangeResourceRecordSetsRecordTypes"           = ["A", "AAAA"]
          }
        }
      },
      {
        # ACM's DNS validation names are `_<hash>.<domain>`. The apex and
        # `*.rottler.io` share one validation name, so this covers both SANs.
        Sid      = "WriteCertValidation"
        Effect   = "Allow"
        Action   = "route53:ChangeResourceRecordSets"
        Resource = "arn:aws:route53:::hostedzone/*"
        Condition = {
          "ForAllValues:StringLike" = {
            "route53:ChangeResourceRecordSetsNormalizedRecordNames" = ["_*.rottler.io"]
          }
          "ForAllValues:StringEquals" = {
            "route53:ChangeResourceRecordSetsRecordTypes" = ["CNAME"]
          }
        }
      },
    ])
  })
}
