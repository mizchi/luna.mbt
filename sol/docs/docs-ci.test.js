import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";

const read = relative => fs.readFileSync(new URL(relative, import.meta.url), "utf8");

test("Sol verification includes docs, CLI, and examples", () => {
  const tasks = read("../justfile");
  assert.match(tasks, /^test-docs:/m);
  assert.match(tasks, /^ci:.*test-docs.*check-examples/m);
  assert.match(tasks, /^verify:.*check.*test.*test-docs.*test-cli-golden.*build/m);
});

test("the active monorepo workflow prepares and tests Sol", () => {
  const workflow = read("../../.github/workflows/sol.yaml");
  assert.match(workflow, /node scripts\/generate-examples\.mjs/);
  assert.match(workflow, /moon build --target js --release/);
  assert.match(workflow, /cd sol && pnpm test:e2e/);
  assert.match(workflow, /pnpm test:hydration/);
  assert.match(workflow, /pnpm test:mbt-e2e/);
});

test("docs tasks target the monorepo website with Astra", () => {
  const tasks = read("../justfile");
  assert.match(tasks, /cd \.\.\/website && node \.\.\/scripts\/run-cli\.mjs astra build/);
  assert.match(tasks, /^smoke-docs:/m);
  assert.match(tasks, /\.\.\/website\/dist-docs\/index\.html/);
});

test("the active website workflow builds Astra and the search index", () => {
  const workflow = read("../../.github/workflows/deploy-website.yml");
  assert.match(workflow, /working-directory: website/);
  assert.match(workflow, /node \.\.\/js\/astra\/bin\/astra\.js build/);
  assert.match(workflow, /pagefind --site website\/dist-docs/);
  assert.match(workflow, /workingDirectory: website/);
});

test("onboarding describes the Sol development flow", () => {
  const doc = read("onboarding.md");
  for (const command of ["sol new", "pnpm install", "pnpm dev", "sol build", "sol deploy", "just verify"]) {
    assert.ok(doc.includes(command), command);
  }
});
