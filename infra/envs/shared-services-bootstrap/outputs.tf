output "state_bucket" {
  description = "Bucket for this account's backend blocks (bootstrap and main)"
  value       = module.state_bucket.bucket
}
