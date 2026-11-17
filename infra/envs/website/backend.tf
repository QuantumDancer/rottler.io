# Shares the account's one state bucket with `website-bootstrap`
# (`bootstrap/terraform.tfstate`) under its own key. The bucket name is
# committed in full (docs/adr/0001-terraform-backend-config-is-committed.md).
terraform {
  backend "s3" {
    bucket       = "rottler-io-website-tf-state-8bb2487a"
    key          = "main/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
