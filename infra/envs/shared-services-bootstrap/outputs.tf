output "state_bucket" {
  description = "Bucket for this account's backend blocks (bootstrap and main)"
  value       = module.state_bucket.bucket
}

output "website_dns_role_arn" {
  description = "Role the website root assumes to write its records (TF_VAR_dns_role_arn for applies)"
  value       = aws_iam_role.website_dns.arn
}

output "website_dns_read_role_arn" {
  description = "Role the website root assumes for read-only plans"
  value       = aws_iam_role.website_dns_read.arn
}
