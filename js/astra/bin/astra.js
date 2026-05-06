#!/usr/bin/env node
// Workspace dev shim. js/astra/bin/astra.js -> three levels up to
// workspace root, then into _build/js/release/build/mizchi/astra/cmd/astra/astra.js.
//
// Primary install path is `moon install mizchi/astra/cmd/astra`; this
// npm wrapper exists for users who already have node but not moon.
// Published npm builds bundle the moonbit CLI output into ./dist/ via
// js/astra/scripts/build-release.mjs (TODO).
//
// Asset resolution: astra's load_asset() tries a fixed list of cwd-relative
// paths to find styles/main.css etc. When astra build is invoked from a
// docs directory like website/, none of those candidates resolves to the
// astra source tree at <repo>/astra/src/assets. Without this override,
// load_asset falls through to its tiny inline fallback CSS and the docs
// site loses ~2900 lines of component CSS. Setting __sol_assets_dir on
// globalThis short-circuits the search to the right directory whenever
// the shim is being run from inside the luna.mbt monorepo. The dynamic
// import below ensures this assignment runs before astra's MoonBit JS
// reads load_asset's first candidate.
import path from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const workspaceAssets = path.resolve(__dirname, "../../../astra/src/assets");
if (existsSync(workspaceAssets)) {
  globalThis.__sol_assets_dir = workspaceAssets;
}

await import("../../../_build/js/release/build/mizchi/astra/cmd/astra/astra.js");
