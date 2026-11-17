# The contract the deploy tooling reads: the Makefile's `build` and
# scripts/deploy.sh locally, and deploy CI's `ci-release` role via
# `terraform_remote_state`. Renaming one breaks the other side, so these names
# stay put. The first three match envs/dev's.

output "website_bucket_id" {
  description = "Deploy target for `aws s3 sync` of the built Astro site"
  value       = module.site.website_bucket_id
}

output "website_bucket_arn" {
  description = "Resource for the deploy role's S3 permissions"
  value       = module.site.website_bucket_arn
}

output "cloudfront_distribution_id" {
  description = "Invalidation target after a deploy"
  value       = module.site.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  description = "Resource for the deploy role's invalidation permission"
  value       = module.site.cloudfront_distribution_arn
}

output "site_url" {
  description = "Canonical origin passed to Astro's `site` config at build time"
  value       = module.site.site_url
}
