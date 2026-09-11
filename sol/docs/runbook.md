# Docs Runbook

Documentation deployment uses the root
[deploy-website.yml](../../.github/workflows/deploy-website.yml) workflow and
publishes `website/dist-docs` to the `luna` Cloudflare Worker.

## Diagnose a failed deployment

1. Identify the failed workflow run and its source commit.
2. Check whether dependency installation, workspace generation, compilation,
   Astra, Pagefind, or Wrangler failed.
3. Reproduce the build locally with `just build-doc` and `just smoke-docs`
   from `sol/`.
4. For deployment failures, verify the configured Cloudflare account and the
   workflow secrets `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`.
5. After fixing the failure, rerun the workflow for the intended source revision.

## Restore a previous version

Identify the last successful source revision, check it out in a separate local
checkout, and rebuild its documentation. Verify the resulting pages and search
index before deploying that checkout with `just release-doc` from `sol/`.
The current workflow does not provide a separate rollback job.

After deployment, verify the home page, a Sol documentation page, and a search
query on the public website.
