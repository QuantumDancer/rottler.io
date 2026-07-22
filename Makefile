# Local-first operations for rottler.io.
#
# Every target is scoped to one environment, selected with ENV (default dev):
#
#     make plan ENV=dev
#     make build deploy ENV=dev
#
# There is deliberately no target that operates on "all environments" — the
# blast radius of a deploy is meant to be one explicitly named site.
#
# CI is a later step; when it lands, the workflows should be thin wrappers
# around these same targets so that what runs in CI is what runs locally.

ENV ?= dev

TF_DIR := infra/envs/$(ENV)

# Recipes run in a single shell per target so that `set -a; . env.sh` can export
# AWS_PROFILE/AWS_REGION into the commands that follow it. Without .ONESHELL
# each line is its own shell and the sourced variables would be lost.
.ONESHELL:
# An absolute path, not `/usr/bin/env bash`: make execs SHELL directly rather
# than resolving it through PATH, so the env form fails with ENOENT.
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Sourced by every target that talks to AWS. `set -a` exports each assignment;
# the guard keeps the Makefile usable in contexts where credentials come from
# elsewhere (CI with OIDC, an already-exported profile).
define load_env
	if [ -f $(TF_DIR)/env.sh ]; then set -a; . ./$(TF_DIR)/env.sh; set +a; fi
endef

.PHONY: help check fmt tf-init tf-plan tf-apply build deploy release

help:
	@echo "Targets (ENV=$(ENV)):"
	@echo "  check     fmt-check, validate, and tflint the Terraform"
	@echo "  fmt       rewrite Terraform files to canonical format"
	@echo "  tf-init   initialise the environment's Terraform working directory"
	@echo "  tf-plan   plan into $(TF_DIR)/$(ENV).tfplan"
	@echo "  tf-apply  apply that saved plan file"
	@echo "  build     build the Astro site with SITE_URL from Terraform"
	@echo "  deploy    sync frontend/dist to S3 and invalidate CloudFront"
	@echo "  release   build then deploy"

# ==============================================================================
# Terraform
# ==============================================================================

# Mirrors what the legacy repo's CI enforced, so that moving to GitHub Actions
# later is a matter of calling this target rather than reimplementing it.
check:
	terraform -chdir=$(TF_DIR) fmt -check -recursive ../../
	terraform -chdir=$(TF_DIR) validate
	tflint --chdir=$(TF_DIR)

fmt:
	terraform fmt -recursive infra/

tf-init:
	$(load_env)
	terraform -chdir=$(TF_DIR) init -input=false

# Plans are always written to a file rather than applied straight from a fresh
# plan: what gets reviewed must be exactly what gets applied. Terraform will
# refuse a stale plan file if the state moved underneath it, which is the point.
tf-plan:
	$(load_env)
	terraform -chdir=$(TF_DIR) plan -input=false -out=$(ENV).tfplan

tf-apply:
	$(load_env)
	terraform -chdir=$(TF_DIR) apply -input=false $(ENV).tfplan

# ==============================================================================
# Site
# ==============================================================================

# SITE_URL comes from the environment's own Terraform output, so the sitemap,
# RSS feed, and canonical URLs in the artefact always match the host it is about
# to be published to. Building for dev with the prod default would advertise
# rottler.io URLs from dev.rottler.io.
build:
	$(load_env)
	SITE_URL=$$(terraform -chdir=$(TF_DIR) output -raw site_url) npm --prefix frontend run build

deploy:
	$(load_env)
	./scripts/deploy.sh $(ENV)

release: build deploy
