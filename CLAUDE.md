# CLAUDE.md

The personal website of Benjamin Rottler (rottler.io): a fully static Astro 7
site on AWS S3 + CloudFront, rebuilding the Cloud Resume Challenge-era site at
`/home/benjamin/Code/rottler.io-legacy`.

## Layout and status

- `frontend/` — the Astro site.
- `infra/` — Terraform: reusable `modules/`, one root per environment under
  `envs/`. Only `envs/dev` exists: the site is live at dev.rottler.io in the
  legacy dev account, an **interim** validation stage. The target is prod-only
  under a new account structure.
- `project/` — gitignored private knowledge base. `project/direction.md` is the
  source of truth for goals, settled decisions, target AWS topology, and open
  items; read it before planning any work. `project/design/v1/` holds the
  Claude Design mockups the site was built from.
- `.scratch/` — gitignored specs and tickets (see Agent skills below).

The repo will be published on GitHub, so every committed line is public.
Account IDs, private infrastructure details, and planning notes belong in
`project/` or `.scratch/`.

## Verification

Tool versions are pinned in the root `mise.toml`, shared with CI
(`.github/workflows/ci.yml`, credential-free, on PRs and `main`). CI only calls
the commands below, so passing them locally predicts a green run.

- Frontend: `npm run build` in `frontend/`. There are no tests or linter; the
  build type-checks the content schemas.
- Infra: `make check` (fmt, validate, tflint). A fresh checkout runs
  `make check-init` first (init without the state backend). `make help` lists
  every target.
- Shell and workflows: `make lint` (shellcheck, actionlint).
- New Terraform root: add it to the `infra` job's `env` matrix in `ci.yml`,
  and its `infra (<env>)` check to the `main` ruleset's required checks.

## Git workflow

`main` is protected by a repository ruleset: changes land through a PR with
the CI checks green, history stays linear, and force-pushes are blocked. Work
on a branch, open a PR, and merge with rebase (`gh pr merge --rebase`); squash
only when a branch's commits are noise. Merge commits are disabled. Benjamin
can bypass the ruleset as admin; agents don't.

## Infra operations

All AWS work runs through the root `Makefile`, scoped to one environment via
`ENV=` (default `dev`):

- Changes go plan-file first: `make tf-plan` writes `<env>.tfplan`, that exact
  file is reviewed, then `make tf-apply` applies it.
- `make release` builds with the environment's own `SITE_URL` (from Terraform
  output) and deploys via `scripts/deploy.sh`, whose preflight guards the
  `aws s3 sync --delete`.
- The AWS provider stays pinned to the lockfile's 5.x (`~> 5.38`); run
  `terraform init` without `-upgrade`. Moving to 6.x is its own change, gated by
  clean before/after plans.

## Frontend architecture

**Design tokens** live in exactly one place, `frontend/src/styles/base.css`:
CSS custom properties on `:root` (dark, the default) with a full light override
under `[data-theme='light']`. The accent is one oklch hue variable `--ah`
(amber; teal/violet via `[data-accent]`). Theme switching is the `data-theme`
attribute on `<html>`, set pre-paint by an inline script in
`src/layouts/BaseLayout.astro`, which every page wraps. New styles reference the
tokens.

**Code blocks** use astro-expressive-code, configured in
`frontend/astro.config.mjs`:

- Frame chrome uses `var(--…)` references into base.css and follows the theme
  automatically.
- Syntax token colors are baked in by Shiki, so the two custom themes in the
  config mirror base.css's `--sx-*` values as literal hex. A `--sx-*` change is
  a two-place edit.
- `mdx()` stays registered after `expressiveCode()` in `integrations`;
  reversing the order silently disables Expressive Code inside MDX.

**Content.** Blog posts are the `blog` content collection
(`src/content.config.ts`, schema-validated frontmatter) served at `/writing/`.
Fetch posts through `getPublishedPosts()` in `src/lib/posts.ts`: it sorts
newest-first and drops `draft: true` posts from production builds while keeping
them visible in dev. RSS and the sitemap read from the same sources.

**Data modules** are the source of truth for facts: `src/data/site.ts`
(identity, nav, socials), `src/data/projects.ts`, `src/data/cv.ts`. Unconfirmed
facts carry `TODO(benjamin)` comments; resolve them with Benjamin.

## Agent skills

### Issue tracker

Local markdown under the gitignored `.scratch/<feature>/`. See
`docs/agents/issue-tracker.md`.

### Triage labels

The five canonical roles, unrenamed, recorded as a `Status:` line. See
`docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `GLOSSARY.md` plus `docs/adr/`. See `docs/agents/domain.md`.
