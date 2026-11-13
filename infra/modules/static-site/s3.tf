# ==============================================================================
# Storage: the website bucket and the CloudFront log bucket
# ==============================================================================
#
# Neither bucket is public. The website bucket is reachable only through
# CloudFront's Origin Access Control (see cloudfront.tf), enforced by the bucket
# policy below.
#
# The account ID comes from a data source declared here rather than passed in as
# a variable: data sources hold no state identity, so re-reading one inside the
# module is free and does not need a `moved` block during the migration.

data "aws_caller_identity" "current" {}

##################
# Website bucket #
##################

# Bucket names are globally unique, so a random suffix avoids collisions with
# whoever else wants "dev.rottler.io". The suffix lives in state — regenerating
# it renames the bucket, which means destroying and recreating it, so this
# resource is one of the migration's `moved` blocks rather than a fresh one.
resource "random_id" "website_bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "website" {
  bucket = "${var.domain_name}-${random_id.website_bucket_id.hex}"
  tags = {
    Name = "${var.domain_name}-${random_id.website_bucket_id.hex}"
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_cloudfront" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.allow_access_from_cloudfront.json
}

# The SourceArn condition is what makes OAC actually restrictive: without it the
# policy would let *any* CloudFront distribution in any account read the bucket.
#
# https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html
data "aws_iam_policy_document" "allow_access_from_cloudfront" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.website.arn}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.website.id}"]
    }
  }
}

##################
# Logs bucket    #
##################

# Named from `project_name`, not the domain — this bucket is per-account rather
# than per-site, so a future second site in the same account logs alongside the
# first under its own CloudFront prefix.
resource "random_id" "logging_bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-logs-${random_id.logging_bucket_id.hex}"
  tags = {
    Name = "${var.project_name}-logs-${random_id.logging_bucket_id.hex}"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs-after-90-days"
    status = "Enabled"

    # Empty filter = every object, as on the website bucket's rule below.
    # Provider 5.x tolerated its absence; 6.x plans to strip the live empty
    # filter instead.
    filter {}

    expiration {
      days = 90
    }
  }
}

# CloudFront's standard logging delivers via ACL rather than a bucket policy, so
# the bucket has to opt back into ACLs (buckets default to BucketOwnerEnforced,
# which disables them entirely) and then grant log-delivery-write.
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]

  bucket = aws_s3_bucket.logs.id
  acl    = "log-delivery-write"
}

data "aws_iam_policy_document" "logs_bucket_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
    actions = [
      "s3:GetBucketAcl",
      "s3:PutBucketAcl"
    ]
    resources = [aws_s3_bucket.logs.arn]
  }
}

resource "aws_s3_bucket_policy" "logs_bucket_policy" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_bucket_policy.json
}

# ==============================================================================
# Hardening
# ==============================================================================
#
# Carried-over gaps from the legacy stack, held back until the migration's
# zero-add plan gate had passed (project/TF_MIGRATION.md, decision 8).

# Neither bucket should ever be public. The website bucket is reached only
# through CloudFront's OAC, and the log bucket only by the log delivery service.
#
# This is defence against a *future* mistake rather than a present one: today's
# policies grant nothing public. The block makes that non-negotiable, so a
# careless policy edit or a console click fails instead of quietly exposing the
# bucket. It does not disturb the log bucket's `log-delivery-write` ACL — the
# public-ACL controls target the AllUsers and AuthenticatedUsers grantees, and
# log delivery is neither.
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning on the website bucket is specifically insurance against the deploy
# path. `aws s3 sync --delete` makes the bucket match a local directory, so a
# broken build published by a careless run would otherwise be unrecoverable
# except by rebuilding. With versioning, the previous site is still there.
#
# scripts/deploy.sh guards the same failure at the other end by refusing to sync
# an empty or incomplete `dist/`. Neither control is redundant: the script
# prevents the common mistake, versioning survives the uncommon one.
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Versioning without expiry is a slow storage leak: every deploy supersedes every
# hashed asset, and the old versions would accumulate forever. Thirty days is far
# longer than it would take to notice a bad deploy, and short enough that the
# bucket stays small.
resource "aws_s3_bucket_lifecycle_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    id     = "expire-noncurrent-versions-after-30-days"
    status = "Enabled"

    # Empty filter = every object. Stated explicitly because the provider treats
    # a rule with no filter and no prefix as ambiguous.
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# S3 has encrypted new objects with SSE-S3 by default since January 2023, so
# these blocks change no behaviour today. They are here to make the guarantee
# explicit and enforced rather than inherited from an account-level default that
# could change, and so that a compliance scan reads the intent from the config.
#
# SSE-S3 rather than SSE-KMS deliberately: KMS would add per-request cost and
# key-policy coupling to CloudFront's OAC, buying nothing for objects that are
# served to the public anyway.
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Intentionally omitted: versioning on the log bucket, which is append-only and
# already expires at 90 days — versions would only double its storage. Also
# omitted: an `abort_incomplete_multipart_upload` rule, since nothing here
# uploads objects large enough to be multipart.
