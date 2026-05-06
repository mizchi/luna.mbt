---
title: Sol Framework
---

# Sol Framework

> **Experimental**: Sol is under active development. APIs may change.

Sol is a full-stack SSR framework built on Luna UI and MoonBit. It provides Island Architecture with server-side rendering and partial hydration.

## Features

- **Hono Integration** - Fast, lightweight HTTP server
- **Island Architecture** - Ship minimal JavaScript with smart triggers
- **File-based Routing** - Pages and API routes from directory structure
- **Type-safe** - MoonBit types flow from server to browser
- **Streaming SSR** - Async content streaming support
- **CSR Navigation** - SPA-like navigation with `data-sol-link`
- **Middleware** - Railway Oriented Programming based middleware
- **Server Actions** - CSRF-protected server-side functions
- **Nested Layouts** - Hierarchical layout structures
- **Docs / SSG** - Docs-only sites via Sol SSG, or hybrid docs via `staticDirs`

## Quick Start

```bash
# Create a new Sol project
npx @luna_ui/sol new myapp --user yourname
cd myapp

# Install dependencies
npm install

# Start development server
npm run dev
```

## Project Structure

```
myapp/
├── moon.mod.json           # MoonBit module
├── package.json            # npm package
├── sol.config.json         # Sol configuration
├── app/
│   ├── server/             # Server components
│   │   ├── moon.pkg
│   │   └── routes.mbt      # routes() + config() + pages
│   ├── client/             # Client components (Islands)
│   │   ├── moon.pkg
│   │   └── counter.mbt     # render + hydrate functions
│   └── __gen__/            # Auto-generated (sol generate)
│       ├── client/         # Client exports
│       └── server/         # Server entry point
└── static/
    └── loader.js           # Island loader
```

## Guides

