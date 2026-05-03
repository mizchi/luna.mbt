# Docs Deploy Guide

This covers the two-stage deployment of `website/dist-docs` to Cloudflare Workers.

## Purpose

- Verify preview on PRs
- Update production on `main`
- Share build results as artifacts and deploy the same artifact

## GitHub Actions Configuration

Target workflow: `.github/workflows/docs.yaml`

1. `build`
   - Builds docs
   - Creates `docs-dist` artifact
2. `deploy-preview`
   - Runs on `pull_request`
   - Deploys preview with worker name `sol-docs-preview-pr-<PR number>`
3. `deploy-production`
   - Runs on `push` to `main` or `workflow_dispatch` (with empty `rollback_ref`)
   - Deploys to production
   - Stops with a guard if `changed_files_count` exceeds the threshold
4. `rollback-production`
   - Runs on `workflow_dispatch` with `rollback_ref` specified
   - `rollback_mode=dry-run` is the default
   - Production deployment requires `rollback_mode=apply` and `rollback_confirm=ROLLBACK_PRODUCTION`

The workflow has `concurrency` configured, so older runs of the same type are automatically cancelled (`workflow_dispatch` runs are not cancelled to protect manual operations).

Each deploy job outputs an execution summary to `GITHUB_STEP_SUMMARY`.
The summary outputs `worker_name` and `workers_url_hint` (the `<your-subdomain>` part varies by environment).
The build job saves a `docs-build-meta` artifact (ref/sha/file count, etc.).
For diff tracking, a `docs-change-meta` artifact (comparison base/changed file list) is also saved.
`docs-build-meta` includes `docs_file_count` and `docs_dist_sha256`, and `deploy-preview` / `deploy-production` verify artifact integrity (sha256 + count) before deploying.
`deploy-production` outputs `### Deploy guard decision`.
`Resolve guard block issues` appends `### Guard issue resolve` and outputs `target_issue`, `stale_issue_count`, `stale_issue_numbers`.

## Overriding the Large Diff Guard

If the `build`'s `Evaluate change volume warning` shows a warning, production deploy via `push` is blocked. To proceed, re-run via `workflow_dispatch` with the following:

- `rollback_ref`: empty
- `override_change_warning`: `FORCE_DEPLOY_LARGE_CHANGE`

Production deploy via `workflow_dispatch` always stops if the override token is not specified.

## Threshold Configuration

The diff threshold can be set via the repository variable `DOCS_CHANGE_WARN_THRESHOLD`. If unset or invalid, the default `200` is used.

`docs-change-warning` outputs the following:

- `threshold`
- `threshold_source` (`repo_var` or `default`)

## Guard Block Notification

When a production deploy on `push` to `main` is blocked by the guard, the workflow automatically creates an Issue with the `docs-deploy-guard` label. If an open Issue with the same ref already exists, it is reused and a comment is appended (duplicate comments for the same sha are not created). If there are multiple open Issues for the same ref, they are consolidated into the latest one and older issues are automatically closed.
Issues/comments include the following as an integrity snapshot:

- `integrity_status`
- `expected_file_count`, `expected_sha256`
- `verified_file_count`, `verified_sha256`
- Search keys: `docs_ref=<ref>`, `docs_sha=<sha>`

When a production deploy succeeds, the latest open `docs-deploy-guard` Issue for the same ref is automatically closed.

## Required Secrets

- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`

When not configured, the deploy step is skipped within the workflow.

## Local Pre-verification

```bash
just verify
```

Next, build docs locally and verify the artifacts.

```bash
just build-doc
```

## Failure Isolation

1. Build failure: Check the `build` job logs
2. Deploy failure: Check whether secrets are set and the `wrangler` execution logs
3. Integrity check failure: Check the expected/actual (count, sha256) in `Verify docs artifact integrity (preview|production)`
4. Preview not reflected: Check the deploy result for `worker_name=sol-docs-preview-pr-<PR number>`

For more detailed incident response, see `docs/runbook.md`.
