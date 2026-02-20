import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(THIS_DIR, "..");
const DOCS_INDEX = path.join(ROOT, "docs", "README.md");
const QUICKSTART = path.join(ROOT, "docs", "quickstart.md");
const TROUBLESHOOTING = path.join(ROOT, "docs", "troubleshooting.md");
const ROOT_README = path.join(ROOT, "README.md");

test("docs index includes quickstart and troubleshooting chapters", () => {
  const index = fs.readFileSync(DOCS_INDEX, "utf8");
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

test("root README links quickstart and troubleshooting docs", () => {
  const readme = fs.readFileSync(ROOT_README, "utf8");
  assert.match(readme, /docs\/quickstart\.md/);
  assert.match(readme, /docs\/troubleshooting\.md/);
});

test("root README quick start follows pnpm-based scaffold flow", () => {
  const readme = fs.readFileSync(ROOT_README, "utf8");
  assert.match(readme, /pnpm install/);
  assert.match(readme, /pnpm dev/);
});
