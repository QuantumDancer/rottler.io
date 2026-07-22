#!/usr/bin/env bash
#
# Publish the built Astro site to an environment's S3 bucket and invalidate its
# CloudFront distribution. Invoked as `make deploy ENV=dev`; see the Makefile.
#
# This is a port of the legacy repo's `astro-deploy` GitHub action, with the
# safety rails it lacked. Those rails exist because `aws s3 sync --delete` is
# the single most destructive command in this repository: it makes the bucket
# match the local directory exactly, deleting anything not present locally.
#
# Two independent failure modes are guarded:
#
#   1. Syncing to the *wrong bucket*. The destination is only ever read from
#      the requested environment's Terraform output, never passed in or
#      hardcoded, so it cannot name a bucket that environment does not own.
#      Deploying to prod would require a prod environment to exist and be
#      named explicitly.
#
#   2. Syncing the *wrong content*. A build that failed, was interrupted, or
#      was never run leaves `dist/` missing, empty, or without an entry point —
#      and `--delete` would then faithfully empty the live bucket. The
#      preflight below refuses all three cases.

set -euo pipefail

env_name="${1:?usage: deploy.sh <environment>}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tf_dir="${repo_root}/infra/envs/${env_name}"
dist_dir="${repo_root}/frontend/dist"

if [ ! -d "${tf_dir}" ]; then
  echo "deploy: no such environment '${env_name}' (expected ${tf_dir})" >&2
  exit 1
fi

# ==============================================================================
# Preflight: is there something safe to publish?
# ==============================================================================
#
# Checked before resolving any AWS identity, so a broken build fails fast and
# locally rather than after touching the network.

if [ ! -d "${dist_dir}" ]; then
  echo "deploy: ${dist_dir} does not exist — run 'make build ENV=${env_name}' first." >&2
  echo "deploy: refusing to sync, as --delete would empty the live bucket." >&2
  exit 1
fi

# `index.html` specifically, not merely "some files": a partial build can leave
# assets behind while lacking the document that makes the site a site, and
# CloudFront's default root object would 404 for every visitor.
if [ ! -f "${dist_dir}/index.html" ]; then
  echo "deploy: ${dist_dir} has no index.html — the build is incomplete or failed." >&2
  echo "deploy: refusing to sync, as --delete would replace the site with a broken one." >&2
  exit 1
fi

# ==============================================================================
# Resolve the destination from Terraform, never from an argument
# ==============================================================================

bucket_id="$(terraform -chdir="${tf_dir}" output -raw website_bucket_id)"
distribution_id="$(terraform -chdir="${tf_dir}" output -raw cloudfront_distribution_id)"
site_url="$(terraform -chdir="${tf_dir}" output -raw site_url)"

if [ -z "${bucket_id}" ] || [ -z "${distribution_id}" ]; then
  echo "deploy: Terraform returned an empty bucket or distribution id for '${env_name}'." >&2
  echo "deploy: has 'make tf-init ENV=${env_name}' been run against a populated state?" >&2
  exit 1
fi

echo "deploy: environment ${env_name}"
echo "deploy:   bucket       s3://${bucket_id}"
echo "deploy:   distribution ${distribution_id}"
echo "deploy:   site         ${site_url}"

# ==============================================================================
# Publish
# ==============================================================================
#
# `--delete` is what keeps the bucket from accumulating files that no longer
# exist in the build — stale hashed assets, pages removed from the site, and on
# the first run of this migration, the entire Cloud Resume Challenge-era site.

aws s3 sync --delete "${dist_dir}/" "s3://${bucket_id}"

# The sync alone is not visible to anyone: CloudFront keeps serving the previous
# objects until their TTL expires (24h under this cache policy). A blanket /*
# invalidation is the blunt but correct choice for a site this small — the first
# 1000 invalidation paths per month are free, and precision here would buy
# nothing.
invalidation_id="$(aws cloudfront create-invalidation \
  --distribution-id "${distribution_id}" \
  --paths '/*' \
  --query 'Invalidation.Id' \
  --output text)"

echo "deploy: invalidation ${invalidation_id} created; ${site_url} updates within a few minutes."
