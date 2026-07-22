# ==============================================================================
# CloudFront distribution
# ==============================================================================
#
# Ported from the legacy stack with the visitor-counter parts removed: the
# `ViewCounterAPI` custom origin, the `/api/*` ordered cache behaviour, and that
# behaviour's cache policy are all gone. Dropping an origin and a behaviour is an
# in-place distribution update — CloudFront distributions are only replaced by
# changes Terraform marks ForceNew, and none of these are.
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#s3-origin

locals {
  cf_website_s3_origin_id = "S3 Bucket"
}

# No WAF in front of a static personal site: nothing here accepts input, and the
# monthly WAF floor costs more than the site does.
# tfsec:ignore:aws-cloudfront-enable-waf
resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
    origin_id                = local.cf_website_s3_origin_id
  }

  enabled         = true
  is_ipv6_enabled = true

  comment             = "S3 bucket for ${var.domain_name}"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "cloudfront/${var.domain_name}/"
  }

  aliases = var.aliases

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

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
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

# Ported byte-identical from the legacy stack, including the counter-era
# `connect-src`. The new Astro site needs `font-src 'self'` added — it self-hosts
# Fontsource woff2 files and `font-src` has no fallback beyond `default-src
# 'none'`, so fonts are currently blocked. That fix is deliberately held for
# Phase 4 so the state-migration plan stays a pure address rename with no
# incidental content diffs (project/TF_MIGRATION.md, decision 6).
#
# see https://www.scip.ch/en/?labs.20160121
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "security-headers"

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

# A static site in S3 has no directory-index concept, so this viewer-request
# function rewrites `/about` and `/about/` to `/about/index.html` — which is
# exactly the shape Astro's static build emits.
resource "aws_cloudfront_function" "append_index_html" {
  name    = "append_index_html"
  runtime = "cloudfront-js-2.0"
  comment = "Append index.html when it's missing from the URL"
  code    = file("${path.module}/files/cloudfront_append_index_html.js")
}
