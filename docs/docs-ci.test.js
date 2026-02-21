import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(THIS_DIR, "..");
const JUSTFILE = path.join(ROOT, "justfile");
const CHECK_WORKFLOW = path.join(ROOT, ".github", "workflows", "check.yaml");
const DOCS_WORKFLOW = path.join(ROOT, ".github", "workflows", "docs.yaml");
const ONBOARDING = path.join(ROOT, "docs", "onboarding.md");

test("justfile defines docs test target", () => {
  const justfile = fs.readFileSync(JUSTFILE, "utf8");
  assert.match(justfile, /^test-docs:/m);
  assert.match(
    justfile,
    /node --test docs\/docs-index\.test\.js docs\/docs-chapters\.test\.js docs\/docs-build-paths\.test\.js docs\/docs-ci\.test\.js/m
  );
});

test("ci target includes docs tests", () => {
  const justfile = fs.readFileSync(JUSTFILE, "utf8");
  assert.match(justfile, /^ci:.*test-docs/m);
});

test("GitHub check workflow follows just bootstrap -> just verify", () => {
  const workflow = fs.readFileSync(CHECK_WORKFLOW, "utf8");
  assert.match(workflow, /extractions\/setup-just@v3/);
  assert.match(workflow, /run:\s*just bootstrap/);
  assert.match(workflow, /run:\s*just verify/);
});

test("justfile defines bootstrap and verify targets", () => {
  const justfile = fs.readFileSync(JUSTFILE, "utf8");
  assert.match(justfile, /^bootstrap:/m);
  assert.match(justfile, /^test-cli-golden:/m);
  assert.match(justfile, /^verify:.*check.*test.*test-docs.*test-cli-golden.*build/m);
});

test("justfile defines smoke-docs target", () => {
  const justfile = fs.readFileSync(JUSTFILE, "utf8");
  assert.match(justfile, /^smoke-docs:/m);
  assert.match(justfile, /website\/dist-docs\/index\.html/);
});

test("onboarding doc defines the golden path", () => {
  const onboarding = fs.readFileSync(ONBOARDING, "utf8");
  assert.match(onboarding, /Onboarding|オンボーディング/);
  assert.match(onboarding, /sol new/);
  assert.match(onboarding, /pnpm install/);
  assert.match(onboarding, /pnpm dev/);
  assert.match(onboarding, /sol build/);
  assert.match(onboarding, /sol deploy/);
  assert.match(onboarding, /just verify/);
});

test("GitHub docs workflow defines preview and production deploy jobs", () => {
  const workflow = fs.readFileSync(DOCS_WORKFLOW, "utf8");
  assert.match(workflow, /^concurrency:/m);
  assert.match(workflow, /cancel-in-progress:\s*\$\{\{\s*github\.event_name != 'workflow_dispatch'\s*\}\}/);
  assert.match(workflow, /^  pull_request:/m);
  assert.match(workflow, /^  deploy-preview:/m);
  assert.match(workflow, /^  deploy-production:/m);
  assert.match(workflow, /if:\s*github\.event_name == 'pull_request'/);
  assert.match(
    workflow,
    /if:\s*\(github\.event_name == 'push' && github\.ref == 'refs\/heads\/main'\)\s*\|\|\s*\(github\.event_name == 'workflow_dispatch' && github\.event\.inputs\.rollback_ref == ''\)/
  );
  assert.match(
    workflow,
    /--name=sol-docs-preview-pr-\$\{\{ github\.event\.pull_request\.number \}\}/
  );
  assert.match(workflow, /--name=sol-docs/);
});

