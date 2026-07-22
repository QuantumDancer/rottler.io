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

# TODO(benjamin): neither bucket has a public access block, versioning, or an
# explicit server-side-encryption configuration. These are genuine gaps carried
# over from the legacy stack, deliberately not fixed here: they would be *new*
# resources, and the migration plan's safety gate asserts zero adds. Follow-up
# commit once Phase 3 has landed (see project/TF_MIGRATION.md, decision 8).
