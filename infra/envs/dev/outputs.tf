# These three are the contract the deploy tooling reads. The Makefile resolves
# the bucket name from `website_bucket_id` rather than hardcoding it, which is
# what makes `aws s3 sync --delete` safe: the destination can only ever be the
# bucket belonging to the environment being deployed.

output "website_bucket_id" {
  description = "Deploy target for `aws s3 sync` of the built Astro site"
  value       = module.site.website_bucket_id
}

output "cloudfront_distribution_id" {
  description = "Invalidation target after a deploy"
  value       = module.site.cloudfront_distribution_id
}

output "site_url" {
  description = "Canonical origin passed to Astro's `site` config at build time"
  value       = module.site.site_url
}
