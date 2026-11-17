# shellcheck shell=bash
# Sourced by the root Makefile: `. infra/envs/$(ENV)/env.sh`.
#
# In GitHub Actions the workflow supplies the OIDC credentials and
# TF_VAR_dns_role_arn (a secret), and the runner has no SSO profiles to read,
# so only the region is set there.

export AWS_REGION=us-east-1

if [ -z "${GITHUB_ACTIONS:-}" ]; then
  # Applied locally with the SSO AdministratorAccess profile.
  export AWS_PROFILE=rottler.io-website

  # The writing role, since local runs are what apply. Its account ID comes from
  # the local shared-services profile rather than a committed file: the repo is
  # public and names no account IDs.
  dns_account_id=$(aws configure get sso_account_id --profile rottler.io-shared-services)
  export TF_VAR_dns_role_arn="arn:aws:iam::${dns_account_id}:role/website-dns"
  unset dns_account_id
fi
