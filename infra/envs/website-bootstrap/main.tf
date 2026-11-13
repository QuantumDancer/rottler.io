# ==============================================================================
# website bootstrap: state bucket and the identities CI assumes
# ==============================================================================
#
# The bootstrap layer of the website account. Applied only by a human from a
# local session; the main root (`envs/website`) holds the site itself and is
# what deploy CI applies. Keeping CI's trust and permissions here means no CI
# apply can widen its own access:
# docs/adr/0003-each-account-has-a-locally-applied-bootstrap-root.md.
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
      stack      = "website-bootstrap"
    }
  }
}

module "state_bucket" {
  source = "../../modules/state-bucket"

  role = "website"
}

# ==============================================================================
# GitHub Actions OIDC
# ==============================================================================

# The account-wide trust anchor for GitHub-issued tokens. On its own it grants
# nothing: access comes only from roles whose trust policy names this provider
# and pins the repository and ref.
#
# No thumbprint_list: AWS validates GitHub's certificate against its own trusted
# CA library for this issuer, and the provider has accepted an empty list since
# 5.81.
#
# TODO: the CI roles that trust this provider are added here by the deploy CI
# ticket, which owns their scope and trust conditions.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}