- [SolRoutes Definition](#solroutes-definition) - Declarative route definition
- [Nested Layouts](#nested-layouts) - Hierarchical layout structure
- [Middleware](#middleware) - Railway Oriented Programming based middleware
- [Server Actions](#server-actions) - CSRF-protected server functions
- [Island Architecture](#island-architecture) - SSR with partial hydration

## CLI Reference

### `sol new <name>`

Create a new project.

```bash
sol new myapp --user mizchi         # Create mizchi/myapp package
sol new myapp --user mizchi --dev   # Use local luna paths (development)
```

### `sol dev`

Start development server. Automatically runs:
1. `sol generate --mode dev` - Code generation
2. `moon build` - MoonBit build
3. `rolldown` - Client bundle (if manifest exists)
4. Start server

```bash
sol dev              # Default port 7777
sol dev --port 8080  # Custom port
sol dev --clean      # Clean cache and rebuild
```

### `sol build`

Production build. Outputs to `.sol/prod/`.

```bash
sol build                 # JS target (default)
sol build --target wasm   # WASM target
sol build --skip-bundle   # Skip rolldown
sol build --skip-generate # Skip generation
sol build --clean         # Clean cache and rebuild
```

### `sol serve`

Serve production build. Requires `sol build` first.

```bash
sol serve              # Default port 7777
sol serve --port 8080  # Custom port
```

### `sol generate`

Generate code from `sol.config.ts` or `sol.config.json`.

```bash
sol generate                    # Use sol.config.ts or sol.config.json (default: prod)
sol generate --mode dev         # Development mode (.sol/dev/)
sol generate --mode prod        # Production mode (.sol/prod/)
```

### `sol clean`

Delete generated files and cache.

```bash
sol clean  # Delete .sol/, app/__gen__/, _build/
```

## SolRoutes Definition

Declarative route definition using `@sol` helper functions:

```moonbit
// app/server/routes.mbt

pub fn routes() -> Array[@sol.SolRoutes] {
  [
    // Page route
    @sol.route("/", home_page, title="Home"),
    // GET API route
    @sol.api_get("/api/health", api_health),
    // POST API route
    @sol.api_post("/api/submit", api_submit),
    // Nested layout
    @sol.wrap("/admin", admin_layout, [
      @sol.route("/", admin_dashboard, title="Admin"),
      @sol.route("/users", admin_users, title="Users"),
    ]),
    // With middleware
    @sol.with_mw([@middleware.cors(), @middleware.logger()], [
      @sol.api_get("/api/data", api_data),
    ]),
  ]
}

pub fn config() -> @sol.RouterConfig {
  @sol.RouterConfig::default()
    .with_default_head(head())
    .with_loader_url("/static/loader.js")
}
```

### Route Helper Functions

| Function | Description |
|----------|-------------|
| `@sol.route(path, handler, title=...)` | Page route (HTML response) |
| `@sol.api_get(path, handler)` | GET API route (JSON response) |
| `@sol.api_post(path, handler)` | POST API route (JSON response) |
| `@sol.api_put(path, handler)` | PUT API route (JSON response) |
| `@sol.api_delete(path, handler)` | DELETE API route (JSON response) |
| `@sol.wrap(segment, layout, children)` | Nested layout group |
| `@sol.with_mw(middleware, children)` | Routes with middleware applied |
| `@sol.nodes(content)` | Create sync ServerNode from nodes |

## Nested Layouts

Hierarchical layout structure support:

```moonbit
// Admin section layout
using @server_dom {
  h1,
  nav,
  div,
  text,
  sol_link,
}

fn admin_layout(
  _props : @sol.PageProps,
  content : @server_dom.ServerNode,
) -> @server_dom.ServerNode raise {
  @sol.nodes([
    h1([text("Admin Panel")]),
    nav([
      sol_link(href="/admin", [text("Dashboard")]),
      sol_link(href="/admin/users", [text("Users")]),
    ]),
    div(class="admin-content", [content.to_vnode()]),
  ])
}

// Route definition
// segment="/admin" + path="/" => /admin
// segment="/admin" + path="/users" => /admin/users
@sol.wrap("/admin", admin_layout, [
  @sol.route("/", admin_dashboard, title="Admin"),
  @sol.route("/users", admin_users, title="Users"),
])
```

## Middleware

Railway Oriented Programming based middleware system.

### Basic Usage

```moonbit
// Compose middleware
let middleware = @middleware.logger()
  .then(@middleware.cors())
  .then(@middleware.security_headers())

// Apply to routes
@sol.with_mw([middleware], [
  @sol.api_get("/api/data", get_data),
])
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

### Middleware Composition

```moonbit
// Sequential execution (m1 -> m2)
let combined = @middleware.then_(m1, m2)
// or
let combined = m1.then(m2)

// Compose from array
let pipeline = @middleware.pipeline([m1, m2, m3])
```

## Server Actions

CSRF-protected server-side functions.

### Basic Usage

```moonbit
// Define action handler
let submit_handler = @action.ActionHandler(async fn(ctx) {
  let body = ctx.body
  // ... process
  @action.ActionResult::ok(@js.any({ "success": true }))
})

// Register in registry
pub fn action_registry() -> @action.ActionRegistry {
  @action.ActionRegistry::new(allowed_origins=["http://localhost:7777"])
    .register(@action.ActionDef::new("submit-form", submit_handler))
}
```

### ActionResult Types

| Type | Description |
|------|-------------|
| `Success(data)` | Success, return JSON data |
| `Redirect(url)` | Client-side redirect (returns JSON with redirect instruction) |
| `HttpRedirect(url)` | HTTP redirect (returns 302 with Location header) |
| `ClientError(status, msg)` | Client error (4xx) |
| `ServerError(msg)` | Server error (5xx) |

## Island Architecture

### Island Component

Islands are components shared between SSR and client:

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
| `Load` | Immediate on page load |
| `Idle` | On requestIdleCallback |
| `Visible` | On IntersectionObserver detection |
| `Media(query)` | On media query match |
| `None` | Manual trigger |

## CSR Navigation

Links with `data-sol-link` attribute are handled as CSR. Use the `sol_link` helper:

```moonbit
sol_link(href="/about", [text("About")])
```

Click behavior:
1. `sol-nav.js` intercepts click
2. `fetch` retrieves new page HTML
3. Replace `<main id="main-content">` content
4. Update browser history with History API
5. Hydrate new page Islands

## Streaming SSR

Async content streaming using `ServerNode::async_`:

```moonbit
@server_dom.ServerNode::async_(async fn() {
  let data = fetch_data()  // async function call
  div([text(data)])
})
```

Enable route-level streaming responses with router config (disabled by default):

```moonbit
pub fn config() -> @sol.RouterConfig {
  @sol.RouterConfig::default()
    .with_default_head(head())
    .with_loader_url("/static/loader.js")
    .with_streaming_ssr()
}
```

> Note: streaming response uses `root_template` when `__LUNA_MAIN__` exists; otherwise it falls back to built-in page shell.

## Modes

Sol supports three usage styles:

### App (default)

- SSR app with islands
- Requires `moon.mod.json`
- `sol dev` starts the app server

### SSG-only (docs)

Docs site with Sol SSG (no app). Detected when `sol.config.json` has `ssg` or `docs` section **and** no `moon.mod.json`.

```bash
sol new my-docs --ssg
sol dev    # SSG dev server with HMR
sol build  # Static site build
sol lint   # Lint SSG content
```

For SSG-specific features and configuration, see [Sol SSG](/sol/ssg/).

### Hybrid (app + docs)

Keep the app and mount docs under a path using `staticDirs`:

```json
{
  "staticDirs": [
    { "path_prefix": "/docs", "source_dir": "docs", "title": "Docs" }
  ]
}
```

- `sol build` builds the app and docs
- `sol dev` runs the app server (use `sol dev --mode ssg` to preview docs)

## See Also

- [Luna UI](/luna/) - Core reactivity concepts
- [Sol SSG](/sol/ssg/) - Static site generation
