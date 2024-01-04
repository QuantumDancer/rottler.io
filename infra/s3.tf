resource "random_id" "website_bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "website" {
  bucket = "${local.domain_name}-${random_id.website_bucket_id.hex}"
  tags = {
    Name = "${local.domain_name}-${random_id.website_bucket_id.hex}"
  }
}

resource "aws_s3_bucket_policy" "allow_access_from_cloudfront" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.allow_access_from_cloudfront.json
}

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

