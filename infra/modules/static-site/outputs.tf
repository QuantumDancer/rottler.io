output "website_bucket_id" {
  description = "Deploy target for `aws s3 sync` of the built Astro site"
  value       = aws_s3_bucket.website.id
}

output "website_bucket_arn" {
  description = "Resource for the deploy role's S3 permissions"
  value       = aws_s3_bucket.website.arn
}

output "cloudfront_distribution_id" {
  description = "Invalidation target after a deploy"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_distribution_arn" {
  description = "Resource for the deploy role's invalidation permission"
  value       = aws_cloudfront_distribution.website.arn
}

output "site_url" {
  description = "Canonical origin, consumed by Astro's `site` config so sitemap/RSS/canonicals point at the right host"
  value       = "https://${var.domain_name}"
}
