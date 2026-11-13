# rottler.io

The personal website of Benjamin Rottler, built with [Astro](https://astro.build/)
as a fully static site and deployed on AWS (S3 + CloudFront), with the
infrastructure managed by Terraform.

## Repository layout

| Directory      | Purpose                                                   |
| -------------- | --------------------------------------------------------- |
| `frontend/`    | Astro static site                                         |
| `infra/`       | Terraform: reusable `modules/`, one root per environment under `envs/` |
| `scripts/`     | Deploy script behind `make deploy`                        |
| `docs/adr/`    | Architecture decision records                             |

## Local development

Tool versions (Node, Terraform, tflint, shellcheck, actionlint) are pinned in
`mise.toml` and shared with CI; install them with [mise](https://mise.jdx.dev):

```sh
mise install
cd frontend
npm install   # install dependencies
npm run dev   # start the dev server at http://localhost:4321
npm run build # produce the static site in dist/
```

## Infrastructure and deployment

Everything that touches AWS runs through the root `Makefile`, scoped to one
environment with `ENV=` (`make help` lists every target):

```sh
make check   ENV=dev   # terraform fmt, validate, and tflint
make tf-plan ENV=dev   # write the plan to infra/envs/dev/dev.tfplan
make tf-apply ENV=dev  # apply exactly that reviewed plan file
make release ENV=dev   # build with the environment's SITE_URL, then deploy
```

CI runs on every pull request and push to `main` without any AWS access: the
site build, `make check-init` + `make check` per Terraform root, and `make lint`
(shellcheck, actionlint). Renovate proposes dependency and tool updates weekly.

Changes are plan-file first: what gets reviewed is exactly what gets applied.
`make deploy` refuses to sync a missing or incomplete build, since the
underlying `aws s3 sync --delete` would otherwise empty the live bucket.

## License

The code in this repository is available under the [MIT License](LICENSE).

The site's content is not: blog posts (`frontend/src/content/`), the portrait
and other images (`frontend/src/assets/`), and the personal data in
`frontend/src/data/` are © Benjamin Rottler, all rights reserved.
