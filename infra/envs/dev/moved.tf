# ==============================================================================
# State migration: legacy flat addresses → module addresses
# ==============================================================================
#
# Every resource below already exists in the adopted dev state under its legacy
# root-module address. These blocks tell Terraform the addresses were renamed,
# not that the infrastructure changed — which is the entire point of doing the
# restructure with `moved` rather than `terraform state mv`: it is declarative,
# reviewable in the diff, and visible in the plan *before* anything is applied.
#
# There are 18 of them, matching every non-counter resource in the legacy root.
# Data sources need no blocks — they hold no state identity and are simply
# re-read at their new locations.
#
# Delete this file in a follow-up commit once a plan comes back clean; the
# blocks are only needed for the one apply that performs the rename.

# ------------------------------------------------------------------ module.dns

moved {
  from = aws_route53_zone.website
  to   = module.dns.aws_route53_zone.website
}

# ----------------------------------------------------------------- module.cert

moved {
  from = aws_acm_certificate.website_cert
  to   = module.cert.aws_acm_certificate.website_cert
}

# One block covers every `for_each` instance: moving the resource address moves
# all of its instance keys with it, and the keys themselves are unchanged
# because the module kept the `dvo.domain_name` key expression verbatim.
moved {
  from = aws_route53_record.acm_validation
  to   = module.cert.aws_route53_record.acm_validation
}

# ------------------------------------------------------------ module.site (S3)

# The random suffixes move rather than regenerate. If these two blocks were
# missing, Terraform would mint new hex values and rename both buckets — which
# for S3 means destroy and recreate, taking the live site's content with it.
moved {
  from = random_id.website_bucket_id
  to   = module.site.random_id.website_bucket_id
}

moved {
  from = random_id.logging_bucket_id
  to   = module.site.random_id.logging_bucket_id
}

moved {
  from = aws_s3_bucket.website
  to   = module.site.aws_s3_bucket.website
}

moved {
  from = aws_s3_bucket_policy.allow_access_from_cloudfront
  to   = module.site.aws_s3_bucket_policy.allow_access_from_cloudfront
}

moved {
  from = aws_s3_bucket.logs
  to   = module.site.aws_s3_bucket.logs
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.logs
  to   = module.site.aws_s3_bucket_lifecycle_configuration.logs
}

moved {
  from = aws_s3_bucket_ownership_controls.logs
  to   = module.site.aws_s3_bucket_ownership_controls.logs
}

moved {
  from = aws_s3_bucket_acl.logs
  to   = module.site.aws_s3_bucket_acl.logs
}

moved {
  from = aws_s3_bucket_policy.logs_bucket_policy
  to   = module.site.aws_s3_bucket_policy.logs_bucket_policy
}

# ---------------------------------------------------- module.site (CloudFront)

moved {
  from = aws_cloudfront_distribution.website
  to   = module.site.aws_cloudfront_distribution.website
}

moved {
  from = aws_cloudfront_cache_policy.website
  to   = module.site.aws_cloudfront_cache_policy.website
}

moved {
  from = aws_cloudfront_response_headers_policy.security_headers
  to   = module.site.aws_cloudfront_response_headers_policy.security_headers
}

moved {
  from = aws_cloudfront_origin_access_control.website
  to   = module.site.aws_cloudfront_origin_access_control.website
}

moved {
  from = aws_cloudfront_function.append_index_html
  to   = module.site.aws_cloudfront_function.append_index_html
}

# ------------------------------------------------------- module.site (Route53)

moved {
  from = aws_route53_record.website
  to   = module.site.aws_route53_record.website
}

# Intentionally absent: the visitor-counter resources
# (aws_lambda_function.view_counter, the apigatewayv2 stack,
# aws_dynamodb_table.view_counter, aws_cloudwatch_log_group.view_counter_api,
# aws_cloudfront_cache_policy.view_counter_api, and the Lambda IAM role/policy
# and its two attachments). They are not being moved — they are being dropped,
# so their absence from the config is what plans them for destruction. Expect
# exactly 14 deletes, all from that list.
