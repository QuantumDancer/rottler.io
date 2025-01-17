# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#s3-origin

locals {
  cf_website_s3_origin_id  = "S3 Bucket"
  cf_website_api_origin_id = "ViewCounterAPI"
}

# tfsec:ignore:aws-cloudfront-enable-waf
resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
    origin_id                = local.cf_website_s3_origin_id
  }

  origin {
    domain_name = replace(aws_apigatewayv2_api.view_counter.api_endpoint, "https://", "")
    origin_id   = local.cf_website_api_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
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

  aliases = local.cloudfront_aliases

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = local.cf_website_s3_origin_id
    cache_policy_id            = aws_cloudfront_cache_policy.website.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
    viewer_protocol_policy     = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.append_index_html.arn
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.cf_website_api_origin_id
    cache_policy_id        = aws_cloudfront_cache_policy.view_counter_api.id
    viewer_protocol_policy = "redirect-to-https"
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
  comment     = "Cache policy for Frontend"
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

resource "aws_cloudfront_cache_policy" "view_counter_api" {
  name        = "view-counter-api-policy"
  comment     = "Cache policy for ViewCounter API"
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

resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "security-headers"

  # see https://www.scip.ch/en/?labs.20160121
  security_headers_config {
    # see https://content-security-policy.com/
    content_security_policy {
      content_security_policy = "default-src 'none'; script-src 'self' 'unsafe-inline'; connect-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; base-uri 'self'; form-action 'self'"
      override                = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = "31536000"
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    xss_protection {
      protection = true
      mode_block = true
      override   = true
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
