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
  assert.match(mbti, /pub fn\[T : (?:@json\.)?FromJson\] decode_action_body/);
  assert.match(mbti, /pub fn\[T : (?:@json\.)?FromJson\] ActionContext::decode_json/);
  assert.match(mbti, /TypedActionKey::from_key/);
  assert.match(mbti, /pub fn\[K : ActionKey\] ActionDef::from_key/);
  assert.match(mbti, /pub fn\[K : ActionKey\] ActionRegistry::register_key/);
  assert.match(mbti, /pub struct ActionFormConfig\[Res\]/);
  assert.match(mbti, /ActionFormConfig::from_key\(TypedActionKey\[Req, Res\]\)/);
  assert.match(mbti, /pub fn\[Res : (?:@json\.)?FromJson\] submit_form_as_action/);
  assert.match(mbti, /pub enum TypedActionResponse\[Res\]/);
  assert.match(mbti, /invoke_typed_action_key/);
  assert.match(mbti, /create_typed_action_invoker_key/);
  assert.match(mbti, /pub fn\[Req : ToJson, Res : (?:@json\.)?FromJson\] invoke_typed_action_key/);
  assert.match(
    mbti,
    /pub fn\[Req : ToJson, Res : (?:@json\.)?FromJson\] create_typed_action_invoker_key/
  );
  assert.match(mbti, /ActionResult::json/);

  const forbidden = [
    /pub\(all\) struct TypedActionKey/,
    /TypedActionKey::new/,
    /\bActionRef\b/,
    /pub fn ActionDef::new\b/,
    /pub fn ActionResult::ok\b/,
    /Success\(@core\.Any\)/,
    /pub enum ActionResponse\b/,
    /pub fn ActionResponse::/,
    /pub fn ActionState::from_response\b/,
    /pub fn\[Res : (?:@json\.)?FromJson\] TypedActionResponse::from_action_response/,
    /pub fn ActionRegistry::get\b/,
    /pub fn ActionRegistry::action_url\b/,
    /signal : @core\.Any\?/,
    /ActionFormConfig::with_success\(Self, \(@core\.Any\) -> Unit\)/,
    /pub fn submit_form_as_action\(@core\.Any/,
    /pub fn invoke_action\(/,
    /pub fn\[K : ActionKey\] invoke_action_key\b/,
    /pub fn create_action_invoker\(/,
    /pub fn\[K : ActionKey\] create_action_invoker_key\b/,
    /pub fn ActionFormConfig::new\b/,
  ];
  for (const pattern of forbidden) {
    assert.doesNotMatch(mbti, pattern, `public API must not expose ${pattern}`);
  }
});

test("sol root public API does not expose JavaScript Any escape hatches", () => {
  const mbti = fs.readFileSync(
    path.join(SOL_DIR, "src", "pkg.generated.mbti"),
    "utf8"
  );

  assert.doesNotMatch(
    mbti,
    /@mizchi\/js\/core\.Any/,
    "sol root public API must not expose JavaScript Any"
  );
  const forbidden = [
    /pub fn json_obj\(/,
    /pub fn json_to_any\(/,
    /pub fn json_array_to_any\(/,
    /pub fn RolldownOutput::as_any\(/,
    /pub fn RolldownChunk::as_any\(/,
  ];

  for (const pattern of forbidden) {
    assert.doesNotMatch(mbti, pattern, `public API must not expose ${pattern}`);
  }
});

test("router public API keeps legacy API resolvers typed as Json", () => {
  const mbti = fs.readFileSync(
    path.join(SOL_DIR, "src", "router", "pkg.generated.mbti"),
    "utf8"
  );

  assert.doesNotMatch(
    mbti,
    /@mizchi\/js\/core\.Any/,
    "router public API must not expose JavaScript Any"
  );
  assert.match(
    mbti,
    /register_routes\(.*\(String, @mars\.Context, RouteParams\) -> Json\?/s
  );
  assert.match(
    mbti,
    /register_server_routes\(.*\(String, @mars\.Context, RouteParams\) -> Json\?/s
  );
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

test("examples dogfood typed action JSON results", () => {
  const files = [
    path.join(SOL_DIR, "README.md"),
    path.join(SOL_DIR, "src", "README.md"),
    path.join(SOL_DIR, "src", "action", "README.md"),
    path.join(SOL_DIR, "examples", "sol_app", "app", "server", "routes.mbt"),
    path.join(SOL_DIR, "examples", "sol_auth", "app", "server", "routes.mbt"),
    path.join(SOL_DIR, "examples", "sol_todo", "app", "server", "routes.mbt"),
  ];
  const forbidden = [
    /ActionResult::ok\(\s*@sol\.json_(?:obj|to_any)/s,
    /ActionResult::ok\([^)]*@core\.any\(/s,
    /ActionResult::ok\([^)]*@js\.any\(/s,
  ];

  for (const file of files) {
    const content = fs.readFileSync(file, "utf8");
    for (const pattern of forbidden) {
      assert.doesNotMatch(
        content,
        pattern,
        `${path.relative(ROOT, file)} must use ActionResult::json for structured success payloads`
      );
    }
  }
});

test("examples dogfood typed action request decoding", () => {
  const files = [
    path.join(SOL_DIR, "examples", "sol_app", "app", "server", "routes.mbt"),
    path.join(SOL_DIR, "examples", "sol_auth", "app", "server", "routes.mbt"),
    path.join(SOL_DIR, "examples", "sol_todo", "app", "server", "routes.mbt"),
  ];

  for (const file of files) {
    const content = fs.readFileSync(file, "utf8");
    assert.match(
      content,
      /ctx\.decode_json\(\)/,
      `${path.relative(ROOT, file)} must use typed action request decoding`
    );
    assert.doesNotMatch(
      content,
      /extern "js" fn parse_json|let data : @core\.Any = parse_json/,
      `${path.relative(ROOT, file)} must not decode action JSON through @core.Any`
    );
  }
});

test("examples dogfood typed action invocation", () => {
  const files = [
    path.join(SOL_DIR, "src", "action", "README.md"),
    path.join(SOL_DIR, "examples", "sol_app", "app", "client", "form.mbt"),
    path.join(SOL_DIR, "examples", "sol_auth", "app", "client", "form.mbt"),
  ];

  for (const file of files) {
    const content = fs.readFileSync(file, "utf8");
    assert.match(
      content,
      /invoke_typed_action_key\(/,
      `${path.relative(ROOT, file)} must use typed action invocation`
    );
    assert.match(
      content,
      /TypedActionResponse\[/,
      `${path.relative(ROOT, file)} must decode typed action responses`
    );
    assert.doesNotMatch(
      content,
      /invoke_action_key\(/,
      `${path.relative(ROOT, file)} must not use untyped action invocation`
    );
    assert.doesNotMatch(
      content,
      /\bActionResponse\b|extern "js" fn get_message/,
      `${path.relative(ROOT, file)} must not unwrap action responses through @js.Any`
    );
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
