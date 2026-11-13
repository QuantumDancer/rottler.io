# ==============================================================================
# shared-services bootstrap: the account's state bucket
# ==============================================================================
#
# The bootstrap layer of the shared-services account, which will hold the
# domain registration and the consolidated rottler.io zone. Applied only by a
# human from a local session; the main root (`envs/shared-services`) holds
# everything else. Why the layers split this way:
# docs/adr/0003-each-account-has-a-locally-applied-bootstrap-root.md.
#
# Bucket only. Unlike the website account, no CI applies anything here yet, so
# there is no OIDC provider or CI role to own.
#
# First apply ran on local state; backend.tf was added afterwards and the state
# migrated into the bucket this root creates.

terraform {
  # 1.10 is the floor for S3 native locking (`use_lockfile`).
  required_version = "~> 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      managed-by = "terraform"
      repository = "rottler.io"
      stack      = "shared-services-bootstrap"
    }
  }
}

module "state_bucket" {
  source = "../../modules/state-bucket"

  role = "shared-services"
}
