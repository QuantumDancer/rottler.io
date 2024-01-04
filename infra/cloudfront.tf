# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#s3-origin

locals {
  cf_website_s3_origin_id = "S3-${aws_s3_bucket.website.id}"
}

resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
    origin_id                = local.cf_website_s3_origin_id
  }

  enabled         = true
  is_ipv6_enabled = true

  comment             = "S3 bucket for ${local.domain_name}"
  default_root_object = "index.html"


# │ Error: creating CloudFront Distribution: InvalidArgument: The S3 bucket that you specified for CloudFront logs does not enable ACL access: rottler.io-logs-95e5827f.s3.amazonaws.com
# │       status code: 400, request id: b6802d5c-15c7-4d75-a3a5-266fe8124fee

  # logging_config {
  #   include_cookies = false
  #   bucket          = aws_s3_bucket.logs.bucket_domain_name
  #   prefix          = "${local.domain_name}/"
  # }

# │ Error: creating CloudFront Distribution: InvalidViewerCertificate: To add an alternate domain name (CNAME) to a CloudFront distribution, you must attach a trusted certificate that validates your authorization to use the domain name. For more details, see: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/CNAMEs.html#alternate-domain-names-requirements
# │       status code: 400, request id: 03db3457-bf7f-48a6-b15c-c658df30ff45
#   aliases = ["${local.domain_name}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.cf_website_s3_origin_id
    cache_policy_id  = aws_cloudfront_cache_policy.website.id

    # TODO: switch to https once cert is set up
    viewer_protocol_policy = "allow-all"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    # TODO use acm_certificate_arn
  }

}

resource "aws_cloudfront_cache_policy" "website" {
  name        = "website-policy"
  comment     = "Cache policy for ${local.domain_name}"
  default_ttl = 86400
  min_ttl     = 0
  max_ttl     = 31536000
  parameters_in_cache_key_and_forwarded_to_origin {
    headers_config {
      header_behavior = "none"
    }
    cookies_config {
      cookie_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "S3Website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
