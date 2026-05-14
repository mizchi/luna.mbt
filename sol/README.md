# mizchi/sol — SSR-first web framework for MoonBit

Sol is an SSR-first web framework implemented in MoonBit.
It adopts Island Architecture, combining server-side rendering with partial
client-side hydration. Static-site generation (SSG) lives in the sibling
[`mizchi/astra`](../astra/) package and mounts on the same Mars Server.

## Install

Library:

```jsonc
// moon.mod.json
{ "deps": { "mizchi/sol": "0.21.1", "mizchi/luna": "0.21.0" } }
```

CLI (binary):

```sh
moon install mizchi/sol/cmd/sol      # → $MOON_HOME/bin/sol
# or via npm
pnpm add -g @luna_ui/sol             # npm wrapper 0.20.0
```

## Playground

`examples/sol_app/` is the development playground (run from the repo
root after `moon build --target js --release`):

```bash
cd sol/examples/sol_app
pnpm install
sol dev
```

## Cloudflare Worker Composition

When `sol.config.json` uses `"runtime": "cloudflare"`, `sol build`
emits `.sol/prod/server/main.js` as a Worker-safe module with a stable
default export. Existing Workers can route some requests to Sol and keep
their own API handlers in the same Worker. New apps can start with this
wiring already in place:

```bash
sol new myapp --user mizchi --cloudflare
cd myapp
pnpm install
pnpm dev
```

The generated `worker.entry.mjs` is the public composition point:

```js
import solApp from "./.sol/prod/server/main.js";
import apiWorker from "./worker-api.mjs";

export default {
  fetch(request, env, ctx) {
    const path = new URL(request.url).pathname;
    return path.startsWith("/api/")
      ? apiWorker.fetch(request, env, ctx)
      : solApp.fetch(request, env, ctx);
  },
};
```

Keep Sol UI routes on `solApp.fetch(...)`, and expose custom MoonBit
Worker handlers behind a stable wrapper such as `worker-api.mjs` instead
of importing Sol's private `_build/js/...` output or waiting on
`globalThis.__SOL_APP__`.

## Runtime Asset Sync (Contributors)

Runtime assets (`loader.js`, `wc-loader.js`, `sol-nav.js`, `lib.js`) now
live in the sibling [`mizchi/astra`](../astra/) package under
`astra/src/assets/scripts/`. Sol's runtime resolves them via
`.mooncakes/mizchi/astra/src/assets/scripts/<name>` at request time.

When you update the Luna loader runtime, sync into astra (not sol):

```bash
just -f ../astra/justfile sync-luna-assets ../luna.mbt
```

## Static Site Generation

SSG capability moved to the dedicated [`mizchi/astra`](../astra/) package
in `0.16.0`. To build a docs / blog site, install `mizchi/astra` and use
`astra dev` / `astra build`. See `astra/README.md` and
`astra/examples/sol_docs/` for a working starter.

## Features

- **Hono Integration**: Server based on lightweight Hono
- **Island Architecture**: Hydrate only necessary parts
- **Type Safety**: Safe routing with MoonBit's type system
- **CLI Tools**: Consistent workflow from project creation to build
- **Streaming SSR**: Streaming support for async content
- **CSR Navigation**: SPA-like page transitions with `data-sol-link` attribute
- **Middleware**: Railway Oriented Programming based middleware system
- **Server Actions**: Server-side functions with CSRF protection
- **Nested Layouts**: Support for hierarchical layout structures

## Mars-first Responsibilities

Sol is organized around Mars as the server foundation, with these primary responsibilities:

- **File-based routing assignment**: Route mapping from files/config to handlers
- **SSR orchestration**: HTML/fragment rendering and response composition
- **Asset loading**: Static assets and hydration loader wiring
- **Wasm entrypoint orchestration (optional)**: `.mbtx` / `.wasm` mount manifest generation

