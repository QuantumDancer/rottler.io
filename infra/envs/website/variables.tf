# Ephemeral so a saved plan doesn't carry it. A plan file records every
# ordinary variable's value and apply reuses it, ignoring what the environment
# sets. Deploy CI plans with `website-dns-read` and applies with `website-dns`,
# so a recorded value would make the apply job write records through the
# read-only role. Ephemeral values are left out of plan and state, and apply
# must supply the variable again. That's fine: it is only ever used in the
# `aws.dns` provider block, where ephemeral values are allowed.
variable "dns_role_arn" {
  description = "Role in the shared-services account that the `aws.dns` provider assumes. Exported by env.sh locally and supplied by the workflow in CI, so the account ID is never committed"
  type        = string
  nullable    = false
  ephemeral   = true

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/website-dns(-read)?$", var.dns_role_arn))
    error_message = "dns_role_arn must be the ARN of the website-dns or website-dns-read role."
  }
}
