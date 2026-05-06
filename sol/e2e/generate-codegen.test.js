import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const SOL_DIR = path.resolve(THIS_DIR, "..");
const ROOT = path.resolve(SOL_DIR, "..");
const CLI_DEBUG = path.join(
  ROOT,
  "_build",
  "js",
  "debug",
  "build",
  "mizchi",
  "sol",
  "cmd",
  "sol",
  "sol.js"
);
const SOL_APP = path.join(SOL_DIR, "examples", "sol_app");

function ensureCliBuilt() {
  const build = spawnSync("moon", ["build", "--target", "js"], {
    cwd: ROOT,
    encoding: "utf8",
  });
  assert.equal(
    build.status,
    0,
    `failed to build CLI\nstdout:\n${build.stdout}\nstderr:\n${build.stderr}`
  );
}

function runSolGenerate(cwd) {
  return spawnSync("node", [CLI_DEBUG, "generate"], {
    cwd,
    encoding: "utf8",
  });
}

test("sol generate: produces types.mbt with route constants, action refs, and component refs", () => {
  ensureCliBuilt();
  const result = runSolGenerate(SOL_APP);
  assert.equal(
    result.status,
    0,
    `sol generate failed\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}`
  );

  const typesPath = path.join(
    SOL_APP,
    "app",
    "__gen__",
    "types",
    "types.mbt"
  );
  assert.ok(fs.existsSync(typesPath), `${typesPath} should exist`);
  const content = fs.readFileSync(typesPath, "utf8");

  // --- Props structs ---
  assert.match(content, /pub\(all\) struct CounterProps/, "CounterProps struct");
  assert.match(
    content,
    /pub\(all\) struct ContactFormProps/,
    "ContactFormProps struct"
  );
  assert.match(
    content,
    /pub\(all\) struct WcCounterProps/,
    "WcCounterProps struct"
  );

  // --- ComponentRef factory functions ---
  assert.match(
    content,
    /pub fn counter\(/,
    "counter() ComponentRef factory"
  );
  assert.match(
    content,
    /pub fn contact_form\(/,
    "contact_form() ComponentRef factory"
  );
  assert.match(
    content,
    /pub fn wc_counter\(/,
    "wc_counter() ComponentRef factory"
  );
  // wc_counter should have wc: true
  assert.match(
    content,
    /wc_counter[\s\S]*?wc: true/,
    "wc_counter has wc: true"
  );

  // --- Route path constants ---
  assert.match(
    content,
    /pub let route_root : String = "\/"/,
    "route_root constant"
  );
  assert.match(
    content,
    /pub let route_about : String = "\/about"/,
    "route_about constant"
  );
  assert.match(
    content,
    /pub let route_form : String = "\/form"/,
    "route_form constant"
  );
  assert.match(
    content,
    /pub let route_docs_slug : String = "\/docs\/\[\.\.\.slug\]"/,
    "route_docs_slug constant (catch-all)"
  );
  assert.match(
    content,
    /pub let route_blog_path : String = "\/blog\/\[\[\.\.\.path\]\]"/,
    "route_blog_path constant (optional catch-all)"
  );
  assert.match(
    content,
    /pub let route_api_health : String = "\/api\/health"/,
    "route_api_health constant"
  );

  // --- Param name constants ---
  assert.match(
    content,
    /pub let param_slug : String = "slug"/,
    "param_slug constant"
  );
  assert.match(
    content,
    /pub let param_path : String = "path"/,
    "param_path constant"
  );

  // --- ActionRef factory functions ---
  assert.match(
    content,
    /pub fn action_submit_contact\(\) -> @action\.ActionRef/,
    "action_submit_contact() factory"
  );
  assert.match(
    content,
    /id: "submit-contact"/,
    "action id in factory body"
  );
  assert.match(
    content,
    /base_path: "\/_action"/,
    "action base_path in factory body"
  );
});

test("sol generate: types moon.pkg imports @action when actions exist", () => {
  ensureCliBuilt();
  runSolGenerate(SOL_APP);

  const pkgPath = path.join(
    SOL_APP,
    "app",
    "__gen__",
    "types",
    "moon.pkg"
  );
  assert.ok(fs.existsSync(pkgPath), `${pkgPath} should exist`);
  const content = fs.readFileSync(pkgPath, "utf8");

  assert.match(
    content,
    /"mizchi\/sol\/action" @action/,
    "moon.pkg imports @action"
  );
  assert.match(
    content,
    /"mizchi\/luna" @luna/,
    "moon.pkg imports @luna"
  );
});

test("sol generate: stdout reports route and action counts", () => {
  ensureCliBuilt();
  const result = runSolGenerate(SOL_APP);
  assert.equal(result.status, 0);

  // Should report found route paths and action IDs
  assert.match(
    result.stdout,
    /Found \d+ route paths/,
    "stdout reports route path count"
  );
  assert.match(
    result.stdout,
    /\d+ action IDs/,
    "stdout reports action ID count"
  );
});

test("sol generate: idempotent (running twice produces same output)", () => {
  ensureCliBuilt();

  // Run generate first time
  const result1 = runSolGenerate(SOL_APP);
  assert.equal(result1.status, 0);
  const typesPath = path.join(
    SOL_APP,
    "app",
    "__gen__",
    "types",
    "types.mbt"
  );
  const content1 = fs.readFileSync(typesPath, "utf8");

  // Run generate second time
  const result2 = runSolGenerate(SOL_APP);
  assert.equal(result2.status, 0);
  const content2 = fs.readFileSync(typesPath, "utf8");

  assert.equal(content1, content2, "generate output should be idempotent");
});

test("sol generate: server main.mbt includes serve_sol_assets", () => {
  ensureCliBuilt();
  const result = runSolGenerate(SOL_APP);
  assert.equal(result.status, 0);

  const mainPath = path.join(
    SOL_APP,
    "app",
    "__gen__",
    "server",
    "main.mbt"
  );
  const content = fs.readFileSync(mainPath, "utf8");
  assert.match(
    content,
    /serve_sol_assets/,
    "server main.mbt should call serve_sol_assets"
  );
});

test("sol generate: writes built-in assets to .sol/prod/__sol__/", () => {
  ensureCliBuilt();
  const result = runSolGenerate(SOL_APP);
  assert.equal(result.status, 0);

  const solAssetDir = path.join(SOL_APP, ".sol", "prod", "__sol__");
  const assets = ["loader.js", "wc-loader.js", "sol-nav.js", "lib.js"];

  for (const asset of assets) {
    const assetPath = path.join(solAssetDir, asset);
    assert.ok(
      fs.existsSync(assetPath),
      `.sol/prod/__sol__/${asset} should exist`
    );
    const content = fs.readFileSync(assetPath, "utf8");
    assert.ok(content.length > 0, `${asset} should not be empty`);
  }
});
