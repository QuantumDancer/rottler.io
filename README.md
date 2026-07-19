# rottler.io

The personal website of Benjamin Rottler, built with [Astro](https://astro.build/)
as a fully static site and deployed on AWS (S3 + CloudFront).

## Repository layout

| Directory   | Purpose                              |
| ----------- | ------------------------------------ |
| `frontend/` | Astro static site                    |
| `infra/`    | Terraform for AWS resources (planned) |

## Local development

```sh
cd frontend
npm install   # install dependencies
npm run dev   # start the dev server at http://localhost:4321
npm run build # produce the static site in dist/
```
