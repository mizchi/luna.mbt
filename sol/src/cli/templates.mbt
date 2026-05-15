// Sol CLI Templates - thin re-exports + cloudflare/doc-only variants.
//
// The default-app templates and `generate_templates` live in
// `mizchi/sol/scaffold_templates` so that the native install shim
// (`mizchi/sol/cmd/sol`) can scaffold a project from outside any moon
// project. The JS-only pieces (cloudflare worker glue, doc starter,
// the island loader hook in `template_ln_loader_js`) stay here.

// Re-export the shared scaffold types/fns so that downstream callers in
// this package (and the existing test surface) keep working unchanged.

///|
pub using @scaffold_templates {
  type TemplateFile,
  template_gitignore,
  template_moon_mod_json,
  template_package_json,
  template_sol_config_json,
  template_layout_mbt,
  template_layout_moon_pkg,
  template_server_using_mbt,
  template_routes_main_mbt,
  template_routes_mbt,
  template_routes_moon_pkg,
  template_routes_using_mbt,
  template_client_counter_mbt,
  template_client_api_tools_mbt,
  template_client_counter_moon_pkg,
  template_gen_types_moon_pkg,
  template_gen_types_mbt,
  generate_templates,
}

///|
fn template_cloudflare_package_json(project_name : String) -> String {
  let tmpl =
    #|{
    #|  "name": "{{PROJECT_NAME}}",
    #|  "version": "0.1.0",
    #|  "type": "module",
    #|  "scripts": {
    #|    "dev": "sol generate --mode dev && moon build --target js && wrangler dev --config wrangler.dev.toml",
    #|    "build": "sol build",
    #|    "deploy": "sol build && wrangler deploy",
    #|    "generate": "sol generate",
    #|    "test:e2e": "playwright test",
    #|    "verify": "pnpm build && pnpm test:e2e"
    #|  },
    #|  "dependencies": {
    #|    "hono": "^4.12.12"
    #|  },
    #|  "devDependencies": {
    #|    "@playwright/test": "^1.58.2",
    #|    "rolldown": "1.0.0-rc.13",
    #|    "wrangler": "^4.81.0"
    #|  }
    #|}
  tmpl.replace(old="{{PROJECT_NAME}}", new=project_name)
}

///|
fn template_cloudflare_moon_mod_json(
  package_name : String,
  luna_path : String?,
) -> String {
  match luna_path {
    Some(path) => {
      let tmpl =
        #|{
        #|  "name": "{{PACKAGE_NAME}}",
        #|  "version": "0.1.0",
        #|  "deps": {
        #|    "mizchi/sol": "0.22.3",
        #|    "mizchi/sol_adapter_cloudflare": "0.22.3",
        #|    "mizchi/mars": "0.3.10",
        #|    "mizchi/luna": {
        #|      "path": "{{LUNA_PATH}}"
        #|    },
        #|    "mizchi/signals": "0.6.4",
        #|    "mizchi/js": "0.10.15",
        #|    "mizchi/npm_typed": "0.1.11",
        #|    "moonbitlang/async": "0.17.0"
        #|  },
        #|  "source": "app",
        #|  "preferred-target": "js"
        #|}
      tmpl
      .replace(old="{{PACKAGE_NAME}}", new=package_name)
      .replace(old="{{LUNA_PATH}}", new=path)
    }
    None => {
      let tmpl =
        #|{
        #|  "name": "{{PACKAGE_NAME}}",
        #|  "version": "0.1.0",
        #|  "deps": {
        #|    "mizchi/sol": "0.22.3",
        #|    "mizchi/sol_adapter_cloudflare": "0.22.3",
        #|    "mizchi/mars": "0.3.10",
        #|    "mizchi/luna": "0.22.2",
        #|    "mizchi/signals": "0.6.4",
        #|    "mizchi/js": "0.10.15",
        #|    "mizchi/npm_typed": "0.1.11",
        #|    "moonbitlang/async": "0.17.0"
        #|  },
        #|  "source": "app",
        #|  "preferred-target": "js"
        #|}
      tmpl.replace(old="{{PACKAGE_NAME}}", new=package_name)
    }
  }
}

///|
fn template_cloudflare_sol_config_json() -> String {
  (
    #|{
    #|  "islands": ["app/client"],
    #|  "routes": "app/server",
    #|  "output": "app/__gen__",
    #|  "runtime": "cloudflare"
    #|}
  )
}

