// Smoke test: every example directory passes `moon check --target js`.
// Sol-app-style examples (those with app/__gen__/ as a generated dep)
// need `sol generate` first, so the test runs that.
//
// Catches regressions where a workspace edit breaks downstream examples
// that aren't part of the workspace test count.

import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..", "..");
const SOL_CLI_DEBUG = path.join(
  ROOT,
  "_build",
  "js",
  "debug",
  "build",
  "mizchi",
  "sol",
  "cmd",
  "sol_js",
  "sol_js.js",
);

function ensureSolCliBuilt() {
  if (fs.existsSync(SOL_CLI_DEBUG)) return;
  const r = spawnSync("moon", ["build", "--target", "js"], {
    cwd: ROOT,
    encoding: "utf8",
  });
  assert.equal(r.status, 0, `moon build failed: ${r.stderr}`);
}

const EXAMPLES = [
  { dir: "sol/examples/sol_api", needsGenerate: false },
  { dir: "sol/examples/sol_sqlite", needsGenerate: false },
  { dir: "sol/examples/sol_app", needsGenerate: true },
  { dir: "sol/examples/sol_auth", needsGenerate: true },
  { dir: "sol/examples/sol_todo", needsGenerate: true },
  { dir: "astra/examples/sol_docs", needsGenerate: false },
  { dir: "astra/examples/sol_blog", needsGenerate: false },
];

for (const { dir, needsGenerate } of EXAMPLES) {
  test(`${dir}: moon check passes`, { timeout: 120_000 }, () => {
    const exampleDir = path.join(ROOT, dir);
    assert.ok(
      fs.existsSync(exampleDir),
      `example dir missing: ${exampleDir}`,
    );

    if (needsGenerate) {
      ensureSolCliBuilt();
      // Wipe stale gen artifacts so we exercise the full sol generate
      // pipeline rather than a possibly-stale __gen__ from a prior run.
      fs.rmSync(path.join(exampleDir, "app", "__gen__"), {
        recursive: true,
        force: true,
      });
      const gen = spawnSync("node", [SOL_CLI_DEBUG, "generate"], {
        cwd: exampleDir,
        encoding: "utf8",
      });
      assert.equal(
        gen.status,
        0,
        `sol generate failed for ${dir}\nstdout:\n${gen.stdout}\nstderr:\n${gen.stderr}`,
      );
    }

    const check = spawnSync("moon", ["check", "--target", "js"], {
      cwd: exampleDir,
      encoding: "utf8",
    });
    assert.equal(
      check.status,
      0,
      `moon check failed for ${dir}\nstdout:\n${check.stdout}\nstderr:\n${check.stderr}`,
    );
  });
}
