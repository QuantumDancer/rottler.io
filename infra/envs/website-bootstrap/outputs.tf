output "state_bucket" {
  description = "Bucket for this account's backend blocks (bootstrap and main)"
  value       = module.state_bucket.bucket
}

output "github_oidc_provider_arn" {
  description = "Federated principal for the trust policies of CI roles"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}
