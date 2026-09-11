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
const ROUTING = path.join(ROOT, "docs", "routing.md");
const WORKER_AUTH = path.join(ROOT, "docs", "worker-auth.md");
const ROOT_README = path.join(ROOT, "README.md");

test("docs index includes quickstart and troubleshooting chapters", () => {
  const index = fs.readFileSync(DOCS_INDEX, "utf8");
  assert.match(index, /docs\/deploy\.md/);
  assert.match(index, /docs\/runbook\.md/);
  assert.match(index, /docs\/quickstart\.md/);
  assert.match(index, /docs\/worker-auth\.md/);
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

test("routing doc defines ownership manifest, raw responses, and error ownership", () => {
  const routing = fs.readFileSync(ROUTING, "utf8");
  assert.match(routing, /route_ownership_manifest/);
  assert.match(routing, /raw_get/);
  assert.match(routing, /Raw `Response`/);
  assert.match(routing, /404/);
  assert.match(routing, /500/);
  assert.match(routing, /Sol page routes own HTML/);
  assert.match(routing, /Sol API routes own JSON/);
  assert.match(routing, /Host Worker routes own/);
});

test("routing doc covers route and component asset attachment", () => {
  const routing = fs.readFileSync(ROUTING, "utf8");
  assert.match(routing, /Route And Component Assets/);
  assert.match(routing, /with_client_script/);
  assert.match(routing, /with_style/);
  assert.match(routing, /with_assets/);
  assert.match(routing, /assets\(/);
  assert.match(routing, /deterministic/);
  assert.match(routing, /deduplicated/);
  assert.match(routing, /\/static\//);
});

test("worker auth doc covers route middleware and host Worker composition", () => {
  const doc = fs.readFileSync(WORKER_AUTH, "utf8");
  assert.match(doc, /Authorization/);
  assert.match(doc, /custom header/i);
  assert.match(doc, /Cloudflare env/);
  assert.match(doc, /with_mw/);
  assert.match(doc, /JSON error/);
  assert.match(doc, /HTML|redirect/i);
  assert.match(doc, /worker.entry.mjs/);
  assert.match(doc, /wrangler dev/);
});

test("deploy and runbook docs identify the active monorepo deployment", () => {
  for (const file of [DEPLOY, RUNBOOK]) {
    const doc = fs.readFileSync(file, "utf8");
    assert.match(doc, /deploy-website\.yml/);
    assert.match(doc, /website\/dist-docs/);
    assert.doesNotMatch(doc, /FORCE_DEPLOY_LARGE_CHANGE|docs-deploy-guard/);
  }
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
