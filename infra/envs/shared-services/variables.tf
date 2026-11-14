# Set in the gitignored `terraform.tfvars` in this directory, which Terraform
# loads automatically. Sensitive so plans don't print it; it still lands in
# state, which stays private in the account's state bucket.
variable "alert_email" {
  description = "Address the `alerts` SNS topic emails. Never committed: the repo is public"
  type        = string
  nullable    = false
  sensitive   = true
}
