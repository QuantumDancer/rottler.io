# The dev state is *adopted*, not created: these values are the legacy repo's
# `backend.tf` and `backend.dev.hcl` merged into one hardcoded block, so a plain
# `terraform init` here picks up the existing dev state with every resource
# already in it. Getting the bucket or key wrong produces an empty state and a
# plan that wants to build a second copy of the whole site — check them before
# the first init.
#
# `dynamodb_table` rather than `use_lockfile`: newer Terraform deprecates the
# DynamoDB lock and will say so on init. That warning is expected. Migrating the
# lock would be churn on a backend that gets abandoned at the account
# restructure anyway (project/TF_MIGRATION.md, "Deferred version upgrades").
terraform {
  backend "s3" {
    bucket         = "rottler-io-tf-state-048f6820"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "rottler-io-tf-state-lock"
    encrypt        = true
  }
}
