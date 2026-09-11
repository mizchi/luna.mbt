// Smoke test: every MoonBit example passes `moon check` with its own backend.
// Sol-app-style examples (those with app/__gen__/ as a generated dep)
// need `sol generate` first, so the test runs that.
//
// Catches regressions where a workspace edit breaks downstream examples
// and verifies that their local workspaces remain usable on their own.

import test, { before } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..", "..");
const EXAMPLES = [
  { dir: "sol/examples/sol_api", needsGenerate: true },
  { dir: "sol/examples/sol_sqlite", needsGenerate: true },
  { dir: "sol/examples/sol_app", needsGenerate: true, islands: ["contact_form", "counter", "wc_counter"] },
  { dir: "sol/examples/sol_auth", needsGenerate: true, islands: ["contact_form", "counter", "wc_counter"] },
  { dir: "sol/examples/sol_todo", needsGenerate: true, islands: ["todo_list"] },
  { dir: "astra/examples/sol_docs", needsGenerate: false },
  { dir: "astra/examples/sol_blog", needsGenerate: false },
  { dir: "astra/examples/sol_api_ref", needsGenerate: false },
  { dir: "astra/examples/sol_changelog", needsGenerate: false },
  { dir: "astra/examples/sol_components_demo", needsGenerate: false },
  { dir: "astra/examples/sol_docs_search", needsGenerate: false },
  { dir: "astra/examples/sol_landing", needsGenerate: false },
  { dir: "astra/examples/sol_portfolio", needsGenerate: false },
  { dir: "js/stella/examples/stella-component", needsGenerate: false },
  { dir: "sol/examples/wasm_island_poc", needsGenerate: false, target: "wasm-gc" },
];

before(() => {
  // Remove all generated packages together: building the generator through the
  // root workspace would fail here, even if its JS artifact were cached.
  for (const { dir, needsGenerate } of EXAMPLES) {
    if (needsGenerate) {
      fs.rmSync(path.join(ROOT, dir, "app/__gen__"), { recursive: true, force: true });
    }
  }
  const generated = spawnSync(process.execPath, ["scripts/generate-examples.mjs"], {
    cwd: ROOT,
    encoding: "utf8",
    timeout: 120_000,
  });
  assert.equal(generated.status, 0, `example generation failed:\n${generated.stdout}\n${generated.stderr}`);
});

for (const { dir, target = "js", islands } of EXAMPLES) {
  test(`${dir}: moon check passes`, { timeout: 120_000 }, () => {
    const exampleDir = path.join(ROOT, dir);
    assert.ok(
      fs.existsSync(exampleDir),
      `example dir missing: ${exampleDir}`,
    );

    if (islands) {
      assert.ok(fs.existsSync(path.join(exampleDir, "app/__gen__/client/moon.pkg")), "Island client package must be generated");
      const manifest = JSON.parse(fs.readFileSync(path.join(exampleDir, ".sol/prod/manifest.json"), "utf8"));
      assert.deepEqual(manifest.islands.map((island) => island.name).sort(), [...islands].sort());
    }

    const check = spawnSync("moon", ["check", "--target", target], {
      cwd: exampleDir,
      encoding: "utf8",
      timeout: 120_000,
    });
    assert.equal(
      check.status,
      0,
      `moon check failed for ${dir}\nstdout:\n${check.stdout}\nstderr:\n${check.stderr}`,
    );
  });
}
