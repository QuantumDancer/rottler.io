# ==============================================================================
# Deploy CI roles
# ==============================================================================
#
# `.github/workflows/deploy.yml` assumes one role per job, each trusted only for
# the GitHub OIDC `sub` claim of that job:
#
# - `ci-plan`: plans `envs/website` on every push to main (and read-only on
#   PRs). Can read the account, take the main state's lock, and store the plan.
# - `ci-apply`: applies that stored plan, behind the `website-terraform`
#   GitHub environment's required reviewer. Broad on the services the site is
#   made of, fenced by explicit denies.
# - `ci-release`: syncs the built site and invalidates the distribution, in the
#   `website-release` GitHub environment. Scoped to the exact bucket and
#   distribution.
#
# They live here, not in `envs/website`, so nothing CI applies can change what
# CI may do (docs/adr/0003-each-account-has-a-locally-applied-bootstrap-root.md).
#
# Every role ARN reaches GitHub as a secret, never a variable: secrets are
# masked in logs, and an ARN names the account.

locals {
  github_repository = "QuantumDancer/rottler.io"

  state_bucket_arn = module.state_bucket.bucket_arn
  main_state_arn   = "${local.state_bucket_arn}/main/terraform.tfstate"
  main_lock_arn    = "${local.state_bucket_arn}/main/terraform.tfstate.tflock"
  plans_arn        = "${local.state_bucket_arn}/plans/*"

  dns_role_arn      = "arn:aws:iam::${var.shared_services_account_id}:role/website-dns"
  dns_read_role_arn = "arn:aws:iam::${var.shared_services_account_id}:role/website-dns-read"

  # The OIDC `sub` each role trusts. A job with a GitHub environment gets
  # `environment:<name>` instead of its ref, so the apply and release roles are
  # reachable only from jobs that went through their environment's protection
  # rules (reviewer, `main`-only deployment branches).
  ci_role_subjects = {
    ci-plan = [
      "repo:${local.github_repository}:ref:refs/heads/main",
      "repo:${local.github_repository}:pull_request",
    ]
    ci-apply   = ["repo:${local.github_repository}:environment:website-terraform"]
    ci-release = ["repo:${local.github_repository}:environment:website-release"]
  }
}

# The site's bucket and distribution, read from the main root's state, so
# `ci-release` is scoped to their exact ARNs without committing them. This makes
# the bootstrap root depend on `envs/website` having been applied once.
data "terraform_remote_state" "website" {
  backend = "s3"

  config = {
    bucket = module.state_bucket.bucket
    key    = "main/terraform.tfstate"
    region = "us-east-1"
  }
}

# ------------------------------------------------------------------------------
# Trust
# ------------------------------------------------------------------------------

# `StringEquals` on `sub`, never `StringLike`: a wildcard there is how a fork's
# branch or another repository ends up trusted. `aud` pins the token to STS.
data "aws_iam_policy_document" "ci_trust" {
  for_each = local.ci_role_subjects

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = each.value
    }
  }
}

resource "aws_iam_role" "ci" {
  for_each = local.ci_role_subjects

  name               = each.key
  description        = "Deploy CI (${each.key}) for the website account, assumed by GitHub Actions"
  assume_role_policy = data.aws_iam_policy_document.ci_trust[each.key].json
}

# ------------------------------------------------------------------------------
# ci-plan
# ------------------------------------------------------------------------------

