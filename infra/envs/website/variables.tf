variable "dns_role_arn" {
  description = "Role in the shared-services account that the `aws.dns` provider assumes. Exported by env.sh locally and supplied by the workflow in CI, so the account ID is never committed"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/website-dns(-read)?$", var.dns_role_arn))
    error_message = "dns_role_arn must be the ARN of the website-dns or website-dns-read role."
  }
}
