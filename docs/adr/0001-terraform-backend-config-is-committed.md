# Terraform backend config is committed in full

Every Terraform root commits its complete S3 backend block, state bucket name included, even though the repository is public and private infrastructure details are otherwise kept out of it. A bucket name is an address, not a credential: the state buckets are private, versioned, and behind a public access block, and S3 does not bill the owner for unauthorized requests from outside the account. Committing the backend keeps `terraform init` argument-free and gives CI nothing extra to inject. The line that is held instead: **committed names never embed an AWS account ID**, so state buckets carry a random suffix rather than the account number.

## Considered Options

- **Partial backend config** (`backend "s3" {}` plus a gitignored `-backend-config=` file, and the same values injected in CI): rejected. It adds a file that a fresh checkout lacks and a CI variable to keep in sync, to hide a value that grants nothing.
