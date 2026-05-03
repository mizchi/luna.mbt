import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(THIS_DIR, "..");

function read(relPath) {
  return fs.readFileSync(path.join(ROOT, relPath), "utf8");
}

test("justfile uses _build paths for CLI and test setup", () => {
  const justfile = read("justfile");
  assert.match(justfile, /_build\/js\/debug\/build\/cli\/cli\.js/);
  assert.match(justfile, /_build\/js\/debug\/test\/package\.json/);
  assert.doesNotMatch(justfile, /target\/js\/debug\/build\/cli\/cli\.js/);
  assert.doesNotMatch(justfile, /target\/js\/debug\/test\/package\.json/);
});

test("sol_auth runtime imports use _build output", () => {
  const worker = read("examples/sol_auth/worker.ts");
  const devAuth = read("examples/sol_auth/dev-auth.ts");
  assert.match(worker, /\.\/_build\/js\/release\/build\/__gen__\/server\/server\.js/);
  assert.match(devAuth, /\.\/_build\/js\/release\/build\/__gen__\/server\/server\.js/);
  assert.doesNotMatch(worker, /\.\/target\/js\/release\/build\/__gen__\/server\/server\.js/);
  assert.doesNotMatch(devAuth, /\.\/target\/js\/release\/build\/__gen__\/server\/server\.js/);
});

test("ssg component SSR loader resolves from _build", () => {
  const loader = read("src/ssg/generator/component_ssr.mbt");
  assert.match(loader, /_build\/js\/release\/build/);
  assert.doesNotMatch(loader, /target\/js\/release\/build/);
});

test("public docs avoid stale target/js path reference", () => {
  const readme = read("README.md");
  const srcReadme = read("src/README.md");
  const websiteIndex = read("website/02_sol/index.md");
  assert.doesNotMatch(readme, /target\/js\/debug\/build\/cli\/cli\.js/);
  assert.doesNotMatch(srcReadme, /target\/js\/debug\/build\/cli\/cli\.js/);
  assert.doesNotMatch(websiteIndex, /target\/js\/debug\/build\/cli\/cli\.js/);
});

test("clean routines remove legacy target before _build to avoid dangling symlink", () => {
  const clean = read("src/cli/clean.mbt");
  const dev = read("src/cli/dev.mbt");
  const cleanLegacy = clean.indexOf("let legacy_target_path");
  const cleanBuild = clean.indexOf("let build_path");
  assert.ok(cleanLegacy >= 0 && cleanBuild >= 0, "clean.mbt must define both paths");
  assert.ok(cleanLegacy < cleanBuild, "clean.mbt should remove target before _build");

  const devLegacy = dev.indexOf("let legacy_target_dir");
  const devBuild = dev.indexOf("let build_dir");
  assert.ok(devLegacy >= 0 && devBuild >= 0, "dev.mbt must define both paths");
  assert.ok(devLegacy < devBuild, "dev.mbt should remove target before _build");
});