test("GitHub docs workflow deploy jobs reuse built artifact", () => {
  const workflow = fs.readFileSync(DOCS_WORKFLOW, "utf8");
  assert.match(workflow, /uses:\s*actions\/upload-artifact@v4/);
  assert.match(workflow, /uses:\s*actions\/download-artifact@v4/);
  assert.match(
    workflow,
    /wrangler(@\d+)? deploy --config=wrangler\.json --name=sol-docs --assets=website\/dist-docs/
  );
  assert.match(
    workflow,
    /wrangler(@\d+)? deploy --config=wrangler\.json --name=sol-docs-preview-pr-\$\{\{ github\.event\.pull_request\.number \}\} --assets=website\/dist-docs/
  );
});

test("GitHub docs workflow generates deploy metadata and publishes summaries", () => {
  const workflow = fs.readFileSync(DOCS_WORKFLOW, "utf8");
  assert.match(workflow, /issues:\s*write/);
  assert.match(workflow, /name:\s*Generate deploy metadata/);
  assert.match(workflow, /docs_dist_sha256=/);
  assert.match(workflow, /docs_file_count=/);
  assert.match(workflow, /name:\s*Generate change summary metadata/);
  assert.match(workflow, /name:\s*Evaluate change volume warning/);
  assert.match(workflow, /name:\s*Upload deploy metadata artifact/);
  assert.match(workflow, /name:\s*Upload change metadata artifact/);
  assert.match(workflow, /name:\s*Upload rollback metadata artifact/);
  assert.match(workflow, /name:\s*Publish preview deploy summary/);
  assert.match(workflow, /name:\s*Verify docs artifact integrity \(preview\)/);
  assert.match(workflow, /name:\s*Publish production deploy summary/);
  assert.match(workflow, /name:\s*Verify docs artifact integrity \(production\)/);
  assert.match(workflow, /name:\s*Publish rollback deploy summary/);
  assert.match(workflow, /docs-build-meta/);
  assert.match(workflow, /docs-change-meta/);
  assert.match(workflow, /docs-rollback-meta/);
  assert.match(
    workflow,
    /worker_name:\s*sol-docs-preview-pr-\$\{\{ github\.event\.pull_request\.number \}\}/
  );
  assert.match(workflow, /worker_name:\s*sol-docs/);
  assert.match(workflow, /workers_url_hint/);
  assert.match(workflow, /### Change metadata/);
  assert.match(workflow, /### Change volume warning/);
  assert.match(workflow, /### Deploy guard decision/);
  assert.match(workflow, /DOCS_CHANGE_WARN_THRESHOLD/);
  assert.match(workflow, /DEFAULT_CHANGE_WARN_THRESHOLD=200/);
  assert.match(workflow, /THRESHOLD_SOURCE="repo_var"/);
  assert.match(workflow, /THRESHOLD_SOURCE="default"/);
  assert.match(workflow, /threshold_source=\$\{THRESHOLD_SOURCE\}/);
  assert.match(workflow, /changed_files_count exceeds threshold/);
  assert.match(workflow, /FORCE_DEPLOY_LARGE_CHANGE/);
  assert.match(workflow, /name:\s*Notify guard block issue/);
  assert.match(workflow, /name:\s*Resolve guard block issues/);
  assert.match(workflow, /actions\/github-script@v7/);
  assert.match(workflow, /const buildMetaPath = "tmp\/docs-build-meta\.txt"/);
  assert.match(workflow, /const artifactVerifyPath = "tmp\/docs-artifact-verify\.txt"/);
  assert.match(workflow, /const parseKvFile = \(filepath\) =>/);
  assert.match(workflow, /const buildKv = parseKvFile\(buildMetaPath\)/);
  assert.match(workflow, /const artifactKv = parseKvFile\(artifactVerifyPath\)/);
  assert.match(workflow, /Artifact integrity:/);
  assert.match(workflow, /docs_ref=\$\{process\.env\.GITHUB_REF\}/);
  assert.match(workflow, /docs_sha=\$\{process\.env\.GITHUB_SHA\}/);
  assert.match(workflow, /integrity_status/);
  assert.match(workflow, /expected_sha256/);
  assert.match(workflow, /verified_sha256/);
  assert.match(workflow, /const existingRefIssue = sortedRefIssues\[0\]/);
  assert.match(workflow, /existingIssueBody\.includes\(`- ref: \$\{process\.env\.GITHUB_REF\}`\)/);
  assert.match(workflow, /github\.rest\.issues\.listComments/);
  assert.match(workflow, /currentShaCommentExists/);
  assert.match(workflow, /issue_number:\s*existingRefIssue\.number/);
  assert.match(workflow, /existing ref issue already has current sha comment/);
  assert.match(workflow, /const existing = await github\.paginate\(github\.rest\.issues\.listForRepo/);
  assert.match(workflow, /const matchingRefIssues = existing\.filter/);
  assert.match(workflow, /const sortedRefIssues = matchingRefIssues\.sort/);
  assert.match(workflow, /const duplicateRefIssues = sortedRefIssues\.slice\(1\)/);
  assert.match(workflow, /for \(const duplicateIssue of duplicateRefIssues\)/);
  assert.match(workflow, /Closed automatically because a newer docs guard issue exists for the same ref\./);
  assert.match(workflow, /skip issue notification: reused issue/);
  assert.match(workflow, /github\.rest\.issues\.update/);
  assert.match(workflow, /state:\s*"closed"/);
  assert.match(workflow, /issueBody\s*=\s*issue\.body\s*\|\|\s*""/);
  assert.match(workflow, /issueBody\.includes\(`- ref: \$\{process\.env\.GITHUB_REF\}`\)/);
  assert.match(workflow, /const sortedTargets = targets\.sort/);
  assert.match(workflow, /const targetIssue = sortedTargets\[0\]/);
  assert.match(workflow, /issue_number:\s*targetIssue\.number/);
  assert.match(workflow, /closed docs guard issue #\$\{targetIssue\.number\}/);
  assert.match(workflow, /### Guard issue resolve/);
  assert.match(workflow, /stale_issue_count/);
  assert.match(workflow, /stale_issue_numbers/);
  assert.match(workflow, /target_issue/);
  assert.match(workflow, /docs-deploy-guard/);
  assert.match(workflow, /GITHUB_STEP_SUMMARY/);
});

test("GitHub docs workflow runs smoke tests and defines rollback job", () => {
  const workflow = fs.readFileSync(DOCS_WORKFLOW, "utf8");
  assert.match(workflow, /name:\s*Smoke test built docs/);
  assert.match(workflow, /run:\s*just smoke-docs/);
  assert.match(workflow, /^  rollback-production:/m);
  assert.match(workflow, /^      rollback_ref:/m);
  assert.match(workflow, /^      rollback_mode:/m);
  assert.match(workflow, /^      rollback_confirm:/m);
  assert.match(workflow, /^      override_change_warning:/m);
  assert.match(workflow, /-\s*dry-run/);
  assert.match(workflow, /-\s*apply/);
  assert.match(workflow, /name:\s*Guard production deploy on large change/);
  assert.match(workflow, /name:\s*Rollback dry run \(no deploy\)/);
  assert.match(workflow, /name:\s*Guard rollback apply confirmation/);
  assert.match(
    workflow,
    /if:\s*\$\{\{\s*github\.event\.inputs\.rollback_mode == 'dry-run'\s*\}\}/
  );
  assert.match(
    workflow,
    /Command:\s*pnpm dlx wrangler@4 deploy --config=wrangler\.json --name=sol-docs --assets=website\/dist-docs/
  );
  assert.match(
    workflow,
    /if:\s*\$\{\{\s*github\.event\.inputs\.rollback_mode == 'apply' && github\.event\.inputs\.rollback_confirm != 'ROLLBACK_PRODUCTION'\s*\}\}/
  );
  assert.match(
    workflow,
    /if:\s*github\.event_name == 'workflow_dispatch' && github\.event\.inputs\.rollback_ref != ''/
  );
});
