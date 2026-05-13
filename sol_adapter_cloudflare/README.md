# sol_adapter_cloudflare

Cloudflare adapter utilities for Sol.

This package depends on `mizchi/sol` and keeps Cloudflare/Wrangler-specific
route conversion outside the Sol core package.

## Worker runtime

Use this package from a Cloudflare-targeted Sol server entry:

```moonbit
async fn main {
  @sol_cloudflare.run_app(fn() {
    @sol.create_app(routes(), config=config())
  })
}
```

The exported app supports the Worker shape:

```js
export default {
  fetch(request, env, ctx) {
    return solApp.fetch(request, env, ctx);
  },
};
```

`env` and `ctx` are passed into Mars/Sol request context, so route handlers and
middleware can use `ctx.env_var("NAME")` and `ctx.wait_until(...)`.

## Binding validation

Declare the bindings a Worker expects and fail early in local tests or Worker
entry code:

```moonbit
let missing = @sol_cloudflare.missing_required_bindings(env, [
  @sol_cloudflare.env_var("API_TOKEN"),
  @sol_cloudflare.kv_namespace("CACHE"),
  @sol_cloudflare.r2_bucket("MEDIA"),
])
```

## Generators

- `generate_cloudflare_server_entry_js(...)` creates an edge-safe Sol server
  module wrapper without top-level timers or Node imports.
- `generate_worker_entry_js(...)` creates a host Worker composition entry that
  routes `/api/*` before delegating to Sol.
- `generate_wrangler_toml(...)` and `generate_wrangler_assets_config(...)`
  generate Wrangler config fragments with string escaping handled by the
  adapter.
