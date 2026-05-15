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
// sol_sqlite is the surviving auto-managed (sol-generates-main.mbt) example
// after sol_app/sol_auth/sol_todo/sol_api moved to user-managed mode. Tests
// that assert on the `__gen__/server/main.mbt` generator output target this.
const SOL_SQLITE = path.join(SOL_DIR, "examples", "sol_sqlite");

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

function runSol(cwd, args) {
  return spawnSync("node", [CLI_DEBUG, ...args], {
    cwd,
    encoding: "utf8",
  });
}

function runSolGenerate(cwd) {
  return runSol(cwd, ["generate"]);
}

function runTypeScriptCheck(entryPath) {
  return spawnSync(
    "pnpm",
    [
      "exec",
      "tsc",
      "--strict",
      "--noEmit",
      "--module",
      "ESNext",
      "--moduleResolution",
      "node",
      "--target",
      "ES2022",
      entryPath,
    ],
    {
      cwd: ROOT,
      encoding: "utf8",
    }
  );
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
          routes: [
            {
              path: "/api/items/:id",
              query: [
                { name: "include", optional: true },
                { name: "token", optional: false },
              ],
            },
          ],
          actions: [
            {
              id: "submit-contact",
              request: {
                name: "SubmitContactRequest",
                fields: [{ name: "email", type: "String" }],
              },
              response: {
                name: "SubmitContactResponse",
                fields: [{ name: "ok", type: "Bool" }],
              },
            },
          ],
          apis: [
            {
              method: "POST",
              path: "/api/items/:id",
              request: {
                name: "CreateItemRequest",
                fields: [{ name: "title", type: "String" }],
              },
              response: {
                name: "ItemResponse",
                fields: [{ name: "id", type: "String" }],
              },
            },
          ],
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
    assert.match(types, /pub\(all\) struct RouteApiItemsIdQuery/);
    assert.match(types, /token : String/);
    assert.match(types, /include : String\?/);
    assert.match(types, /pub\(all\) struct SubmitContactRequest/);
    assert.match(types, /pub\(all\) struct SubmitContactResponse/);
    assert.match(types, /pub\(all\) struct CreateItemRequest/);
    assert.match(types, /pub\(all\) struct ItemResponse/);
    assert.match(types, /pub\(all\) struct CounterProps/);
    assert.match(types, /pub fn params_api_items_id/);
    assert.match(types, /pub fn query_api_items_id/);
    assert.match(types, /pub fn action_submit_contact\(\)/);
    assert.match(types, /pub fn action_submit_contact_typed\(\)/);
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

    const typecheckPath = path.join(sandbox, "contract-boundary-check.ts");
    fs.writeFileSync(
      typecheckPath,
      [
        'import type { SolActionRequest, SolActionResponse, SolApiRequest, SolApiResponse, SolRouteQueryOf, SolRouteRef } from "./app/__gen__/types/types";',
        "",
        'const query: SolRouteQueryOf<"/api/items/:id"> = { token: "t", include: null };',
        'const route: SolRouteRef<"/api/items/:id"> = { path: "/api/items/:id", params: { id: "1" }, query };',
        'const actionReq: SolActionRequest<"submit-contact"> = { email: "a@example.com" };',
        'const actionRes: SolActionResponse<"submit-contact"> = { ok: true };',
        'const apiReq: SolApiRequest<"POST /api/items/:id"> = { title: "hello" };',
        'const apiRes: SolApiResponse<"POST /api/items/:id"> = { id: "1" };',
        "void [route, actionReq, actionRes, apiReq, apiRes];",
        "",
        "// @ts-expect-error missing required query token",
        'const badQuery: SolRouteQueryOf<"/api/items/:id"> = { include: "all" };',
        "void badQuery;",
        "",
        "// @ts-expect-error action request payload is typed",
        'const badActionReq: SolActionRequest<"submit-contact"> = { name: "not-email" };',
        "void badActionReq;",
        "",
      ].join("\n")
    );
    const typecheck = runTypeScriptCheck(typecheckPath);
    assert.equal(
      typecheck.status,
      0,
      `generated boundary contract types should typecheck\nstdout:\n${typecheck.stdout}\nstderr:\n${typecheck.stderr}`
    );
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});

