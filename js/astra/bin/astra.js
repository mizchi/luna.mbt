#!/usr/bin/env node
// Entry point for the @luna_ui/astra npm wrapper.
//
// Primary install path is `moon install mizchi/astra/cmd/astra`; this
// npm wrapper exists for users who already have node but not moon.
//
// CLI resolution order:
//   1. ../dist/astra.js — populated by scripts/build-release.mjs at
//      publish time. This is the path used in real npm installs.
//   2. ../../../_build/js/release/build/mizchi/astra/cmd/astra/astra.js
//      — workspace fallback so the shim stays usable from a clean
//      monorepo checkout, which is what tests/integration/* relies on.
//
// Asset resolution: astra's load_asset() tries a fixed list of
// cwd-relative paths to find styles/main.css etc. None of those resolve
// when the CLI is installed via npm, so we set globalThis.__sol_assets_dir
// to short-circuit the lookup. Bundled assets in dist/assets/ take
// precedence; the workspace path is the dev fallback.
import path from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const distEntry = path.resolve(__dirname, "../dist/astra.js");
const workspaceEntry = path.resolve(
  __dirname,
  "../../../_build/js/release/build/mizchi/astra/cmd/astra/astra.js",
);
const distAssets = path.resolve(__dirname, "../dist/assets");
const workspaceAssets = path.resolve(__dirname, "../../../astra/src/assets");

const entry = existsSync(distEntry)
  ? distEntry
  : existsSync(workspaceEntry)
    ? workspaceEntry
    : null;

if (!entry) {
  console.error(
    "astra CLI binary not found. Tried:\n" +
      `  ${distEntry}\n` +
      `  ${workspaceEntry}\n` +
      "If running from the luna.mbt monorepo, run " +
      "`moon build --target js --release` first.",
  );
  process.exit(1);
}

const assetsDir = existsSync(distAssets)
  ? distAssets
  : existsSync(workspaceAssets)
    ? workspaceAssets
    : null;
if (assetsDir) {
  globalThis.__sol_assets_dir = assetsDir;
}

await import(entry);
