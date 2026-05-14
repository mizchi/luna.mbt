import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
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
  "sol_js",
  "sol_js.js"
);
const SOL_APP = path.join(SOL_DIR, "examples", "sol_app");
const SOL_API = path.join(SOL_DIR, "examples", "sol_api");

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

test("sol generate: external client bundle avoids generated client intermediates", () => {
  ensureCliBuilt();
  const sandbox = fs.mkdtempSync(path.join(os.tmpdir(), "sol-external-bundle-"));
  try {
    fs.mkdirSync(path.join(sandbox, "app", "server"), { recursive: true });
    fs.mkdirSync(path.join(sandbox, "app", "client"), { recursive: true });
    fs.writeFileSync(
      path.join(sandbox, "moon.mod.json"),
      JSON.stringify(
        {
          name: "example/external-bundle",
          version: "0.1.0",
          deps: {},
          source: "app",
          "preferred-target": "js",
        },
        null,
        2
      ) + "\n"
    );
    fs.writeFileSync(
      path.join(sandbox, "sol.config.json"),
      JSON.stringify(
        {
          routes: "app/server",
          output: "app/__gen__",
          runtime: "node",
          serverEntry: "user",
          clientBundle: "external",
          islands: ["app/client"],
        },
        null,
        2
      ) + "\n"
    );
    fs.writeFileSync(
      path.join(sandbox, "app", "server", "routes.mbt"),
      "pub fn routes() -> Array[Unit] { [] }\n"
    );
    fs.writeFileSync(
      path.join(sandbox, "app", "client", "counter.mbt"),
      [
        "pub(all) struct CounterProps {",
        "  initial : Int",
        "}",
        "",
      ].join("\n")
    );

    const result = runSolGenerate(sandbox);
    assert.equal(
      result.status,
      0,
      `sol generate failed\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}`
    );

    assert.equal(
      fs.existsSync(path.join(sandbox, "app", "__gen__", "client")),
      false,
      "external client bundle should not create generated MoonBit client glue"
    );
    assert.equal(
      fs.existsSync(path.join(sandbox, "app", "__gen__", "server")),
      false,
      "user-managed server entry should not create generated MoonBit server glue"
    );
    assert.equal(
      fs.existsSync(path.join(sandbox, ".sol", "prod", "manifest.json")),
      false,
      "external client bundle should not create a rolldown manifest"
    );
    assert.equal(
      fs.existsSync(path.join(sandbox, ".sol", "prod", "client")),
      false,
      "external client bundle should not create generated client entries"
    );

    const mainJs = fs.readFileSync(
      path.join(sandbox, ".sol", "prod", "server", "main.js"),
      "utf8"
    );
    assert.match(mainJs, /user-managed MoonBit mode/);
    assert.match(mainJs, /_build\/js\/release\/build\/server\/server\.js/);
    assert.doesNotMatch(mainJs, /__gen__\/server/);

    const typesPath = path.join(
      sandbox,
      "app",
      "__gen__",
      "types",
      "types.mbt"
    );
    assert.ok(fs.existsSync(typesPath), "external mode should keep Props types");
    const types = fs.readFileSync(typesPath, "utf8");
    assert.match(types, /pub\(all\) struct CounterProps/);
    assert.match(types, /pub fn counter_at\(/);
    assert.doesNotMatch(types, /counter_at\("\/static\/counter\.js"/);
    assert.doesNotMatch(types, /pub fn counter\(\s*props : CounterProps/);
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});

test("sol generate: contract manifest drives route/action/client asset types", () => {
  ensureCliBuilt();
  const sandbox = fs.mkdtempSync(path.join(os.tmpdir(), "sol-contract-"));
  try {
    fs.mkdirSync(path.join(sandbox, "app", "server"), { recursive: true });
    fs.writeFileSync(
      path.join(sandbox, "moon.mod.json"),
      JSON.stringify(
        {
          name: "example/contract-manifest",
          version: "0.1.0",
          deps: {},
          source: "app",
          "preferred-target": "js",
        },
        null,
        2
      ) + "\n"
    );
    fs.writeFileSync(
      path.join(sandbox, "sol.config.json"),
      JSON.stringify(
        {
          routes: "app/server",
          output: "app/__gen__",
          runtime: "node",
          serverEntry: "user",
          clientBundle: "external",
          contractManifest: "sol.contract.json",
          islands: ["app/client"],
        },
        null,
        2
      ) + "\n"
    );
    fs.writeFileSync(
      path.join(sandbox, "sol.contract.json"),
      JSON.stringify(
        {
          routes: ["/api/items/:id"],
          actions: ["submit-contact"],
          clientAssets: [
            {
              component: "counter",
              url: "/assets/counter.abc123.js",
            },
          ],
          components: [
            {
              name: "counter",
              package: "app/client",
              importAlias: "client",
              props: {
                name: "CounterProps",
                fields: [{ name: "initial", type: "Int" }],
              },
            },
          ],
        },
        null,
        2
      ) + "\n"
    );
    fs.writeFileSync(
      path.join(sandbox, "app", "server", "routes.mbt"),
      [
        "pub fn routes() -> Array[Unit] {",
        "  []",
        "}",
        "",
      ].join("\n")
    );
    const result = runSolGenerate(sandbox);
    assert.equal(
      result.status,
      0,
      `sol generate failed\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}`
    );
    assert.match(result.stdout, /Contract manifest: sol\.contract\.json/);
    assert.match(result.stdout, /Found 1 route paths, 1 action IDs/);

    const typesPath = path.join(
      sandbox,
      "app",
      "__gen__",
      "types",
      "types.mbt"
    );
    assert.ok(fs.existsSync(typesPath), "manifest should generate types.mbt");
    const types = fs.readFileSync(typesPath, "utf8");
    assert.match(types, /pub\(all\) struct RouteApiItemsIdParams/);
    assert.match(types, /pub\(all\) struct CounterProps/);
    assert.match(types, /pub fn params_api_items_id/);
    assert.match(types, /pub fn action_submit_contact\(\)/);
    assert.match(types, /pub fn counter\(/);
    assert.match(types, /counter_at\("\/assets\/counter\.abc123\.js"/);

    const pkg = fs.readFileSync(
      path.join(sandbox, "app", "__gen__", "types", "moon.pkg"),
      "utf8"
    );
    assert.match(pkg, /"counter"/);
    assert.match(pkg, /"mizchi\/sol\/router" @router/);
    assert.match(pkg, /"mizchi\/sol\/action" @action/);

    assert.equal(
      fs.existsSync(path.join(sandbox, "app", "__gen__", "server")),
      false,
      "user-managed server entry should not create generated MoonBit server glue"
    );
    assert.equal(
      fs.existsSync(path.join(sandbox, "app", "__gen__", "client")),
      false,
      "external client bundle should not create generated MoonBit client glue"
    );
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});

test("sol generate: produces types.mbt with route constants, action keys, and component refs", () => {
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

  // --- Typed route param accessors ---
  assert.match(
    content,
    /pub\(all\) struct RouteDocsSlugParams[\s\S]*?slug : String/,
    "RouteDocsSlugParams struct"
  );
  assert.match(
    content,
    /pub fn params_docs_slug\(props : @router\.PageProps\) -> Result\[RouteDocsSlugParams, @router\.ApiResponse\]/,
    "params_docs_slug() accessor"
  );
  assert.match(
    content,
    /@router\.require\(props, "slug"\)/,
    "required route param uses generated accessor body"
  );
  assert.match(
    content,
    /pub\(all\) struct RouteBlogPathParams[\s\S]*?path : String\?/,
    "optional catch-all route param is optional"
  );
  assert.match(
    content,
    /pub fn params_blog_path\(props : @router\.PageProps\) -> Result\[RouteBlogPathParams, @router\.ApiResponse\]/,
    "params_blog_path() accessor"
  );
  assert.match(
    content,
    /pub fn link_docs_slug_params\(params : RouteDocsSlugParams\) -> String/,
    "link_docs_slug_params() builder"
  );
  assert.match(
    content,
    /link_docs_slug\(slug=params\.slug\)/,
    "route params struct feeds link builder"
  );
  assert.match(
    content,
    /Some\(path\) => link_blog_path\(path~\)[\s\S]*?None => "\/blog"/,
    "optional catch-all params builder omits missing segment"
  );

  // --- Action key factory functions ---
  assert.match(
    content,
    /pub fn action_submit_contact\(\) -> ActionSubmitContact/,
    "typed action_submit_contact() factory"
  );
  assert.match(
    content,
    /pub\(all\) struct ActionSubmitContact \{\}/,
    "action key marker type"
  );
  assert.match(
    content,
    /pub impl @action\.ActionKey for ActionSubmitContact with id/,
    "action key impl"
  );
  assert.match(
    content,
    /ActionSubmitContact::\{\}/,
    "typed action marker factory body"
  );
  assert.doesNotMatch(
    content,
    new RegExp("Action" + "Ref"),
    "removed action wrapper is not generated"
  );
});

test("sol generate: dogfoods user-managed routes with typed params", () => {
  ensureCliBuilt();
  const result = runSolGenerate(SOL_API);
  assert.equal(
    result.status,
    0,
    `sol_api generate failed\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}`
  );

  assert.equal(
    fs.existsSync(path.join(SOL_API, "app", "__gen__", "server")),
    false,
    "user-managed sol_api should not create generated server glue"
  );

  const typesPath = path.join(
    SOL_API,
    "app",
    "__gen__",
    "types",
    "types.mbt"
  );
  assert.ok(fs.existsSync(typesPath), "sol_api should generate route types");
  const content = fs.readFileSync(typesPath, "utf8");

  assert.match(
    content,
    /pub\(all\) struct RouteApiItemsIdParams[\s\S]*?id : String/,
    "sol_api user-managed route params should be generated"
  );
  assert.match(
    content,
    /pub fn params_api_items_id\(props : @router\.PageProps\) -> Result\[RouteApiItemsIdParams, @router\.ApiResponse\]/,
    "sol_api should expose typed params accessor"
  );

  const routes = fs.readFileSync(
    path.join(SOL_API, "app", "server", "routes.mbt"),
    "utf8"
  );
  assert.match(routes, /@types\.params_api_items_id\(props\)/);
  assert.doesNotMatch(routes, /@sol\.require_int\(props,\s*"id"\)/);

  const check = spawnSync("moon", ["check", "--target", "js"], {
    cwd: SOL_API,
    encoding: "utf8",
  });
  assert.equal(
    check.status,
    0,
    `sol_api dogfood app must typecheck\nstdout:\n${check.stdout}\nstderr:\n${check.stderr}`
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
  assert.match(
    content,
    /"mizchi\/sol\/router" @router/,
    "moon.pkg imports @router for typed route params"
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

test("sol build: cloudflare server output is Worker-bundler clean", () => {
  ensureCliBuilt();
  const result = spawnSync("node", [CLI_DEBUG, "build"], {
    cwd: SOL_APP,
    encoding: "utf8",
  });
  assert.equal(
    result.status,
    0,
    `sol build failed\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}`
  );

  const mainJs = fs.readFileSync(
    path.join(SOL_APP, ".sol", "prod", "server", "main.js"),
    "utf8"
  );
  assert.match(mainJs, /globalThis\.__SOL_RUNTIME__ = 'cloudflare'/);
  assert.match(mainJs, /await import\('\.\.\/\.\.\/\.\.\/_build\/js\/release\/build\/__gen__\/server\/server\.js'\)/);
  assert.doesNotMatch(mainJs, /setInterval/);
  assert.doesNotMatch(mainJs, /await new Promise/);

  const serverJs = fs.readFileSync(
    path.join(
      SOL_APP,
      "_build",
      "js",
      "release",
      "build",
      "__gen__",
      "server",
      "server.js"
    ),
    "utf8"
  );
  assert.doesNotMatch(
    serverJs,
    /import\(['"](?:node:fs|node:fs\/promises|node:path|node:module|@hono\/node-server)['"]\)/
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
