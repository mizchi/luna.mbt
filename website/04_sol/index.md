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
- **CSR Navigation** - SPA-like navigation with `sol-link`
- **Middleware** - Railway Oriented Programming based middleware
- **Server Actions** - CSRF-protected server-side functions
- **Nested Layouts** - Hierarchical layout structures

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
│   │   ├── moon.pkg.json
│   │   └── routes.mbt      # routes() + config() + pages
│   ├── client/             # Client components (Islands)
│   │   └── counter/
│   │       ├── moon.pkg.json
│   │       └── counter.mbt # render + hydrate functions
│   └── __gen__/            # Auto-generated (sol generate)
│       ├── client/         # Client exports
│       └── server/         # Server entry point
└── static/
    └── loader.min.js       # Island loader
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
sol dev              # Default port 3000
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
sol serve              # Default port 3000
sol serve --port 8080  # Custom port
```

### `sol generate`

Generate code from `sol.config.json`.

```bash
sol generate                    # Use sol.config.json (default: dev)
sol generate --mode dev         # Development mode (.sol/dev/)
sol generate --mode prod        # Production mode (.sol/prod/)
```

### `sol clean`

Delete generated files and cache.

```bash
sol clean  # Delete .sol/, app/__gen__/, target/
```

## SolRoutes Definition

Declarative route definition with `SolRoutes`:

```moonbit
// app/server/routes.mbt

pub fn routes() -> Array[SolRoutes] {
  [
    // Page route
    SolRoutes::Page(
      path="/",
      handler=PageHandler(home_page),
      title="Home",
      meta=[],
    ),
    // GET API route
    SolRoutes::Get(
      path="/api/health",
      handler=ApiHandler(api_health),
    ),
    // POST API route
    SolRoutes::Post(
      path="/api/submit",
      handler=ApiHandler(api_submit),
    ),
    // Nested layout
    SolRoutes::Layout(
      segment="admin",
      layout=admin_layout,
      children=[
        SolRoutes::Page(path="/admin", handler=PageHandler(admin_dashboard), title="Admin"),
        SolRoutes::Page(path="/admin/users", handler=PageHandler(admin_users), title="Users"),
      ],
    ),
    // With middleware
    SolRoutes::WithMiddleware(
      middleware=[@middleware.cors(), @middleware.logger()],
      children=[
        SolRoutes::Get(path="/api/data", handler=ApiHandler(api_data)),
      ],
    ),
  ]
}

pub fn config() -> RouterConfig {
  RouterConfig::default()
    .with_default_head(head())
    .with_loader_url("/static/loader.min.js")
}
```

### SolRoutes Variants

| Variant | Description |
|---------|-------------|
| `Page` | Page route (HTML response) |
| `Get` | GET API route (JSON response) |
| `Post` | POST API route (JSON response) |
| `Layout` | Nested layout group |
| `WithMiddleware` | Routes with middleware applied |

## Nested Layouts

Hierarchical layout structure support:

```moonbit
// Admin section layout
fn admin_layout(
  props : PageProps,
  content : ServerNode,
) -> ServerNode raise {
  ServerNode::sync(@luna.fragment([
    h1([text("Admin Panel")]),
    nav([
      a(href="/admin", attrs=[("sol-link", @luna.attr_static(""))], [text("Dashboard")]),
      a(href="/admin/users", attrs=[("sol-link", @luna.attr_static(""))], [text("Users")]),
    ]),
    div(class="admin-content", [content.to_vnode()]),
  ]))
}

// Route definition
SolRoutes::Layout(
  segment="admin",     // URL prefix
  layout=admin_layout, // Layout function
  children=[
    SolRoutes::Page(path="/admin", handler=PageHandler(admin_dashboard), title="Admin"),
    SolRoutes::Page(path="/admin/users", handler=PageHandler(admin_users), title="Users"),
  ],
)
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
SolRoutes::WithMiddleware(
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
  CorsConfig::default()
    .with_origin_single("https://example.com")
    .with_methods(["GET", "POST"])
    .with_credentials()
)
```

### Security Headers

```moonbit
@middleware.security_headers_with_config(
  SecurityHeadersConfig::default()
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

// Conditional execution
let conditional = @middleware.when(
  fn(ctx) { ctx.request.method == "POST" },
  csrf_middleware,
)
```

## Server Actions

CSRF-protected server-side functions.

### Basic Usage

```moonbit
// Define action handler
let submit_handler = ActionHandler(async fn(ctx) {
  let body = ctx.body
  // ... process
  ActionResult::ok(@js.any({ "success": true }))
})

// Register in registry
pub fn action_registry() -> ActionRegistry {
  ActionRegistry::new(allowed_origins=["http://localhost:3000"])
    .register(ActionDef::new("submit-form", submit_handler))
}
```

### ActionResult Types

| Type | Description |
|------|-------------|
| `Success(data)` | Success, return JSON data |
| `Redirect(url)` | Success, redirect |
| `ClientError(status, msg)` | Client error (4xx) |
| `ServerError(msg)` | Server error (5xx) |

## Island Architecture

### Island Component

Islands are components shared between SSR and client:

```moonbit
// app/client/counter/counter.mbt

pub fn counter(count : Signal[Int]) -> @luna.Node[CounterAction] {
  div(class="counter", [
    span(class="count-display", [text_signal(count)]),
    button(onclick=@luna.action(Increment), [text("+")]),
    button(onclick=@luna.action(Decrement), [text("-")]),
  ])
}
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

Links with `sol-link` attribute are handled as CSR:

```moonbit
a(href="/about", attrs=[("sol-link", @luna.attr_static(""))], [text("About")])
```

Click behavior:
1. `sol-nav.js` intercepts click
2. `fetch` retrieves new page HTML
3. Replace `<main id="main-content">` content
4. Update browser history with History API
5. Hydrate new page Islands

## Streaming SSR

Async content streaming:

```moonbit
@luna.vasync(async fn() {
  let data = fetch_data().await
  div([text(data)])
})
```

## See Also

- [Luna UI](/luna/) - Core reactivity concepts
- [Astra SSG](/astra/) - Static site generation
- [Stella](/stella/) - Web Components
