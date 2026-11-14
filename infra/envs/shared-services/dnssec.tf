# ==============================================================================
# DNSSEC signing
# ==============================================================================
#
# The zone signs from creation, before anything delegates to it. With no DS at
# .io pointing at it, validating resolvers treat it as insecure, so signing
# early is harmless and lets the setup be checked (`dig +dnssec`, KSK
# `ACTIVE`) well ahead of the cutover. A signed-to-signed move isn't possible
# (Route 53 has no multi-signer), so there is an unsigned window between the old
# DS's removal and the new one's publication either way.
#
# `prevent_destroy` on the key and the KSK: once the DS is published, losing
# either makes the whole domain fail validation (SERVFAIL for every validating
# resolver) until a new DS propagates.

resource "aws_kms_key" "dnssec" {
  description              = "Route 53 DNSSEC key-signing key for ${local.domain_name}"
  customer_master_key_spec = "ECC_NIST_P256"
  key_usage                = "SIGN_VERIFY"
  deletion_window_in_days  = 7

  # Route 53's DNSSEC service signs with the key on the zone's behalf. Scoped
  # to this account and this zone so no other zone can use it (confused
  # deputy). The account-root statement keeps the key manageable through IAM;
  # without it a key policy can lock everyone out.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableIamPolicies"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowRoute53DnssecSigning"
        Effect    = "Allow"
        Principal = { Service = "dnssec-route53.amazonaws.com" }
        Action    = ["kms:DescribeKey", "kms:GetPublicKey", "kms:Sign"]
        Resource  = "*"
        Condition = {
          StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
          ArnEquals    = { "aws:SourceArn" = "arn:aws:route53:::hostedzone/${module.dns.zone_id}" }
        }
      },
      {
        Sid       = "AllowRoute53DnssecGrant"
        Effect    = "Allow"
        Principal = { Service = "dnssec-route53.amazonaws.com" }
        Action    = "kms:CreateGrant"
        Resource  = "*"
        Condition = {
          Bool = { "kms:GrantIsForAWSResource" = "true" }
        }
      },
    ]
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_key_signing_key" "rottler_io" {
  hosted_zone_id             = module.dns.zone_id
  key_management_service_arn = aws_kms_key.dnssec.arn
  name                       = "rottler_io"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_hosted_zone_dnssec" "rottler_io" {
  # Referencing the KSK (not just the zone) orders signing after the KSK
  # exists, and on destroy, unsigning before the KSK goes.
  hosted_zone_id = aws_route53_key_signing_key.rottler_io.hosted_zone_id
}