Migration guide for existing Mars users: `docs/migrate-from-mars.md`
Documentation guide: `docs/README.md`
Onboarding guide: `docs/onboarding.md`
Quickstart guide: `docs/quickstart.md`
Deploy guide: `docs/deploy.md`
Runbook: `docs/runbook.md`
Troubleshooting guide: `docs/troubleshooting.md`
Worker auth guide: `docs/worker-auth.md`

## Quick Start

```bash
# Create new project
sol new myapp --user yourname
cd myapp

# Install dependencies
pnpm install

# Start development server
pnpm dev

# Build and deploy preflight (Cloudflare Workers default)
sol build
sol deploy --dry-run
```

## Configuration

`sol.config.ts` is the recommended configuration file. It should default-export a plain object.

```ts
export default {
  islands: ["app/client"],
  routes: "app/server",
  output: "app/__gen__",
  runtime: "node",
  // Defaults preserve the generated Sol pipeline.
  serverEntry: "auto", // "auto" | "generated" | "user"
  clientBundle: "auto", // "auto" | "external"
  client_auto_exports: false,
  wasmEntryPoints: [
    {
      id: "users_show",
      route: "/users/:id",
      source: "app/entries/users_show.mbtx",
      runtime: "wagi", // "wagi" | "wasi-cli" | "component"
      method: ["GET"],
    },
  ],
}
```

`serverEntry` and `clientBundle` split ownership of generated intermediates:

- `serverEntry: "auto"` keeps the historical behavior: `app/server/main.mbt`
  means user-managed server entry; otherwise Sol generates `app/__gen__/server`.
- `serverEntry: "user"` makes the server entry explicit and skips
  `app/__gen__/server` even if `main.mbt` is not present yet.
- `clientBundle: "external"` makes island discovery and bundling user-owned.
  Sol skips `app/__gen__/client`, `.sol/*/client`, and `.sol/*/manifest.json`.
  It still generates `app/__gen__/types` when it finds Props structs, so the
  server can keep a typed contract to frontend props while explicitly passing
  URLs served by your own bundler.

External bundles can still use SSR modulepreload without making Sol read or
write the client build graph. Load the bundler manifest in your app entry and
pass the JSON to `RouterConfig`:

```moonbit
let client_manifest =
  #|{
  #|  "app/client/counter.ts": {
  #|    "file": "assets/counter-abc123.js",
  #|    "imports": ["assets/runtime-def456.js"]
  #|  }
  #|}

pub fn config() -> @sol.RouterConfig {
  @sol.RouterConfig::default()
    .with_client_manifest_json(client_manifest, base_url="/static/")
}
```

The manifest may be keyed by source entry or emitted file, matching
Vite/Rolldown-style output. Island refs should point at the emitted URL, such
as `/static/assets/counter-abc123.js`; Sol only uses the supplied JSON to emit
the shared chunk `<link rel="modulepreload">` tags during SSR.

For external bundles, generated type helpers use URL injection:

```moonbit
@sol.island(
  @types.counter_at(
    "/static/assets/counter-abc123.js",
    { initial_count: 42 },
  ),
  [counter_ssr()],
)
```

This keeps `CounterProps` checked between the server and frontend without
letting Sol own the client bundle output path.

If you prefer JSON, `sol.config.json` is supported. For schema validation in this repo, add:

```json
{
  "$schema": "./schemas/sol.config.schema.json"
}
```

## Project Structure

Project structure generated by `sol new` (app server routes live in `app/server`):

```
myapp/
├── moon.mod.json           # MoonBit module definition
├── package.json            # npm package definition
├── sol.config.json         # Sol config file
├── worker.entry.mjs        # Cloudflare starter compose point (--cloudflare)
├── wrangler.toml           # Cloudflare Workers config (--cloudflare)
├── app/
│   ├── server/             # Server components
│   │   ├── moon.pkg
│   │   └── routes.mbt      # routes() + config() + page functions
│   ├── client/             # Client components (Islands)
│   │   ├── moon.pkg
│   │   ├── counter.mbt     # render + hydrate functions
│   │   └── api_tools.mbt   # copy/status/format starter controls
│   └── __gen__/            # Auto-generated (sol generate)
│       ├── client/         # Client exports
│       └── server/         # Server entry point
└── static/
    └── loader.js           # Island loader
```

