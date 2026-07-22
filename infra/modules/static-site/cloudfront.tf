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

  # Without these, a mistyped URL returns CloudFront's generic XML error and the
  # site's own 404 page is unreachable — Astro builds and uploads it, but nothing
  # ever routes there.
  #
  # Both codes have to be mapped, and 403 is the one that actually matters. The
  # bucket is private behind OAC with no `s3:ListBucket` grant, so S3 reports a
  # missing key as `AccessDenied` (403) rather than `NoSuchKey` (404); a
  # 404-only mapping would never fire. The 404 block is kept anyway so the
  # behaviour does not silently depend on that policy detail staying as it is.
  #
  # Rewriting 403 to 404 is safe *because* the site is entirely public: every
  # object is meant to be readable, so a 403 can only mean "not there". Were any
  # path ever genuinely access-controlled, this would misreport it as missing.
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 300
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

# see https://www.scip.ch/en/?labs.20160121
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "security-headers"

  security_headers_config {
    # Everything is same-origin: the site has no third-party scripts, analytics,
    # embeds, or CDN assets, so `default-src 'none'` plus a narrow allowlist is
    # achievable rather than aspirational.
    #
    # Two entries are worth explaining:
    #
    #   * `font-src 'self'` — fonts are self-hosted via Fontsource and emitted
    #     into `_astro/`. `font-src` does not fall back to anything but
    #     `default-src`, so without this line every font request is blocked and
    #     the site silently renders in fallback faces.
    #
    #   * `script-src 'unsafe-inline'` — required by the pre-paint theme script
    #     in BaseLayout.astro, which must run inline and before first paint to
    #     avoid a flash of the wrong theme. A nonce would be the stronger answer
    #     but needs per-request header generation, which a static S3 origin
    #     cannot do. The exposure is small: no user input reaches the page.
    #
    # Dropped from the legacy policy: `connect-src 'self'`, which existed for the
    # visitor counter's fetch call. The site now ships no client-side networking
    # at all — no view transitions, no prefetch — so it falls through to
    # `default-src 'none'`. Reinstate it the moment anything starts fetching.
    #
    # see https://content-security-policy.com/
    content_security_policy {
      content_security_policy = "default-src 'none'; script-src 'self' 'unsafe-inline'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; font-src 'self'; base-uri 'self'; form-action 'self'"
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
