variable "role_arn" {
  description = "The ARN of the role to assume"
  type        = string
}

variable "project_name" {
  description = "A project name to be used in resources"
  type        = string
  default     = "rottler-io"
}

variable "environment" {
  description = "dev/prod environment"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Invalid environment. Allowed values: dev, prod."
  }
}

variable "top_level_domain" {
  description = "The top level domain for the website"
  type        = string
  default     = "rottler.io"
}

locals {
  domain_name = "${var.environment}.${var.top_level_domain}"
}
