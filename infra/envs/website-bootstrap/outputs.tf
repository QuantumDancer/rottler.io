output "state_bucket" {
  description = "Bucket for this account's backend blocks (bootstrap and main)"
  value       = module.state_bucket.bucket
}

output "github_oidc_provider_arn" {
  description = "Federated principal for the trust policies of CI roles"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

# Each becomes a GitHub secret (AWS_ROLE_CI_PLAN, AWS_ROLE_CI_APPLY,
# AWS_ROLE_CI_RELEASE), never a variable: the ARN names the account.
output "ci_role_arns" {
  description = "Deploy CI roles by name, for the GitHub secrets deploy.yml reads"
  value       = { for name, role in aws_iam_role.ci : name => role.arn }
}