// Note: For different runtimes, update sol.config.json:
// - "node"       - Node.js with @hono/node-server (default)
// - "cloudflare" - Cloudflare Workers (exports fetch handler)
// - "deno"       - Deno.serve
// - "bun"        - Bun.serve

///|
pub fn template_cloudflare_routes_main_mbt() -> String {
  (
    #|///| Server entry point
    #|
    #|async fn main {
    #|  @sol_cloudflare.run_app(fn() {
    #|    @sol.create_app(routes(), config=config())
    #|  })
    #|}
  )
}

///|
pub fn template_cloudflare_routes_moon_pkg(package_name : String) -> String {
  let tmpl =
    #|import {
    #|  "mizchi/sol" @sol,
    #|  "mizchi/sol_adapter_cloudflare" @sol_cloudflare,
    #|  "mizchi/luna/dom/static" @server_dom,
    #|  "{{PACKAGE_NAME}}/layout" @layout,
    #|  "{{PACKAGE_NAME}}/__gen__/types" @types,
    #|  "moonbitlang/async",
    #|}
    #|
    #|supported_targets = "js"
    #|warnings = "-67-29"
    #|
    #|options(
    #|  "is-main": true,
    #|  link: { "js": { "format": "esm" } },
    #|)
  tmpl.replace_all(old="{{PACKAGE_NAME}}", new=package_name)
}

///|
pub fn template_ln_loader_js() -> String {
  @astra_assets.get_island_loader_js()
}

///|
pub fn template_worker_entry_mjs(
  sol_module? : String = "./.sol/prod/server/main.js",
) -> String {
  (
    #|import solApp from "{{SOL_MODULE}}";
    #|
    #|const jobs = [
    #|  { id: "job-104", title: "Resize upload variants", state: "pending" },
    #|  { id: "job-105", title: "Sync metadata cache", state: "failed" },
    #|  { id: "job-106", title: "Publish audit event", state: "done" },
    #|];
    #|
    #|function json(data, init = {}) {
    #|  const headers = new Headers(init.headers);
    #|  headers.set("content-type", "application/json; charset=utf-8");
    #|  return new Response(JSON.stringify(data), { ...init, headers });
    #|}
    #|
    #|function requireWriteToken(request, env) {
    #|  const expected = env.WRITE_TOKEN || "dev-token";
    #|  return request.headers.get("Authorization") === `Bearer ${expected}`;
    #|}
    #|
    #|async function apiFetch(request, env, ctx) {
    #|  const url = new URL(request.url);
    #|  if (url.pathname === "/api/health") {
    #|    return json({
    #|      status: "ok",
    #|      source: "worker-api",
    #|      kv: Boolean(env.APP_KV),
    #|      r2: Boolean(env.UPLOADS_BUCKET),
    #|    });
    #|  }
    #|  if (url.pathname === "/api/jobs" && request.method === "GET") {
    #|    return json({ jobs, page: 1, pageSize: jobs.length });
    #|  }
    #|  if (url.pathname === "/api/jobs/batch" && request.method === "POST") {
    #|    if (!requireWriteToken(request, env)) {
    #|      return json({ error: "unauthorized" }, { status: 401 });
    #|    }
    #|    return json({ status: "queued", count: 2 }, { status: 202 });
    #|  }
    #|  if (url.pathname === "/api/proxy" && env.BACKEND_SERVICE) {
    #|    return env.BACKEND_SERVICE.fetch(request);
    #|  }
    #|  return json({ error: "not_found" }, { status: 404 });
    #|}
    #|
    #|export default {
    #|  async fetch(request, env, ctx) {
    #|    const url = new URL(request.url);
    #|    if (url.pathname.startsWith("/api/")) {
    #|      return apiFetch(request, env, ctx);
    #|    }
    #|    return solApp.fetch(request, env, ctx);
    #|  },
    #|};
  ).replace(old="{{SOL_MODULE}}", new=sol_module)
}

///|
fn template_wrangler_toml(project_name : String) -> String {
  template_wrangler_toml_with_main(project_name, "worker.entry.mjs")
}

///|
fn template_wrangler_toml_with_main(
  project_name : String,
  main : String,
) -> String {
  let tmpl =
    #|name = "{{PROJECT_NAME}}"
    #|main = "{{MAIN}}"
    #|compatibility_date = "2026-05-07"
    #|workers_dev = true
    #|
    #|[vars]
    #|APP_ENV = "local"
    #|
    #|[[kv_namespaces]]
    #|binding = "APP_KV"
    #|id = "replace-with-kv-id"
    #|preview_id = "local-app-kv"
    #|
    #|[[r2_buckets]]
    #|binding = "UPLOADS_BUCKET"
    #|bucket_name = "replace-with-r2-bucket"
  tmpl
  .replace(old="{{PROJECT_NAME}}", new=project_name)
  .replace(old="{{MAIN}}", new=main)
}

