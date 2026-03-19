import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(THIS_DIR, "..");
const DOCS_INDEX = path.join(ROOT, "docs", "README.md");
const QUICKSTART = path.join(ROOT, "docs", "quickstart.md");
const DEPLOY = path.join(ROOT, "docs", "deploy.md");
const RUNBOOK = path.join(ROOT, "docs", "runbook.md");
const TROUBLESHOOTING = path.join(ROOT, "docs", "troubleshooting.md");
const ROOT_README = path.join(ROOT, "README.md");

test("docs index includes quickstart and troubleshooting chapters", () => {
  const index = fs.readFileSync(DOCS_INDEX, "utf8");
  assert.match(index, /docs\/deploy\.md/);
  assert.match(index, /docs\/runbook\.md/);
  assert.match(index, /docs\/quickstart\.md/);
  assert.match(index, /docs\/troubleshooting\.md/);
});

test("quickstart doc covers minimum end-to-end commands", () => {
  const quickstart = fs.readFileSync(QUICKSTART, "utf8");
  assert.match(quickstart, /Quickstart|クイックスタート/);
  assert.match(quickstart, /sol new/);
  assert.match(quickstart, /sol dev/);
  assert.match(quickstart, /sol build/);
  assert.match(quickstart, /sol serve/);
});

test("troubleshooting doc includes checks for routing and benchmark issues", () => {
  const troubleshooting = fs.readFileSync(TROUBLESHOOTING, "utf8");
  assert.match(troubleshooting, /Troubleshooting|トラブルシューティング/);
  assert.match(troubleshooting, /routing|ルーティング/i);
  assert.match(troubleshooting, /benchmark|ベンチ/i);
  assert.match(troubleshooting, /docs\/routing\.md/);
  assert.match(troubleshooting, /docs\/benchmarking\.md/);
});

test("deploy and runbook docs describe large-change deploy guard", () => {
  const deploy = fs.readFileSync(DEPLOY, "utf8");
  const runbook = fs.readFileSync(RUNBOOK, "utf8");
  assert.match(deploy, /override_change_warning/);
  assert.match(deploy, /FORCE_DEPLOY_LARGE_CHANGE/);
  assert.match(deploy, /DOCS_CHANGE_WARN_THRESHOLD/);
  assert.match(deploy, /docs-deploy-guard/);
  assert.match(deploy, /close|クローズ/i);
  assert.match(deploy, /同じ ref|same ref/i);
  assert.match(deploy, /再利用|reuse|コメント/i);
  assert.match(deploy, /最新|latest|集約|consolidat/i);
  assert.match(deploy, /同じ sha|same sha/i);
  assert.match(deploy, /整合性|integrity|sha256/i);
  assert.match(deploy, /integrity_status|expected_sha256|verified_sha256/i);
  assert.match(deploy, /docs_ref=|docs_sha=|検索|search/i);
  assert.match(deploy, /stale_issue_count|stale_issue_numbers|summary|サマリ/i);
  assert.match(deploy, /concurrency|同時実行/i);
  assert.match(runbook, /DOCS_CHANGE_WARN_THRESHOLD/);
  assert.match(runbook, /FORCE_DEPLOY_LARGE_CHANGE/);
  assert.match(runbook, /docs-deploy-guard/);
  assert.match(runbook, /close|クローズ/i);
  assert.match(runbook, /同じ sha|same sha/i);
  assert.match(runbook, /整合性|integrity|sha256/i);
  assert.match(runbook, /integrity_status|expected_sha256|verified_sha256/i);
  assert.match(runbook, /docs_ref=|docs_sha=|検索|search/i);
  assert.match(runbook, /stale_issue_count|stale_issue_numbers|summary|サマリ/i);
  assert.match(runbook, /同じ ref|same ref/i);
  assert.match(runbook, /最新|latest|集約|consolidat/i);
  assert.match(runbook, /成功|successful|close.*最新|latest/i);
  assert.match(runbook, /再利用|reuse|comment|コメント/i);
  assert.match(runbook, /concurrency|同時実行/i);
});

test("root README links quickstart and troubleshooting docs", () => {
  const readme = fs.readFileSync(ROOT_README, "utf8");
  assert.match(readme, /docs\/onboarding\.md/);
  assert.match(readme, /docs\/deploy\.md/);
  assert.match(readme, /docs\/runbook\.md/);
  assert.match(readme, /docs\/quickstart\.md/);
  assert.match(readme, /docs\/troubleshooting\.md/);
});

test("root README quick start follows pnpm-based scaffold flow", () => {
  const readme = fs.readFileSync(ROOT_README, "utf8");
  assert.match(readme, /pnpm install/);
  assert.match(readme, /pnpm dev/);
});
