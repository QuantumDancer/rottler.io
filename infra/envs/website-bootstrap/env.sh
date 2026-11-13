# shellcheck shell=bash
# Sourced by the root Makefile: `. infra/envs/$(ENV)/env.sh`.
#
# The SSO AdministratorAccess profile for the website account: a bootstrap root
# is applied by a human, never by CI.

export AWS_PROFILE=rottler.io-website
export AWS_REGION=us-east-1
