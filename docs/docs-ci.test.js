import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(THIS_DIR, "..");
const JUSTFILE = path.join(ROOT, "justfile");
const CHECK_WORKFLOW = path.join(ROOT, ".github", "workflows", "check.yaml");

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

test("GitHub check workflow runs docs tests", () => {
  const workflow = fs.readFileSync(CHECK_WORKFLOW, "utf8");
  assert.match(workflow, /name:\s*docs tests/i);
  assert.match(
    workflow,
    /node --test docs\/docs-index\.test\.js docs\/docs-chapters\.test\.js docs\/docs-build-paths\.test\.js docs\/docs-ci\.test\.js/
  );
});
