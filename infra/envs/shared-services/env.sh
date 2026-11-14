# shellcheck shell=bash
# Sourced by the root Makefile: `. infra/envs/$(ENV)/env.sh`.
#
# Applied locally with the SSO AdministratorAccess profile; no CI applies this
# account. The alert email address isn't here: this file is committed, so the
# address comes from the gitignored terraform.tfvars next to it.

export AWS_PROFILE=rottler.io-shared-services
export AWS_REGION=us-east-1
