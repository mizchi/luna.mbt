# Docs Deploy Guide

The monorepo documentation lives in `website/` and is built with Astra.
The active workflow is [deploy-website.yml](../../.github/workflows/deploy-website.yml).
It deploys `website/dist-docs` to the Cloudflare Workers static-assets worker
`luna`, configured in [website/wrangler.json](../../website/wrangler.json).

## Local verification

From `sol/`:

```bash
just build-doc
just smoke-docs
```

`build-doc` builds the local Astra CLI, generates the site, and runs Pagefind.
`dev-doc` serves the same website locally; `lint-doc` checks its MoonBit examples.

## Deployment

The workflow runs when a `luna-v*` GitHub release is published, or through
`workflow_dispatch`. It installs dependencies, generates the Sol examples,
builds the workspace and npm packages, runs Astra and Pagefind, and deploys
using `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`.

For a manual local deployment after verification, run `just release-doc` from
`sol/`. This deploys the shared documentation website. Application deployment
is separate: use `sol deploy --help` from the application directory.

The nested `sol/.github/workflows/` files describe the former standalone
repository. GitHub Actions uses the workflows at the monorepo root.
