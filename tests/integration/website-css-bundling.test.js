// Regression test for the bug fixed in PR #47:
// `astra build` invoked from website/ produced a 143-byte fallback
// style.css instead of inlining astra/src/assets/styles/main.css
// (~47KB), because load_asset() in astra has no cwd-relative path that
// reaches <repo>/astra/src/assets when run from a docs directory. The
// fix in js/astra/bin/astra.js sets globalThis.__sol_assets_dir to
// short-circuit load_asset's lookup. If that override regresses, this
// test catches it before the website ships with broken styling.

import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, statSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..", "..");
const ASTRA_SHIM = path.join(ROOT, "js", "astra", "bin", "astra.js");
const WEBSITE_DIR = path.join(ROOT, "website");

test("astra build from website/ inlines full main.css", () => {
  const outDir = mkdtempSync(path.join(tmpdir(), "astra-css-regression-"));
  try {
    const result = spawnSync(
      process.execPath,
      [ASTRA_SHIM, "build", "--out", outDir],
      { cwd: WEBSITE_DIR, encoding: "utf-8" },
    );
    assert.equal(
      result.status,
      0,
      `astra build failed:\nstdout=${result.stdout}\nstderr=${result.stderr}`,
    );

    const stylePath = path.join(outDir, "assets", "style.css");
    const styleSize = statSync(stylePath).size;

    // Full minified main.css is ~47KB; the get_fallback_css() path
    // emits ~143 bytes. A 10KB threshold stays comfortably above the
    // fallback and below the live size, so theme refactors that trim
    // a few hundred bytes don't false-positive this test.
    assert.ok(
      styleSize > 10_000,
      `${stylePath} is ${styleSize} bytes — too small to contain ` +
        `astra/src/assets/styles/main.css. The shim probably failed to ` +
        `set globalThis.__sol_assets_dir, or load_asset's lookup ` +
        `chain regressed.`,
    );
  } finally {
    rmSync(outDir, { recursive: true, force: true });
  }
});
