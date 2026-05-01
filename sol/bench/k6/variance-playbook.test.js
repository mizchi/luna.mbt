import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(THIS_DIR, "..", "..");
const README = path.join(ROOT, "bench", "k6", "README.md");
const SPEC = path.join(ROOT, "docs", "benchmarking.md");

test("k6 README documents high-load variance triage steps", () => {
  const readme = fs.readFileSync(README, "utf8");
  assert.match(readme, /高負荷時のばらつき切り分け/);
  assert.match(readme, /CPU.*固定|固定.*CPU/);
  assert.match(readme, /ウォームアップ/);
  assert.match(readme, /再計測|再実行|複数回実行/);
  assert.match(readme, /just bench-k6-quick/);
  assert.match(readme, /just bench-k6 .* 5/);
});

test("benchmarking spec includes the same variance triage policy", () => {
  const spec = fs.readFileSync(SPEC, "utf8");
  assert.match(spec, /高負荷時のばらつき切り分け/);
  assert.match(spec, /CPU.*固定|固定.*CPU/);
  assert.match(spec, /ウォームアップ/);
  assert.match(spec, /再計測|再実行|複数回実行/);
});
