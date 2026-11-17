# shellcheck shell=bash
# Sourced by the root Makefile: `. infra/envs/$(ENV)/env.sh`.
#
# The SSO AdministratorAccess profile for the website account: a bootstrap root
# is applied by a human, never by CI.

export AWS_PROFILE=rottler.io-website
export AWS_REGION=us-east-1

# The CI roles may assume the DNS roles in shared-services. Its ID comes from
# the local profile rather than a committed file: the repo is public and names
# no account IDs.
TF_VAR_shared_services_account_id=$(aws configure get sso_account_id --profile rottler.io-shared-services)
export TF_VAR_shared_services_account_id