test("sol contract-ts output drives sol generate contract manifest mode", () => {
  ensureCliBuilt();
  const sandbox = fs.mkdtempSync(path.join(os.tmpdir(), "sol-contract-ts-"));
  try {
    fs.mkdirSync(path.join(sandbox, "app", "server"), { recursive: true });
    fs.mkdirSync(path.join(sandbox, "app", "client"), { recursive: true });
    fs.writeFileSync(
      path.join(sandbox, "moon.mod.json"),
      JSON.stringify(
        {
          name: "example/contract-ts",
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
      path.join(sandbox, "app", "server", "routes.mbt"),
      "pub fn routes() -> Array[Unit] { [] }\n"
    );
    fs.writeFileSync(
      path.join(sandbox, "app", "client", "props.ts"),
      [
        "export interface CounterProps {",
        "  initial: int;",
        "  label?: string;",
        "  tags: Array<string>;",
        "}",
        "",
      ].join("\n")
    );

    const contract = runSol(sandbox, [
      "contract-ts",
      "--input",
      "app/client/props.ts",
      "--props",
      "CounterProps",
      "--package",
      "app/client",
      "--client-url",
      "/assets/counter.js",
    ]);
    assert.equal(
      contract.status,
      0,
      `sol contract-ts failed\nstdout:\n${contract.stdout}\nstderr:\n${contract.stderr}`
    );
    fs.writeFileSync(path.join(sandbox, "sol.contract.json"), contract.stdout);

    const result = runSolGenerate(sandbox);
    assert.equal(
      result.status,
      0,
      `sol generate failed\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}`
    );

    const types = fs.readFileSync(
      path.join(sandbox, "app", "__gen__", "types", "types.mbt"),
      "utf8"
    );
    assert.match(types, /pub\(all\) struct CounterProps/);
    assert.match(types, /initial : Int/);
    assert.match(types, /label : String\?/);
    assert.match(types, /tags : Array\[String\]/);
    assert.match(types, /counter_at\("\/assets\/counter\.js"/);

    const dts = fs.readFileSync(
      path.join(sandbox, "app", "__gen__", "types", "types.d.ts"),
      "utf8"
    );
    assert.match(dts, /export interface CounterProps/);
    assert.match(dts, /initial: number/);
    assert.match(dts, /label\?: string \| null/);
    assert.match(dts, /tags: string\[\]/);
    assert.match(dts, /export type SolComponentName = keyof SolComponentProps/);
    assert.match(dts, /export interface SolComponentRef/);
    assert.match(
      dts,
      /"counter": \{ props: CounterProps; url: "\/assets\/counter\.js"; wc: false; \}/
    );
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});

test("sol generate: contractTs config drives generated contract types", () => {
  ensureCliBuilt();
  const sandbox = fs.mkdtempSync(
    path.join(os.tmpdir(), "sol-contract-ts-config-")
  );
  try {
    fs.mkdirSync(path.join(sandbox, "app", "server"), { recursive: true });
    fs.mkdirSync(path.join(sandbox, "app", "client"), { recursive: true });
    fs.writeFileSync(
      path.join(sandbox, "moon.mod.json"),
      JSON.stringify(
        {
          name: "example/contract-ts-config",
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
          contractTs: [
            {
              input: "app/client/props.ts",
              props: "CounterProps",
              package: "app/client",
              clientUrl: "/assets/counter.js",
            },
          ],
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
      path.join(sandbox, "app", "client", "props.ts"),
      [
        "export interface CounterProps {",
        "  initial: int;",
        "  label?: string;",
        "  tags: ReadonlyArray<string>;",
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
    assert.match(result.stdout, /Contract manifest: TypeScript interfaces/);

    const types = fs.readFileSync(
      path.join(sandbox, "app", "__gen__", "types", "types.mbt"),
      "utf8"
    );
    assert.match(types, /pub\(all\) struct CounterProps/);
    assert.match(types, /initial : Int/);
    assert.match(types, /label : String\?/);
    assert.match(types, /tags : Array\[String\]/);
    assert.match(types, /counter_at\("\/assets\/counter\.js"/);

    const dts = fs.readFileSync(
      path.join(sandbox, "app", "__gen__", "types", "types.d.ts"),
      "utf8"
    );
    assert.match(dts, /export interface CounterProps/);
    assert.match(dts, /tags: string\[\]/);
    assert.match(dts, /"counter": CounterProps/);
    assert.match(dts, /export type SolComponentPropsOf/);

    const typecheckPath = path.join(sandbox, "contract-check.ts");
    fs.writeFileSync(
      typecheckPath,
      [
        'import type { CounterProps, SolComponentPropsOf, SolComponentRef, SolComponentUrl } from "./app/__gen__/types/types";',
        "",
        "const props: CounterProps = { initial: 1, label: null, tags: [] };",
        "const typedProps: SolComponentPropsOf<\"counter\"> = props;",
        "const url: SolComponentUrl<\"counter\"> = \"/assets/counter.js\";",
        "const ref: SolComponentRef<\"counter\"> = { component: \"counter\", props: typedProps, url, wc: false };",
        "void ref;",
        "",
      ].join("\n")
    );
    const typecheck = runTypeScriptCheck(typecheckPath);
    assert.equal(
      typecheck.status,
      0,
      `generated types.d.ts should typecheck\nstdout:\n${typecheck.stdout}\nstderr:\n${typecheck.stderr}`
    );
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});

test("sol generate: route and action declarations typecheck in TypeScript", () => {
  ensureCliBuilt();
  const sandbox = fs.mkdtempSync(path.join(os.tmpdir(), "sol-route-dts-"));
  try {
    fs.mkdirSync(path.join(sandbox, "app", "server"), { recursive: true });
    fs.writeFileSync(
      path.join(sandbox, "moon.mod.json"),
      JSON.stringify(
        {
          name: "example/route-dts",
          version: "0.1.0",
          deps: {
            "mizchi/sol": { path: SOL_DIR },
            "mizchi/luna": { path: path.join(ROOT, "luna") },
            "mizchi/mars": "0.3.10",
            "mizchi/js": "0.10.15",
            "moonbitlang/async": "0.17.0",
          },
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
        },
        null,
        2
      ) + "\n"
    );
    fs.writeFileSync(
      path.join(sandbox, "app", "server", "routes.mbt"),
      [
        "let submit_contact_handler : @action.ActionHandler = @action.ActionHandler(async fn(ctx) {",
        "  @action.ActionResult::ok(@core.any(true))",
        "})",
        "",
        "pub fn routes() -> Array[Unit] {",
        '  [@sol.route("/", home), @sol.route("/blog/:slug", blog), @sol.route("/docs/[[...path]]", docs)]',
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

    const dts = fs.readFileSync(
      path.join(sandbox, "app", "__gen__", "types", "types.d.ts"),
      "utf8"
    );
    assert.match(
      dts,
      /export type SolRoutePath = "\/" \| "\/blog\/:slug" \| "\/docs\/\[\[\.\.\.path\]\]";/
    );
    assert.match(dts, /"\/": undefined;/);
    assert.match(dts, /"\/blog\/:slug": \{ slug: string; \};/);
    assert.match(
      dts,
      /"\/docs\/\[\[\.\.\.path\]\]": \{ path\?: string \| null; \};/
    );
    assert.match(dts, /export type SolActionId = "submit-contact";/);

    const typecheckPath = path.join(sandbox, "route-check.ts");
    fs.writeFileSync(
      typecheckPath,
      [
        'import type { SolActionId, SolActionKey, SolRouteParamsOf, SolRoutePath, SolRouteRef } from "./app/__gen__/types/types";',
        "",
        'const path: SolRoutePath = "/blog/:slug";',
        'const rootParams: SolRouteParamsOf<"/"> = undefined;',
        'const rootRoute: SolRouteRef<"/"> = { path: "/" };',
        'const rootRouteDefault: SolRouteRef = { path: "/" };',
        'const params: SolRouteParamsOf<"/blog/:slug"> = { slug: "hello" };',
        'const optionalParams: SolRouteParamsOf<"/docs/[[...path]]"> = {};',
        'const route: SolRouteRef<"/blog/:slug"> = { path: "/blog/:slug", params };',
        'const routeDefault: SolRouteRef = { path: "/blog/:slug", params };',
        'const actionId: SolActionId = "submit-contact";',
        'const action: SolActionKey<"submit-contact"> = { id: actionId, basePath: "/_action" };',
        "void [path, rootParams, rootRoute, rootRouteDefault, optionalParams, route, routeDefault, action];",
        "",
        "// @ts-expect-error static route does not accept params",
        'const badRootRoute: SolRouteRef<"/"> = { path: "/", params: {} };',
        "void badRootRoute;",
        "",
        "// @ts-expect-error missing required route param",
        'const badParams: SolRouteParamsOf<"/blog/:slug"> = {};',
        "void badParams;",
        "",
        "// @ts-expect-error unknown action id",
        'const badAction: SolActionKey<"delete-user"> = { id: "delete-user", basePath: "/_action" };',
        "void badAction;",
        "",
      ].join("\n")
    );
    const typecheck = runTypeScriptCheck(typecheckPath);
    assert.equal(
      typecheck.status,
      0,
      `generated route/action types should typecheck\nstdout:\n${typecheck.stdout}\nstderr:\n${typecheck.stderr}`
    );
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
});

test("sol generate: invalid contract manifest fails instead of source fallback", () => {
  ensureCliBuilt();
  const sandbox = fs.mkdtempSync(
    path.join(os.tmpdir(), "sol-contract-invalid-")
  );
  try {
    fs.mkdirSync(path.join(sandbox, "app", "server"), { recursive: true });
    fs.mkdirSync(path.join(sandbox, "app", "client"), { recursive: true });
    fs.writeFileSync(
      path.join(sandbox, "moon.mod.json"),
      JSON.stringify(
        {
          name: "example/contract-manifest-invalid",
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
          components: [
            {
              name: "counter",
              package: "app/client",
              props: {
                name: "CounterProps",
                fields: [{ name: "bad-name", type: "Int" }],
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
    assert.notEqual(
      result.status,
      0,
      `sol generate should reject invalid manifest\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}`
    );
    assert.match(
      result.stderr,
      /contract manifest not found or invalid: sol\.contract\.json/
    );
    assert.equal(
      fs.existsSync(path.join(sandbox, "app", "__gen__", "types")),
      false,
      "invalid manifest should not fall back to source-generated Props types"
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
  // user-managed mode (sol_app ships its own app/server/main.mbt): the
  // generated `.sol/prod/server/main.js` imports the moonbit server bundle
  // directly, not via `__gen__/server/`. auto-managed examples instead
  // import `_build/js/release/build/__gen__/server/server.js` — see
  // sol_sqlite below for that path.
  assert.match(
    mainJs,
    /await import\('\.\.\/\.\.\/\.\.\/_build\/js\/release\/build\/server\/server\.js'\)/,
  );
  assert.doesNotMatch(mainJs, /setInterval/);
  assert.doesNotMatch(mainJs, /await new Promise/);

  // user-managed mode (sol_app): the moonbit bundle lives directly under
  // `_build/js/release/build/server/server.js` — `__gen__/server/` is not
  // produced. Auto-managed examples would read from the __gen__ path.
  const serverJs = fs.readFileSync(
    path.join(
      SOL_APP,
      "_build",
      "js",
      "release",
      "build",
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
  // This test asserts on the generator output, so it has to run against
  // an auto-managed example (where sol owns `__gen__/server/main.mbt`).
  // After the 0.22.4 example migration, sol_sqlite is the canonical
  // auto-managed survivor.
  const result = runSolGenerate(SOL_SQLITE);
  assert.equal(result.status, 0);

  const mainPath = path.join(
    SOL_SQLITE,
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