///|
fn template_cloudflare_readme(project_name : String) -> String {
  let tmpl =
    #|# {{PROJECT_NAME}}
    #|
    #|Sol + Cloudflare Worker starter.
    #|
    #|The first screen is an operational UI example: filters, pagination, a
    #|copy-to-clipboard affordance, local create/delete/retry controls, and a
    #|guarded batch action endpoint. It is intentionally small, but shaped like
    #|an admin console instead of a content site.
    #|
    #|## Development
    #|
    #|```bash
    #|moon update
    #|pnpm install
    #|pnpm dev
    #|```
    #|
    #|`worker.entry.dev.mjs` and `wrangler.dev.toml` run the same Worker composition shape against `.sol/dev/server/main.js`. `worker.entry.mjs` and `wrangler.toml` use `.sol/prod/server/main.js` for production.
    #|
    #|Keep UI routes on Sol and route Worker API paths before falling back to `solApp.fetch(request, env, ctx)`.
    #|
    #|## Operational UI
    #|
    #|- `app/server/routes.mbt` renders the SSR fallback for the Operations Console.
    #|- `app/client/api_tools.mbt` hydrates filters, copy, pagination, and batch status controls.
    #|- `worker.entry.mjs` owns `/api/health`, `/api/jobs`, `/api/jobs/batch`, and the service-binding proxy placeholder `/api/proxy`.
    #|- `tests/e2e/worker-app.spec.ts` drives the actual Wrangler Worker entry.
    #|
    #|## Route ownership
    #|
    #|- `worker.entry.mjs` owns platform-specific routes such as `/api/*`, media, service bindings, and auth callbacks.
    #|- Sol owns page routes, layouts, `/__sol__/*`, `/static/*`, and JSON routes you declare in `app/server/routes.mbt`.
    #|- Return JSON 404/500 responses from Worker-owned API routes. Let Sol handle Sol-owned page and API route errors.
    #|
    #|## Auth and bindings
    #|
    #|For route-group auth inside Sol, wrap routes with `@sol.with_mw([...], [...])`. For Cloudflare bindings, read `env` in `worker.entry.mjs` or in Worker-owned API handlers, then delegate unmatched UI requests to `solApp.fetch(request, env, ctx)`.
    #|
    #|`/api/jobs/batch` demonstrates a write endpoint protected by
    #|`Authorization: Bearer dev-token` in local development. In production,
    #|set `WRITE_TOKEN` as a Cloudflare secret:
    #|
    #|```bash
    #|wrangler secret put WRITE_TOKEN
    #|```
    #|
    #|The generated `wrangler.toml` includes placeholder KV and R2 bindings:
    #|replace `APP_KV.id` and `UPLOADS_BUCKET.bucket_name` before production deploy.
    #|
    #|## Dogfood checklist
    #|
    #|- Pending, success, and error states are visible before wiring real APIs.
    #|- Copyable API URLs and finite filter controls are present on the first screen.
    #|- Worker-owned APIs return JSON, while Sol-owned pages keep HTML responses.
    #|- `pnpm verify` exercises the Worker entry instead of private build paths.
    #|
    #|## Build
    #|
    #|```bash
    #|pnpm build
    #|pnpm deploy
    #|```
    #|
    #|## Verify
    #|
    #|```bash
    #|pnpm verify
    #|```
  tmpl.replace(old="{{PROJECT_NAME}}", new=project_name)
}

///|
fn template_cloudflare_playwright_config_ts() -> String {
  (
    #|import { defineConfig, devices } from "@playwright/test";
    #|
    #|export default defineConfig({
    #|  testDir: "./tests/e2e",
    #|  fullyParallel: true,
    #|  forbidOnly: !!process.env.CI,
    #|  retries: process.env.CI ? 2 : 0,
    #|  workers: process.env.CI ? 1 : undefined,
    #|  reporter: process.env.CI ? [["github"], ["html"]] : [["html"]],
    #|  use: {
    #|    baseURL: "http://127.0.0.1:8787",
    #|    trace: "on-first-retry",
    #|    screenshot: "only-on-failure",
    #|  },
    #|  projects: [
    #|    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    #|  ],
    #|  webServer: {
    #|    command: "pnpm dev",
    #|    url: "http://127.0.0.1:8787",
    #|    reuseExistingServer: !process.env.CI,
    #|    timeout: 120_000,
    #|  },
    #|});
  )
}