The scaffold generated by `sol new` is defined in `src/cli/templates.mbt` and matches the layout above.

## CLI Commands

### `sol new <name> --user <namespace>`

Create a new project.

```bash
sol new myapp --user mizchi         # Create mizchi/myapp package
sol new myapp --user mizchi --cloudflare
sol new myapp --user mizchi --dev   # Use local luna path (for development)
```

### `sol dev`

Start development server. Auto-executes:
1. `sol generate --mode dev` - Code generation (outputs to `.sol/dev/`)
2. `moon build` - MoonBit build
3. `rolldown` - Client bundle (if manifest exists; skipped with `clientBundle: "external"`)
4. Start server

For `runtime: "cloudflare"`, `sol dev` starts `wrangler dev` instead of the
Node adapter. If the project has `wrangler.dev.toml`, that file is used;
otherwise Sol writes a fallback `.sol/dev/wrangler.toml` that runs
`.sol/dev/server/main.js`.

```bash
sol dev              # Default port 7777
sol dev --port 8080  # Specify port
sol dev --clean      # Clear cache and build
```

### `sol build`

Production build. Outputs to `.sol/prod/`.

```bash
sol build                 # JS target (default)
sol build --target wasm   # WASM target
sol build --skip-bundle   # Skip rolldown
sol build --skip-generate # Skip generation
sol build --clean         # Clear cache and build
sol build --wasm-entrypoints --runtime wagi --emit-spin-fragment
```

### `sol serve`

Serve production build. Requires prior `sol build`.

```bash
sol serve              # Default port 7777
sol serve --port 8080  # Specify port
```

### `sol deploy`

Deployment preflight and command guidance (`cloudflare-workers` default).

```bash
sol deploy                                          # Dry-run guidance
sol deploy --provider cloudflare-workers --project my-worker
sol deploy --execute                                # Execute wrangler command
```

### `sol doctor`

Diagnose local project wiring before build/serve/deploy. It checks
`sol.config.json`, route files, generated outputs, and whether the selected
runtime uses the matching adapter package (`sol_adapter_node` or
`sol_adapter_cloudflare`).

```bash
sol doctor          # Print warnings/errors
sol doctor --strict # Treat warnings as failures
```

### `sol generate`

Auto-generate code based on `sol.config.ts` (recommended) or `sol.config.json`. If both exist, `sol.config.ts` takes priority.

> **Note**: Usually `sol dev` and `sol build` call this internally, so explicit execution is not needed.

For a user-owned server entry and external client bundle, `sol generate` writes
the runtime server wrapper under `.sol/<mode>/server/`, built-in Sol assets, and
`app/__gen__/types` when Props contracts exist. It does not create
`app/__gen__/server`, `app/__gen__/client`, or client bundle manifests.

```bash
sol generate                    # Use sol.config.ts or sol.config.json (default: prod)
sol generate --mode dev         # Development mode (outputs to .sol/dev/)
sol generate --mode prod        # Production mode (outputs to .sol/prod/)
```

### `sol clean`

Delete generated files and cache.

```bash
sol clean  # Delete .sol/, app/__gen__/, _build/
```

## SolRoutes Definition

Declarative route definition using `@router.SolRoutes`:

```moonbit
// app/server/routes.mbt

pub fn routes() -> Array[@router.SolRoutes] {
  [
    // Page route
    @router.SolRoutes::Page(
      path="/",
      handler=@router.PageHandler(home_page),
      title="Home",
      meta=[],
      revalidate=None,
      cache=None,
    ),
    // API route (GET)
    @router.SolRoutes::Get(
      path="/api/health",
      handler=@router.ApiHandler(api_health),
    ),
    // API route (POST)
    @router.SolRoutes::Post(
      path="/api/submit",
      handler=@router.ApiHandler(api_submit),
    ),
    // Nested layout
    @router.SolRoutes::Layout(
      segment="/admin",
      layout=admin_layout,
      children=[
        @router.SolRoutes::Page(path="/", handler=@router.PageHandler(admin_dashboard), title="Admin", meta=[], revalidate=None, cache=None),
        @router.SolRoutes::Page(path="/users", handler=@router.PageHandler(admin_users), title="Users", meta=[], revalidate=None, cache=None),
      ],
    ),
    // Apply middleware
    @router.SolRoutes::WithMiddleware(
      middleware=[@middleware.cors(), @middleware.logger()],
      children=[
        @router.SolRoutes::Get(path="/api/data", handler=@router.ApiHandler(api_data)),
      ],
    ),
  ]
}

pub fn config() -> @router.RouterConfig {
  @router.RouterConfig::default()
    .with_default_head(head())
    .with_loader_url("/static/loader.js")
```

