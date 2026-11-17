variable "shared_services_account_id" {
  description = "ID of the shared-services account, whose DNS roles the CI roles may assume. Exported by env.sh from the local AWS profile, so it is never committed"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.shared_services_account_id))
    error_message = "shared_services_account_id must be a 12-digit AWS account ID."
  }
}
