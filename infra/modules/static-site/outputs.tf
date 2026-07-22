output "website_bucket_id" {
  description = "Deploy target for `aws s3 sync` of the built Astro site"
  value       = aws_s3_bucket.website.id
}

output "cloudfront_distribution_id" {
  description = "Invalidation target after a deploy"
  value       = aws_cloudfront_distribution.website.id
}

output "site_url" {
  description = "Canonical origin, consumed by Astro's `site` config so sitemap/RSS/canonicals point at the right host"
  value       = "https://${var.domain_name}"
}