### SolRoutes Variants

| Variant | Description |
|---------|-------------|
| `Page` | Page route (HTML response) |
| `Get` | GET API route (JSON response) |
| `Post` | POST API route (JSON response) |
| `RawGet` / `RawPost` / `RawPut` / `RawDelete` / `RawPatch` | Raw Web `Response` route |
| `Layout` | Nested layout group |
| `WithMiddleware` | Route group with middleware applied |

### Router API Selection

- `@router.register_routes` / `@router.register_server_routes`
  - Input: `@luna/core/routes.Routes`
  - Purpose: Thin file-based routing assignment
  - `Layout` is treated as path prefix grouping only (no layout function composition)
- `@router.register_sol_routes`
  - Input: `@router.SolRoutes`
  - Purpose: Handles `ServerNode`-based SSR including layout composition
  - Actually applies `SolRoutes::Layout`

Single source of truth: `docs/routing.md`
Refer to this document for `Layout` application rules, raw response routes,
route/component asset attachment, and `source_path` dynamic parameter format.

Route and component assets are first-class Sol metadata. Use
`RouterConfig.with_style(...)` / `.with_client_script(...)` for app-wide
assets, `page(..., styles=[...], scripts=[...])` or `assets(...)` for
route-scoped assets, and `with_style(...)` / `with_assets(...)` for
component-local CSS and client modules. Local paths are emitted under
`/static/` and deduplicated deterministically.

Hot Reload design: `docs/hot-reload.md`
Benchmark procedures and `SOL_BENCH_MODE` specification: `docs/benchmarking.md`

### Route Ownership And Errors

Sol is allowed to own only part of a deployed Worker. In mixed apps, keep
ownership explicit in the host entry. `route_ownership_manifest(routes)` gives
host routers a typed Sol ownership contract for pages, JSON APIs, raw
responses, static assets, and reserved framework paths.

The same manifest can be used as an optional JSON API client source:
`manifest.api_client_manifest_json()` returns method/path/param metadata, and
`manifest.api_client_typescript()` emits browser/Worker `fetch` helpers with a
typed `SolApiResult<T>` success/error shape.

```js
import solApp from "./.sol/prod/server/main.js";

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    if (url.pathname.startsWith("/api/")) {
      return apiFetch(request, env, ctx);
    }
    return solApp.fetch(request, env, ctx);
  },
};
```

Recommended split:

- Sol page routes own HTML responses, layout composition, fragments, and
  framework assets such as `/__sol__/*` and `/static/*`.
- Sol API routes own JSON responses declared with `api_get`, `api_post`,
  `api_put`, `api_delete`, or `api_patch`.
- Raw Sol routes own exact Web `Response` values declared with `raw_get`,
  `raw_post`, `raw_put`, `raw_delete`, or `raw_patch`.
- Host Worker routes own platform-specific passthroughs such as service
  binding proxies and auth callbacks.

Error handling follows the owning layer. Sol page handler/layout failures
return HTML/text `500` responses. Sol API handler failures return JSON
`500` responses. Raw handler failures return plain text `500`; otherwise the
raw `Response` body/status are not wrapped. Middleware response headers are
merged into raw responses without overwriting headers that the raw `Response`
already set. A route that is intentionally outside Sol should be matched before
`solApp.fetch`; if neither the host nor Sol owns it, return the host fallback
`404` from the Worker entry.

