# ==============================================================================
# Terraform state bucket: one per account
# ==============================================================================
#
# Holds every state file of the account it lives in: the bootstrap root's own
# state (key `bootstrap/terraform.tfstate`) and the main root's
# (`main/terraform.tfstate`). Called only from bootstrap roots, which a human
# applies locally (docs/adr/0003-each-account-has-a-locally-applied-bootstrap-root.md),
# so nothing CI applies can reach this bucket's configuration.
#
# Locking is S3 native (`use_lockfile` in each backend block): the lock is a
# `.tflock` object next to the state, so no DynamoDB table exists to manage.

# Bucket names are global. The random suffix avoids collisions with anyone
# else's bucket without embedding the account ID, which committed names never
# carry (docs/adr/0001-terraform-backend-config-is-committed.md).
resource "random_id" "state_bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "state" {
  bucket = "rottler-io-${var.role}-tf-state-${random_id.state_bucket_suffix.hex}"

  # Losing this bucket loses the state of every root in the account. A destroy
  # has to start by deleting this line in a reviewed change.
  lifecycle {
    prevent_destroy = true
  }
}

# ==============================================================================
# Hardening
# ==============================================================================

# Versioning is the recovery path for a corrupted or wrongly-migrated state:
# any earlier write can be restored by promoting its version.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# SSE-S3, not KMS: state is only ever read by principals inside this account,
# so a customer-managed key would add cost and a key policy to maintain without
# narrowing who can read it.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ACLs off entirely: access is decided by IAM and the bucket policy alone.
resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Deny-only, so the public access block does not treat it as public.
data "aws_iam_policy_document" "state" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# Applied after the public access block so the policy is never evaluated
# against a bucket that would still accept a public one.
resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}

# Every apply writes a new state version, so versioning alone grows without
# bound. Ninety days covers noticing a bad state long after the fact; keeping
# the newest ten regardless means a root that is rarely applied still has its
# recent history when those versions age past ninety days.
#
# Intentionally omitted: access logging and object lock. CloudTrail management
# events already record who changed the bucket, and object lock would block the
# lifecycle cleanup above for no threat this bucket faces.
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    # Empty filter = every object.
    filter {}

    noncurrent_version_expiration {
      noncurrent_days           = 90
      newer_noncurrent_versions = 10
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # Lifecycle rules on a versioned bucket need versioning in place first.
  depends_on = [aws_s3_bucket_versioning.state]
}
