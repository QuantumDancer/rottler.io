# Sourced by the root Makefile: `. infra/envs/$(ENV)/env.sh`.
#
# Named env.sh rather than .env because the repo .gitignore swallows `.env`, and
# nothing here is secret — it is just the profile and region a fresh checkout
# needs in order to point at the right account.
#
# The legacy file also exported TF_VAR_role_arn; it was dead (no `role_arn`
# variable existed) and is dropped.

export AWS_PROFILE=rottler.io-dev
export AWS_REGION=us-east-1