## Middleware

Railway Oriented Programming based middleware system.

### Basic Usage

```moonbit
// Middleware composition
let middleware = @middleware.logger()
  .then(@middleware.cors())
  .then(@middleware.security_headers())

// Apply to routes
@router.SolRoutes::WithMiddleware(
  middleware=[middleware],
  children=[...],
)
```

### Built-in Middleware

| Middleware | Description |
|------------|-------------|
| `logger()` | Request logging |
| `cors()` | CORS headers |
| `csrf()` | CSRF protection |
| `security_headers()` | Security headers |
| `nosniff()` | X-Content-Type-Options |
| `frame_options(value)` | X-Frame-Options |

### CORS Configuration

```moonbit
@middleware.cors_with_config(
  @middleware.CorsConfig::default()
    .with_origin_single("https://example.com")
    .with_methods(["GET", "POST"])
    .with_credentials()
)
```

### Security Headers

```moonbit
@middleware.security_headers_with_config(
  @middleware.SecurityHeadersConfig::default()
    .with_csp("default-src 'self'")
    .with_frame_options("DENY")
)
```

### Route-Level Auth For Worker Apps

Middleware can protect a route group and may read request headers through the
Mars context. To halt, send a response from the middleware; to continue, return
without sending.

```moonbit
fn require_admin() -> @middleware.Middleware {
  @middleware.Middleware(@mars.Handler(async fn(ctx) {
    match ctx.header("Authorization") {
      Some(token) if token.has_prefix("Bearer ") => ()
      _ => ctx.json({ "error": "unauthorized" }.to_json(), status=401)
    }
  }))
}

pub fn routes() -> Array[@sol.SolRoutes] {
  [
    @sol.route("/", home),
    @sol.with_mw([require_admin()], [
      @sol.route("/admin", admin_page),
      @sol.api_post("/api/items", create_item),
    ]),
  ]
}
```

For Cloudflare bindings, keep the env-specific routing in the host Worker
entry until a typed binding contract is available. Pass host-owned requests to
the Worker API layer first, then fall back to Sol for UI routes.

### Middleware Composition

```moonbit
// Sequential execution (m1 → m2)
let combined = @middleware.then_(m1, m2)
// or
let combined = m1.then(m2)

// Compose from array
let pipeline = @middleware.pipeline([m1, m2, m3])
```

## Server Actions

Server-side functions with CSRF protection. See [Server Actions README](./action/README.md) for details.

### Basic Usage

```moonbit
// Define action handler
let submit_handler = @action.ActionHandler(async fn(ctx) {
  let body = ctx.body
  // ... processing
  @action.ActionResult::ok(@js.any({ "success": true }))
})

// Register to registry
pub fn action_registry() -> @action.ActionRegistry {
  @action.ActionRegistry::new(allowed_origins=["http://localhost:7777"])
    .register(@action.ActionDef::from_key(@types.action_submit(), submit_handler))
}
```

### ActionResult Types

| Type | Description |
|------|-------------|
| `Success(data)` | Success, returns JSON data |
| `Redirect(url)` | Client-side redirect (returns JSON with redirect instruction) |
| `HttpRedirect(url)` | HTTP redirect (returns 302 with Location header) |
| `ClientError(status, msg)` | Client error (4xx) |
| `ServerError(msg)` | Server error (5xx) |

## Island Architecture

### Island Components

Island is a component shared between SSR and client:

```moonbit
// app/client/counter.mbt

pub fn counter(count : @signal.Signal[Int]) -> @luna.Node[CounterAction] {
  div(class="counter", [
    span(class="count-display", [text_of(count)]),
    button(onclick=@luna.action(Increment), [text("+")]),
    button(onclick=@luna.action(Decrement), [text("-")]),
  ])
}
```

### Embedding Islands (Server-side)

Use `ComponentRef`-based API for type-safe island embedding. `sol generate` auto-generates factory functions from client Props types.

