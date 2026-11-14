# shellcheck shell=bash
# Sourced by the root Makefile: `. infra/envs/$(ENV)/env.sh`.
#
# The SSO AdministratorAccess profile for the shared-services account: a
# bootstrap root is applied by a human, never by CI.

export AWS_PROFILE=rottler.io-shared-services
export AWS_REGION=us-east-1

# The DNS roles trust the website account. Its ID comes from the local profile
# rather than a committed file: the repo is public and names no account IDs.
TF_VAR_website_account_id=$(aws configure get sso_account_id --profile rottler.io-website)
export TF_VAR_website_account_id
