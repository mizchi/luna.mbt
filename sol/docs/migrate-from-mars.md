# Migration Guide from Mars to Sol

`sol` is designed as a thin wrapper around `mars`, so you can migrate incrementally.

## Strategy

- Keep existing `@mars.Server::new()` / `app.get` / `app.post` as-is
- First, consolidate only the entrypoint to `sol`
- Replace only the HTML rendering with `sol.page`
- Finally, introduce file-based routing / `SolRoutes` as needed

## 1. Consolidate the Entrypoint to sol

Consolidate just the startup to `@sol.run_app` with almost no changes to existing route registration code.

```moonbit
// before: standalone startup with mars
// after: unify the startup boundary with sol

fn configure_app() -> @mars.Server {
  let app = @mars.Server::new()
  register_api_routes(app) // reuse existing mars handler group as-is
  app
}

fn main {
  @sol.run_app(configure_app)
}
```

## 2. Keep API Routes As-Is

Since `sol` uses `App = @mars.Server` / `Ctx = @mars.Context`, API routes can be written the same way as before.

```moonbit
fn register_api_routes(app : @mars.Server) -> Unit {
  app.get(
    "/api/health",
    @mars.handler(async fn(c) {
      c.json(@sol.json_obj([("ok", @js.any(true))]))
    }),
  )
}
```

## 3. Migrate Only HTML Routes to `sol.page`

Consolidate hand-written HTML responses to `sol`'s SSR helpers.

```moonbit
fn home(_c : @mars.Context) -> @luna.Node[Unit, String] {
  @luna.h1([@luna.text("Hello from Sol SSR")])
}

fn register_pages(app : @mars.Server) -> Unit {
  @sol.page(app, "/", home, title="Home")
}
```

## 4. Unify static / HMR

- Static file serving: `@sol.serve_static(app)`
- HMR script injection: Already unified in `@sol.page` / `@router.register_sol_routes`
- Direct usage: `@hot_reload.with_dev_head_script(head)`

## 5. Migrate Routing Incrementally

- For lightweight file-based routing: `@router.register_routes`
- For routing with layout composition: `@router.register_sol_routes`

## API Correspondence Table

| Existing (mars) | Migration target (sol) | Notes |
|---|---|---|
| `@mars.Server::new()` | As-is | `sol` uses the same app type |
| `app.get/post/...` | As-is | API routes can basically remain unchanged |
| `@mars.Context` | `@mars.Context` | Use as-is |
| Hand-written HTML strings | `@sol.page` / `@sol.render_page` | Unifies SSR and HMR injection |
| Custom startup code | `@sol.run` / `@sol.run_app` | Unifies the startup boundary |

## Notes

- `@sol.serve` / `@sol.create_app_then` have been removed (use `@sol.run` / `@sol.run_app`)
- `@sol.get_port` / `@sol.get_hmr_port` / `@sol.get_hmr_script` / `@sol.set_env` have been removed (use `@hot_reload.*` and CLI-side env configuration)
- `@sol.text_response` / `@sol.js_response` / `@sol.static_response` / `@sol.read_file_sync` have been removed (use `Ctx`'s `text/html/json` and the static serve API)
- It is safest to migrate only the "startup boundary" and "HTML routes" first, leaving API routes unchanged
