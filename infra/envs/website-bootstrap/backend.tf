# This root's state lives in the bucket the root itself creates. The first
# apply ran without this file, on local state; this block was added afterwards
# and the state moved in with `terraform init -migrate-state`. A fresh checkout
# just runs `terraform init`.
#
# Key `bootstrap/` so the main root (`main/terraform.tfstate`) shares the
# bucket without sharing a state file. The bucket name is committed in full
# (docs/adr/0001-terraform-backend-config-is-committed.md).
terraform {
  backend "s3" {
    bucket       = "rottler-io-website-tf-state-8bb2487a"
    key          = "bootstrap/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
