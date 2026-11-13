# Each account has a locally-applied bootstrap root

Every AWS account the site runs in gets two Terraform roots: a bootstrap root (`infra/envs/<account>-bootstrap`) and a main root (`infra/envs/<account>`). The bootstrap root holds the account's state bucket and the identities CI assumes in that account: the GitHub OIDC provider and the CI roles. Only a human applies it, from a local session. Everything CI plans and applies goes in the main root. The split follows who applies what. A main root that CI applies can't change the trust policy or permissions of the role CI runs as, and the bucket that holds all of the account's state is outside the blast radius of a routine apply.

The bootstrap root's first apply runs on local state and creates the bucket. The root then migrates its own state into that bucket with `terraform init -migrate-state`, under a key separate from the main root's. Buckets are versioned, encrypted, private, TLS-only and `prevent_destroy`, with S3 native locking (`use_lockfile`) and no DynamoDB table.

## Considered Options

- **The main root owns its own state bucket**: rejected. It saves one directory per account, but CI's apply path would reach both the bucket holding its state and its own IAM role.
- **CloudFormation for the bucket**, as the legacy site did: rejected. It's a second IaC tool for a few resources, and its stack sits outside every Terraform plan.
- **An AWS CLI script**: rejected. It isn't declarative, so drift such as versioning being switched off never shows up in a plan.

## Consequences

- An IAM change for CI (a new permission for the deploy role) is a local bootstrap apply, not a pull request that CI applies by itself.
- Bootstrap roots sit next to the main roots under `infra/envs/`, so the Makefile's `ENV=` targets and the CI `infra` matrix cover them without special cases.
