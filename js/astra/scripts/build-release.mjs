#!/usr/bin/env node
// Bundles the moonbit-built astra CLI plus its runtime asset directory
// into js/astra/dist/. astra's load_asset() has no cwd-relative path
// that resolves to assets when the CLI is installed via npm, so the
// bin shim points globalThis.__sol_assets_dir at the bundled copy.
// Only runtime-loaded subdirs (styles/, scripts/) are copied — the
// .mbt source files in astra/src/assets/ are already compiled into
// astra.js.
import { copyFileSync, cpSync, existsSync, mkdirSync, rmSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PKG_DIR = path.resolve(__dirname, "..");
const ROOT = path.resolve(__dirname, "../../..");
const SRC_JS = path.join(
  ROOT,
  "_build/js/release/build/mizchi/astra/cmd/astra/astra.js",
);
const SRC_ASSETS = path.join(ROOT, "astra/src/assets");
const OUT_DIR = path.join(PKG_DIR, "dist");

for (const p of [SRC_JS, SRC_ASSETS]) {
  if (!existsSync(p)) {
    console.error(
      `Missing ${p}\n` +
        "Run `moon build --target js --release` from the workspace root first.",
    );
    process.exit(1);
  }
}

rmSync(OUT_DIR, { recursive: true, force: true });
mkdirSync(OUT_DIR, { recursive: true });
copyFileSync(SRC_JS, path.join(OUT_DIR, "astra.js"));

for (const sub of ["styles", "scripts"]) {
  const from = path.join(SRC_ASSETS, sub);
  if (existsSync(from)) {
    cpSync(from, path.join(OUT_DIR, "assets", sub), { recursive: true });
  }
}

console.log(`Wrote ${path.relative(ROOT, OUT_DIR)}/`);
