# Worker Auth And Middleware Patterns

This guide describes the recommended split for authentication and
authorization in Cloudflare Worker apps that embed Sol UI routes.

## Ownership

Keep platform-specific code at the Worker boundary. `worker.entry.mjs` should
route existing Worker APIs, service binding proxies, media endpoints, and auth
callbacks before delegating unmatched UI requests to Sol:

```js
import solApp from "./.sol/prod/server/main.js";
import apiWorker from "./worker-api.mjs";

export default {
  fetch(request, env, ctx) {
    const path = new URL(request.url).pathname;
    if (path.startsWith("/api/")) {
      return apiWorker.fetch(request, env, ctx);
    }
    return solApp.fetch(request, env, ctx);
  },
};
```

Read Cloudflare env bindings in this host layer when the code depends on
Workers-only resources such as KV, R2, D1, Queues, Durable Objects, secrets, or
service bindings. Sol core should only receive the Web-standard `Request`,
`Response`, and `ctx` shape through the adapter.

## Route Group Middleware

Use Sol middleware for route-local policy that does not need a typed
Cloudflare binding contract. Middleware can inspect `Authorization`, cookies,
or a custom header through the Mars context. To halt, send a response. To
continue, return without sending.

```moonbit
fn require_admin() -> @middleware.Middleware {
  @middleware.Middleware(@mars.Handler(async fn(ctx) {
    let auth = ctx.header("Authorization")
    let role = ctx.header("X-Admin-Role") // custom header
    match (auth, role) {
      (Some(token), Some("admin")) if token.has_prefix("Bearer ") => ()
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

This pattern protects a route group without moving platform-specific bindings
into Sol. Put common logging, CORS, security headers, and cheap header checks
in middleware. Put binding-heavy authorization in the host Worker or adapter.

## API Versus Page Failures

Return a JSON error for API routes:

```moonbit
ctx.json({ "error": "unauthorized" }.to_json(), status=401)
```

For page routes, prefer an HTML response or redirect owned by the page layer:

```moonbit
ctx.redirect("/login", status=302)
```

If the path is Worker-owned, return the Worker JSON/HTML response before
calling `solApp.fetch`. If the path is Sol-owned, let Sol route middleware and
page/API handlers decide the response. This keeps API clients from receiving
HTML and keeps browser navigations from receiving unexpected JSON.

## Cloudflare Env And Secrets

Secrets should come from Cloudflare env, not from source files:

```js
function requireWriteToken(request, env) {
  return request.headers.get("Authorization") === `Bearer ${env.WRITE_TOKEN}`;
}
```

For local development, use a documented development token or a `.dev.vars`
file that is ignored by git. The `sol new --cloudflare` starter uses
`Bearer dev-token` only as a local placeholder and documents `wrangler secret
put WRITE_TOKEN` for production.

## Local Dev And Test Setup

For Cloudflare projects, use Wrangler as the actual host:

```bash
pnpm dev
# or directly
wrangler dev --config wrangler.dev.toml
```

E2E tests should drive the Worker entry rather than importing private
`_build/js/...` artifacts. The generated starter uses Playwright with a
`webServer` command that starts `pnpm dev`, then tests both the Sol-rendered
page and Worker-owned API endpoints.

## Composition Checklist

- Match Worker-owned APIs first in `worker.entry.mjs`.
- Delegate Sol-owned pages, framework assets, and Sol JSON/raw routes to
  `solApp.fetch(request, env, ctx)`.
- Use `@sol.with_mw([...], [...])` for route group policy.
- Keep Cloudflare env access in the host Worker or platform adapter.
- Return JSON error responses for API routes and HTML/redirect responses for
  page routes.
