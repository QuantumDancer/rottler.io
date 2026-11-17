terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"

      # Route 53 records go through `aws.dns`, the account that owns the zone.
      # For a single-account root, the caller passes its default provider here.
      configuration_aliases = [aws.dns]
    }
  }
}