```moonbit
// Auto-generated: app/__gen__/types/types.mbt
pub struct CounterProps { initial_count : Int } derive(ToJson, FromJson)
pub fn counter(props : CounterProps, trigger~ : @luna.Trigger) -> @luna.ComponentRef[CounterProps]
```

**Recommended: `@sol.island()` with ComponentRef**

```moonbit
// app/server/home.mbt
let counter_props : @types.CounterProps = { initial_count: 42 }

// Type-safe island embedding
@sol.island(
  @types.counter(counter_props),
  [div([button([text("Count: 42")])])],  // SSR fallback children
)
```

**Alternative: `@server_dom.client()` (equivalent)**

```moonbit
@server_dom.client(
  @types.counter(counter_props),
  [div([text("Loading...")])],
)
```

**Low-level: `@sol.island_raw()` (string-based, not recommended)**

```moonbit
@sol.island_raw("counter", "/static/counter.js", props_json, children)
```

### Hydration Triggers

| Trigger | Description |
|---------|-------------|
| `Load` | Immediately on page load |
| `Idle` | On requestIdleCallback |
| `Visible` | On IntersectionObserver detection |
| `Media(query)` | On media query match |
| `None` | Manual trigger |

### Hydration Module Origin Policy

`loader.js` only allows same-origin module URLs by default.
Cross-origin hydration modules are blocked unless host/origin is explicitly allowed.

```html
<script>
  window.__LUNA_ALLOWED_HOSTS__ = [
    "127.0.0.1:3456",
    "https://cdn.example.com"
  ];
</script>
```

You can also update this allowlist at runtime, then re-scan islands:

```js
window.__LUNA_SET_ALLOWED_HOSTS__?.(["127.0.0.1"]);
window.__LUNA_SCAN__?.();
```

## CSR Navigation

Links with `data-sol-link` attribute are processed as CSR. Use the `sol_link` helper:

```moonbit
sol_link(href="/about", [text("About")])
```

Behavior on click:
1. `sol-nav.js` intercepts the click
2. `fetch` gets new page HTML
3. Replace `<main id="main-content">` content
4. Update browser history with History API
5. Hydrate Islands on the new page

## Streaming SSR

Streaming async content using `ServerNode::async_`:

```moonbit
@server_dom.ServerNode::async_(async fn() {
  let data = fetch_data()  // async function call
  div([text(data)])
})
```

To use streaming responses with `register_sol_routes`, enable it in `RouterConfig` (disabled by default).

```moonbit
pub fn config() -> @router.RouterConfig {
  @router.RouterConfig::default()
    .with_default_head(head())
    .with_loader_url("/static/loader.js")
    .with_streaming_ssr()
}
```

> Note: streaming response uses `root_template` when `__LUNA_MAIN__` exists; otherwise it falls back to built-in page shell.

## Module Structure

```
src/sol/
├── runtime.mbt      # Core API
├── compiler.mbt     # Rolldown bindings
├── router/          # Hono router integration
│   ├── router.mbt   # Route registration
│   ├── sol_routes.mbt # SolRoutes definition
│   └── fragment.mbt # Fragment response (CSR)
├── middleware/      # Middleware system
│   ├── types.mbt    # MwContext, MwRequest, MwResponse
│   ├── compose.mbt  # Composition functions (then, pipeline)
│   ├── logger.mbt   # Logger middleware
│   ├── cors.mbt     # CORS middleware
│   ├── csrf.mbt     # CSRF middleware
│   └── security_headers.mbt # Security headers
├── action/          # Server Actions
│   ├── action.mbt   # ActionHandler, ActionResult
│   └── router.mbt   # register_actions
└── cli/             # CLI tools
    ├── main.mbt     # Entry point
    ├── new.mbt      # sol new
    ├── dev.mbt      # sol dev
    ├── build.mbt    # sol build
    ├── serve.mbt    # sol serve
    ├── generate.mbt # sol generate
    └── clean.mbt    # sol clean
```

## References

- [Server Actions](./action/README.md) - Server Actions details
- [Luna Core](../luna/README.md) - VNode/Signal details
- [Stella](../stella/README.md) - Island embedding mechanism
