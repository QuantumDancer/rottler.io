# Shares the account's one state bucket with `shared-services-bootstrap`
# (`bootstrap/terraform.tfstate`) under its own key. The bucket name is
# committed in full (docs/adr/0001-terraform-backend-config-is-committed.md).
terraform {
  backend "s3" {
    bucket       = "rottler-io-shared-services-tf-state-14a9b03d"
    key          = "main/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
