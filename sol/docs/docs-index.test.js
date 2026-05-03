import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(THIS_DIR, "..");
const DOCS_INDEX = path.join(ROOT, "docs", "README.md");
const ROOT_README = path.join(ROOT, "README.md");

test("docs index defines reading order and links canonical docs", () => {
  const index = fs.readFileSync(DOCS_INDEX, "utf8");
  assert.match(index, /ドキュメントガイド|Documentation Guide/);
  assert.match(index, /Reading Order|読む順|学習順/);
  assert.match(index, /docs\/deploy\.md/);
  assert.match(index, /docs\/runbook\.md/);
  assert.match(index, /docs\/routing\.md/);
  assert.match(index, /docs\/benchmarking\.md/);
  assert.match(index, /docs\/hot-reload\.md/);
  assert.match(index, /docs\/migrate-from-mars\.md/);
  assert.match(index, /docs\/wasm-entrypoint\.md/);
});

test("root README links docs index", () => {
  const readme = fs.readFileSync(ROOT_README, "utf8");
  assert.match(readme, /docs\/README\.md/);
});