///|
fn template_cloudflare_e2e_spec_ts() -> String {
  (
    #|import { test, expect } from "@playwright/test";
    #|
    #|test("operational UI and Worker APIs run through the Worker entry", async ({ page }) => {
    #|  await page.goto("/");
    #|  await expect(page.getByRole("heading", { name: "Welcome to Sol" })).toBeVisible();
    #|  await expect(page.getByText("Operations Console")).toBeVisible();
    #|
    #|  await page.getByRole("button", { name: "failed" }).click();
    #|  await expect(page.getByText("Filter: failed")).toBeVisible();
    #|
    #|  await page.getByRole("button", { name: "Retry Failed" }).click();
    #|  await expect(page.getByText("Retrying failed jobs")).toBeVisible();
    #|
    #|  await page.getByRole("button", { name: "Simulate Error" }).click();
    #|  await expect(page.getByText("Last Error: validation failed")).toBeVisible();
    #|
    #|  const health = await page.request.get("/api/health");
    #|  await expect(health).toBeOK();
    #|  await expect(await health.json()).toMatchObject({
    #|    status: "ok",
    #|    source: "worker-api",
    #|  });
    #|
    #|  const denied = await page.request.post("/api/jobs/batch");
    #|  expect(denied.status()).toBe(401);
    #|
    #|  const accepted = await page.request.post("/api/jobs/batch", {
    #|    headers: { Authorization: "Bearer dev-token" },
    #|  });
    #|  expect(accepted.status()).toBe(202);
    #|});
  )
}

///|
pub fn generate_cloudflare_templates(
  package_name : String,
  project_name : String,
  luna_path : String?,
) -> Array[TemplateFile] {
  let templates = generate_templates(package_name, project_name, luna_path)
  let out : Array[TemplateFile] = []
  for file in templates {
    if file.path == "package.json" {
      out.push({
        path: file.path,
        content: template_cloudflare_package_json(project_name),
      })
    } else if file.path == "moon.mod.json" {
      out.push({
        path: file.path,
        content: template_cloudflare_moon_mod_json(package_name, luna_path),
      })
    } else if file.path == "sol.config.json" {
      out.push({
        path: file.path,
        content: template_cloudflare_sol_config_json(),
      })
    } else if file.path == "app/server/moon.pkg" {
      out.push({
        path: file.path,
        content: template_cloudflare_routes_moon_pkg(package_name),
      })
    } else if file.path == "app/server/main.mbt" {
      out.push({
        path: file.path,
        content: template_cloudflare_routes_main_mbt(),
      })
    } else {
      out.push(file)
    }
  }
  out.push({ path: "worker.entry.mjs", content: template_worker_entry_mjs() })
  out.push({
    path: "worker.entry.dev.mjs",
    content: template_worker_entry_mjs(sol_module="./.sol/dev/server/main.js"),
  })
  out.push({
    path: "wrangler.toml",
    content: template_wrangler_toml(project_name),
  })
  out.push({
    path: "wrangler.dev.toml",
    content: template_wrangler_toml_with_main(
      project_name, "worker.entry.dev.mjs",
    ),
  })
  out.push({
    path: "README.md",
    content: template_cloudflare_readme(project_name),
  })
  out.push({
    path: "playwright.config.ts",
    content: template_cloudflare_playwright_config_ts(),
  })
  out.push({
    path: "tests/e2e/worker-app.spec.ts",
    content: template_cloudflare_e2e_spec_ts(),
  })
  out
}

