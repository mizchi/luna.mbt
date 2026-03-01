# Docs Runbook

This defines incident response and rollback procedures for docs deployment.

## Scope

- Workflow: `.github/workflows/docs.yaml`
- Deployment target: Cloudflare Workers (`sol-docs`)

## Monitoring Points

1. Whether the GitHub Actions `docs` workflow has failed
2. Execution logs for `deploy-preview` / `deploy-production` / `rollback-production`
3. Deploy summary in `GITHUB_STEP_SUMMARY`
4. Display of `worker_name` / `workers_url_hint` and reachability of the public URL
5. `decision` (allow/block) in `### Deploy guard decision`
6. Whether auto-cancellation by `concurrency` occurred (whether the intended run remains)
7. `status=ok` in `### Artifact integrity` (`sha256` and file count match)
8. `target_issue` / `stale_issue_count` / `stale_issue_numbers` in `### Guard issue resolve`

## Pre-checks

Perform minimum local verification.

```bash
just verify
just build-doc
just smoke-docs
```

## Initial Incident Response

1. Identify the most recent failed job
2. Classify the failure stage (build / smoke / deploy)
3. Verify that `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` are configured
4. Check the `docs-build-meta` / `docs-change-meta` artifacts and step summary
   - Check `docs_file_count` / `docs_dist_sha256` in `docs-build-meta`
5. Check expected/actual (count, sha256) in `Verify docs artifact integrity (preview|production)`
6. Check `level` / `threshold` / `threshold_source` in `docs-change-warning` and `decision` in `docs-deploy-guard`
7. Check the state of Issues with the `docs-deploy-guard` label (on block: created or comment appended to the same ref, no duplicate comments for the same sha; on success: the latest issue for the same ref is closed)
   - Check `integrity_status`, `expected_sha256`, `verified_sha256` in the issue body/comments
   - Verify that you can track the relevant issue/comment using search keys `docs_ref=<ref>`, `docs_sha=<sha>`
   - Verify that when there are multiple open issues for the same ref, they are consolidated into the latest one and older issues are automatically closed
8. If the impact is significant, perform a rollback

## When Blocked by the Large Diff Guard

If `Guard production deploy on large change` fails, deploy manually as follows:

1. Review the diff content and confirm it is safe to deploy
2. Run the `docs` workflow via `workflow_dispatch` in GitHub Actions
3. Leave `rollback_ref` empty (normal production deploy)
4. Set `override_change_warning=FORCE_DEPLOY_LARGE_CHANGE`
5. Confirm that `### Deploy guard decision` shows `decision=allow`
6. Confirm that after success, the latest `docs-deploy-guard` Issue for the same ref is automatically closed

When deploying to production via `workflow_dispatch`, this override token is always required.

If `threshold_source=default`, the repository variable `DOCS_CHANGE_WARN_THRESHOLD` is unset or invalid. Correct the value if needed and re-run.

## Rollback Procedure (Production)

Run the `docs` workflow via `workflow_dispatch` and specify `rollback_ref`.

1. Determine the target ref for recovery (tag / commit / branch)
2. Manually run the `docs` workflow in GitHub Actions
3. Enter the recovery target ref in `rollback_ref`
4. First run with `rollback_mode=dry-run` and confirm the dry-run completion of `rollback-production`
5. Only if production deployment is needed, set `rollback_mode=apply` and enter `rollback_confirm=ROLLBACK_PRODUCTION`, then run
6. Check `worker_name=sol-docs` and `workers_url_hint` in the summary, and open the production URL to confirm recovery

If `rollback_ref` is empty, the normal build flow is executed.

## Recovery Verification

1. `index.html` is being served
2. Main pages return 200
3. The diff from the latest deploy matches expectations

## Post-incident Actions

1. Document the incident cause in `docs/troubleshooting.md` or related documentation
2. Add smoke test conditions to `docs.yaml` if needed
