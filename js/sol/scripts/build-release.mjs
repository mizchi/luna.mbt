#!/usr/bin/env node
// Bundles the moonbit-built sol CLI into js/sol/dist/ so npm installs
// resolve a self-contained file rather than the workspace _build/ tree.
// Invoked from the package's `build` script — `pnpm -r build` in CI
// runs this automatically before `npm publish`.
import { copyFileSync, existsSync, mkdirSync, rmSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PKG_DIR = path.resolve(__dirname, "..");
const ROOT = path.resolve(__dirname, "../../..");
const SRC = path.join(
  ROOT,
  "_build/js/release/build/mizchi/sol/cmd/sol/sol.js",
);
const OUT_DIR = path.join(PKG_DIR, "dist");
const OUT = path.join(OUT_DIR, "sol.js");

if (!existsSync(SRC)) {
  console.error(
    `Missing ${SRC}\n` +
      "Run `moon build --target js --release` from the workspace root first.",
  );
  process.exit(1);
}

rmSync(OUT_DIR, { recursive: true, force: true });
mkdirSync(OUT_DIR, { recursive: true });
copyFileSync(SRC, OUT);
console.log(`Wrote ${path.relative(ROOT, OUT)}`);
