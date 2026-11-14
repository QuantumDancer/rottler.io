# ==============================================================================
# shared-services bootstrap: state bucket and the website's DNS roles
# ==============================================================================
#
# The bootstrap layer of the shared-services account, which holds the domain
# registration and the consolidated rottler.io zone. Applied only by a human
# from a local session; the main root (`envs/shared-services`) holds
# everything else. Why the layers split this way:
# docs/adr/0003-each-account-has-a-locally-applied-bootstrap-root.md.
#
# No CI applies anything in this account, so there is no OIDC provider here.
# The identities this root does own are the cross-account roles the website
# root assumes to write its own records into the zone (website_dns.tf).
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
