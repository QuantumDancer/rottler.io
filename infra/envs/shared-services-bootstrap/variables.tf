variable "website_account_id" {
  description = "ID of the website account, whose principals the DNS roles trust. Exported by env.sh from the local AWS profile, so it is never committed"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.website_account_id))
    error_message = "website_account_id must be a 12-digit AWS account ID."
  }
}