///|
/// Generate template files for a documentation site project
pub fn generate_doc_templates(
  package_name : String,
  project_name : String,
) -> Array[TemplateFile] {
  let sol_config = "{\n  \"islands\": [],\n  \"routes\": \"app/server\",\n  \"output\": \"app/__gen__\",\n  \"runtime\": \"node\",\n  \"staticDirs\": [\n    {\n      \"pathPrefix\": \"/docs\",\n      \"sourceDir\": \"docs\",\n      \"title\": \"\{project_name}\",\n      \"sidebar\": \"auto\",\n      \"trailingSlash\": true,\n      \"theme\": {\n        \"primaryColor\": \"#3b82f6\",\n        \"socialLinks\": [],\n        \"header\": {\n          \"left\": [\"logo\"],\n          \"right\": [\"navLinks\", \"themeToggle\"],\n          \"sticky\": true\n        },\n        \"footer\": {\n          \"message\": \"Built with Sol\",\n          \"copyright\": \"2025\"\n        }\n      }\n    }\n  ]\n}"
  let gitignore = template_gitignore() + "\ndist\n.sol-cache"
  [
    { path: ".gitignore", content: gitignore },
    {
      path: "moon.mod.json",
      content: template_moon_mod_json(package_name, None),
    },
    { path: "package.json", content: template_package_json(project_name) },
    { path: "sol.config.json", content: sol_config },
    {
      path: "app/server/moon.pkg",
      content: "import {\n  \"mizchi/sol\" @sol,\n  \"moonbitlang/async\",\n}\n\nsupported_targets = \"js\"\nwarnings = \"-67-29\"\n\noptions(\n  \"is-main\": true,\n  link: { \"js\": { \"format\": \"esm\" } },\n)",
    },
    { path: "app/server/main.mbt", content: template_routes_main_mbt() },
    {
      path: "app/server/routes.mbt",
      content: "///| Route definitions\n\npub fn routes() -> Array[@sol.SolRoutes] {\n  [\n    @sol.api_get(\"/api/health\", api_health),\n  ]\n}\n\npub fn config() -> @sol.RouterConfig {\n  @sol.RouterConfig::default()\n}\n\npriv struct HealthResponse {\n  status : String\n} derive(ToJson)\n\nasync fn api_health(_props : @sol.PageProps) -> HealthResponse {\n  { status: \"ok\" }\n}",
    },
    {
      path: "docs/index.md",
      content: "---\nlayout: home\ntitle: \{project_name}\n---\n\n# \{project_name}\n\nWelcome to \{project_name} documentation.\n\n## Getting Started\n\nSee the [Guide](/docs/guide/) to get started.\n",
    },
    {
      path: "docs/guide/index.md",
      content: "---\ntitle: Guide\n---\n\n# Guide\n\nThis section covers the basics of \{project_name}.\n",
    },
    {
      path: "docs/guide/getting-started.md",
      content: "---\ntitle: Getting Started\n---\n\n# Getting Started\n\n## Prerequisites\n\n- [MoonBit](https://moonbitlang.com/) toolchain\n- Node.js 24+\n- pnpm\n\n## Installation\n\n```bash\nmoon update\npnpm install\n```\n\n## Development\n\nStart the dev server:\n\n```bash\nsol dev\n```\n\nOpen [http://localhost:7777/docs/](http://localhost:7777/docs/) in your browser.\n\n## Build\n\n```bash\nsol build\n```\n\nThe output will be in the `dist/` directory.\n",
    },
    {
      path: "docs/guide/configuration.md",
      content: "---\ntitle: Configuration\n---\n\n# Configuration\n\nSol uses `sol.config.json` for project configuration.\n\n## Example\n\n```json\n{\n  \"staticDirs\": [\n    {\n      \"pathPrefix\": \"/docs\",\n      \"sourceDir\": \"docs\",\n      \"title\": \"My Docs\",\n      \"sidebar\": \"auto\"\n    }\n  ]\n}\n```\n\n## Options\n\n| Key | Type | Description |\n|-----|------|-------------|\n| `pathPrefix` | string | URL prefix for docs |\n| `sourceDir` | string | Directory containing markdown files |\n| `title` | string | Site title |\n| `sidebar` | string/array | `\"auto\"` or manual sidebar config |\n| `theme` | object | Theme customization |\n",
    },
    {
      path: "docs/api/index.md",
      content: "---\ntitle: API Reference\n---\n\n# API Reference\n\nAPI documentation for \{project_name}.\n",
    },
    {
      path: "README.md",
      content: "# \{project_name}\n\nDocumentation site built with [Sol](https://github.com/mizchi/luna.mbt/tree/main/sol).\n\n## Quick Start\n\n```bash\nmoon update\npnpm install\nsol dev\n```\n\nOpen http://localhost:7777/docs/\n\n## Project Structure\n\n```\ndocs/                 # Markdown documentation\n  index.md            # Home page\n  guide/              # Guide section\n  api/                # API reference\napp/\n  server/             # Server routes\nsol.config.json       # Sol configuration\n```\n",
    },
  ]
}
