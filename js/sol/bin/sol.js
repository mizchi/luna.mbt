#!/usr/bin/env node
// Entry point for the @luna_ui/sol npm wrapper.
//
// Primary install path is `moon install mizchi/sol/cmd/sol`; this npm
// wrapper exists for users who already have node but not moon.
//
// Resolution order:
//   1. ../dist/sol.js — populated by scripts/build-release.mjs at
//      publish time. This is the path used in real npm installs.
//   2. ../../../_build/js/release/build/mizchi/sol/cmd/sol_js/sol_js.js —
//      workspace fallback so the shim stays usable from a clean
//      monorepo checkout (after `moon build --target js --release`),
//      which is what tests/integration/* relies on.
import path from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const distEntry = path.resolve(__dirname, "../dist/sol.js");
const workspaceEntry = path.resolve(
  __dirname,
  "../../../_build/js/release/build/mizchi/sol/cmd/sol_js/sol_js.js",
);

const entry = existsSync(distEntry)
  ? distEntry
  : existsSync(workspaceEntry)
    ? workspaceEntry
    : null;

if (!entry) {
  console.error(
    "sol CLI binary not found. Tried:\n" +
      `  ${distEntry}\n` +
      `  ${workspaceEntry}\n` +
      "If running from the luna.mbt monorepo, run " +
      "`moon build --target js --release` first.",
  );
  process.exit(1);
}

await import(entry);
