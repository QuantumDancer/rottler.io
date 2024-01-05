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

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "cloudfront/${local.domain_name}/"
  }

  aliases = [local.domain_name]

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.cf_website_s3_origin_id
    cache_policy_id        = aws_cloudfront_cache_policy.website.id
    viewer_protocol_policy = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.append_index_html.arn
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.website_cert.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
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

resource "aws_cloudfront_function" "append_index_html" {
  name    = "append_index_html"
  runtime = "cloudfront-js-2.0"
  comment = "Append index.html when it's missing from the URL"
  code    = file("${path.module}/scripts/cloudfront_append_index_html.js")
}