# AWS managed `ReadOnlyAccess` covers every refresh read, and the state read
# with it. It keeps up with new provider data sources, which a hand-written list
# would not. It also reads the bootstrap state, which holds nothing secret: no
# credentials, only ARNs and names.
resource "aws_iam_role_policy_attachment" "ci_plan_read_only" {
  role       = aws_iam_role.ci["ci-plan"].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "ci_plan" {
  # A plan on main holds the lock so it can't interleave with an apply. PR
  # plans run with `-lock=false` and never get here.
  statement {
    sid       = "MainStateLock"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [local.main_lock_arn]
  }

  # Put only: the apply job, as `ci-apply`, is the one that reads the plan back.
  statement {
    sid       = "StorePlan"
    actions   = ["s3:PutObject"]
    resources = [local.plans_arn]
  }

  statement {
    sid       = "AssumeDnsRead"
    actions   = ["sts:AssumeRole"]
    resources = [local.dns_read_role_arn]
  }
}

resource "aws_iam_role_policy" "ci_plan" {
  name   = "plan-website"
  role   = aws_iam_role.ci["ci-plan"].id
  policy = data.aws_iam_policy_document.ci_plan.json
}

# ------------------------------------------------------------------------------
# ci-apply
# ------------------------------------------------------------------------------

# Service-wide allows on S3, CloudFront, and ACM on purpose: the site is made of
# exactly those, and per-action lists break whenever a provider upgrade starts
# calling one more API. What keeps the role safe is the deny half below, not the
# allow half.
data "aws_iam_policy_document" "ci_apply" {
  # `not_resources` keeps the blanket S3 allow off the state bucket, whose
  # access is granted key by key in the statements after it.
  statement {
    sid           = "SiteServices"
    actions       = ["s3:*", "cloudfront:*", "acm:*"]
    not_resources = [local.state_bucket_arn, "${local.state_bucket_arn}/*"]
  }

  # The S3 backend lists the bucket on init to find workspaces, so init fails
  # without this one bucket-level action.
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]
  }

  statement {
    sid       = "MainState"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = [local.main_state_arn]
  }

  statement {
    sid       = "MainStateLock"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [local.main_lock_arn]
  }

  statement {
    sid       = "ReadPlan"
    actions   = ["s3:GetObject"]
    resources = [local.plans_arn]
  }

  statement {
    sid       = "AssumeDnsWrite"
    actions   = ["sts:AssumeRole"]
    resources = [local.dns_role_arn]
  }

  # --- Explicit denies --------------------------------------------------------
  #
  # A deny beats any allow, including one a future edit adds by mistake. Each
  # one closes a way for an apply to outgrow the role.

  # No identity work at all: with IAM, an apply could mint itself a broader
  # role or edit this one. Organizations and Account would let it reach beyond
  # the account. The site needs none of the three.
  statement {
    sid       = "DenyIdentityAndOrg"
    effect    = "Deny"
    actions   = ["iam:*", "organizations:*", "account:*"]
    resources = ["*"]
  }

  # `website-dns` is the only role it may become. Without this, a later allow
  # with a wildcard resource would let it hop to any role that trusts the
  # account.
  statement {
    sid           = "DenyOtherRoles"
    effect        = "Deny"
    actions       = ["sts:AssumeRole"]
    not_resources = [local.dns_role_arn]
  }

  # The bucket's own configuration (policy, versioning, lifecycle, deletion) is
  # bootstrap's to manage. Listing is the one bucket-level call init needs.
  statement {
    sid         = "DenyStateBucketConfig"
    effect      = "Deny"
    not_actions = ["s3:ListBucket"]
    resources   = [local.state_bucket_arn]
  }

  # The bootstrap state records this role's own definition. Rewriting it would
  # make the next local bootstrap apply plan from false data.
  statement {
    sid       = "DenyBootstrapState"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["${local.state_bucket_arn}/bootstrap/*"]
  }
}

resource "aws_iam_role_policy" "ci_apply" {
  name   = "apply-website"
  role   = aws_iam_role.ci["ci-apply"].id
  policy = data.aws_iam_policy_document.ci_apply.json
}

# ------------------------------------------------------------------------------
# ci-release
# ------------------------------------------------------------------------------

# What `make release ENV=website` touches: init plus `terraform output` for the
# build's SITE_URL and the deploy targets, `aws s3 sync --delete` into the site
# bucket, and one invalidation.
data "aws_iam_policy_document" "ci_release" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]
  }

  # Read only. `terraform output` neither locks nor writes.
  statement {
    sid       = "ReadMainState"
    actions   = ["s3:GetObject"]
    resources = [local.main_state_arn]
  }

  statement {
    sid       = "ListSiteBucket"
    actions   = ["s3:ListBucket"]
    resources = [data.terraform_remote_state.website.outputs.website_bucket_arn]
  }

  statement {
    sid       = "SyncSiteObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${data.terraform_remote_state.website.outputs.website_bucket_arn}/*"]
  }

  statement {
    sid       = "Invalidate"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [data.terraform_remote_state.website.outputs.cloudfront_distribution_arn]
  }
}

resource "aws_iam_role_policy" "ci_release" {
  name   = "release-website"
  role   = aws_iam_role.ci["ci-release"].id
  policy = data.aws_iam_policy_document.ci_release.json
}
