import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const THIS_DIR = path.dirname(fileURLToPath(import.meta.url));
const SOL_DIR = path.resolve(THIS_DIR, "..");
const ROOT = path.resolve(SOL_DIR, "..");
const SOL_APP = path.join(SOL_DIR, "examples", "sol_app");
const CLI_DEBUG = path.join(
  ROOT,
  "_build",
  "js",
  "debug",
  "build",
  "mizchi",
  "sol",
  "cmd",
  "sol_js",
  "sol_js.js"
);

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

function collectFiles(dir, keep) {
  const files = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === "_build" || entry.name === "__gen__" || entry.name === ".sol") {
      continue;
    }
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...collectFiles(full, keep));
    } else if (keep(full)) {
      files.push(full);
    }
  }
  return files;
}

test("action public API only exposes typed action keys", () => {
  const mbti = fs.readFileSync(
    path.join(SOL_DIR, "src", "action", "pkg.generated.mbti"),
    "utf8"
  );

  assert.match(mbti, /pub\(open\) trait ActionKey/);
  assert.match(mbti, /pub struct TypedActionKey/);
  assert.match(mbti, /pub fn\[K : ActionKey\] action_id\(K\) -> String/);
  assert.match(mbti, /pub fn\[K : ActionKey\] action_url\(K\) -> String/);
  assert.match(mbti, /TypedActionKey::from_key/);
  assert.match(mbti, /pub fn\[K : ActionKey\] ActionDef::from_key/);
  assert.match(mbti, /pub fn\[K : ActionKey\] ActionRegistry::register_key/);
  assert.match(mbti, /pub fn\[K : ActionKey\] ActionFormConfig::from_key/);
  assert.match(mbti, /invoke_typed_action_key/);
  assert.match(mbti, /create_typed_action_invoker_key/);

  const forbidden = [
    /pub\(all\) struct TypedActionKey/,
    /TypedActionKey::new/,
    /\bActionRef\b/,
    /pub fn ActionDef::new\b/,
    /pub fn ActionRegistry::get\b/,
    /pub fn ActionRegistry::action_url\b/,
    /pub fn invoke_action\(/,
    /pub fn create_action_invoker\(/,
    /pub fn ActionFormConfig::new\b/,
  ];
  for (const pattern of forbidden) {
    assert.doesNotMatch(mbti, pattern, `public API must not expose ${pattern}`);
  }
});

test("docs and examples do not use removed stringly action APIs", () => {
  const files = [
    path.join(SOL_DIR, "README.md"),
    path.join(SOL_DIR, "src", "README.md"),
    path.join(SOL_DIR, "src", "action", "README.md"),
    ...collectFiles(path.join(SOL_DIR, "examples"), (file) => file.endsWith(".mbt")),
  ];
  const forbidden = [
    /\bActionRef\b/,
    /\bActionDef::new\(/,
    /@action\.invoke_action\(/,
    /\binvoke_action\(/,
    /\bcreate_action_invoker\(/,
    /\bActionFormConfig::new\(/,
    /\bregister_ref\b/,
    /\bfrom_ref\b/,
    /\baction_ref\b/,
  ];

  for (const file of files) {
    const content = fs.readFileSync(file, "utf8");
    for (const pattern of forbidden) {
      assert.doesNotMatch(
        content,
        pattern,
        `${path.relative(ROOT, file)} must not use ${pattern}`
      );
    }
  }
});

test("generated types dependency remains acyclic for client code", () => {
  ensureCliBuilt();
  const generate = runSolGenerate(SOL_APP);
  assert.equal(
    generate.status,
    0,
    `sol generate failed\nstdout:\n${generate.stdout}\nstderr:\n${generate.stderr}`
  );

  const appClientPkg = JSON.parse(
    fs.readFileSync(path.join(SOL_APP, "app", "client", "moon.pkg.json"), "utf8")
  );
  assert.ok(
    appClientPkg.import.some(
      (entry) =>
        typeof entry === "object" &&
        entry.path === "example/sol-app/__gen__/types" &&
        entry.alias === "types"
    ),
    "app/client must import generated @types for action keys and props"
  );

  const typesPkg = fs.readFileSync(
    path.join(SOL_APP, "app", "__gen__", "types", "moon.pkg"),
    "utf8"
  );
  assert.match(typesPkg, /"mizchi\/sol\/action" @action/);
  assert.doesNotMatch(typesPkg, /example\/sol-app\/client/);

  const generatedClientPkg = fs.readFileSync(
    path.join(SOL_APP, "app", "__gen__", "client", "moon.pkg"),
    "utf8"
  );
  assert.match(generatedClientPkg, /"example\/sol-app\/client" @app_client/);
  assert.doesNotMatch(generatedClientPkg, /example\/sol-app\/__gen__\/types/);

  const check = spawnSync("moon", ["check", "--target", "js"], {
    cwd: SOL_APP,
    encoding: "utf8",
  });
  assert.equal(
    check.status,
    0,
    `sol_app client/types contract must typecheck\nstdout:\n${check.stdout}\nstderr:\n${check.stderr}`
  );
});
