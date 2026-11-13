variable "role" {
  description = "The account's role, which names the bucket: rottler-io-<role>-tf-state-<suffix>, e.g. website"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.role))
    error_message = "role must be lowercase letters, digits, and hyphens, as it becomes part of an S3 bucket name."
  }
}
