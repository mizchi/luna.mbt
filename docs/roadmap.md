# Sol Native Compatibility Roadmap

## Current State (2026-03-18)

Sol is JS-only. All 4 core packages declare `supported-targets: "js"`:
- `src/` (@sol)
- `src/router/` (@router)
- `src/action/` (@action)
- `src/internal/mars_response/`

71 `extern "js"` FFI calls across the codebase. Mars itself supports native (`mars_js.mbt` / `mars_native.mbt`), but Sol connects to Mars exclusively through JS paths.

### What's already portable (after Json migration)

- `ApiHandler`: `async (PageProps) -> Json` — no `@js.Any`
- `ApiResponse` enum and helpers (`ok`, `bad_request`, etc.) — pure MoonBit
- `SolRoutes` enum and route compilation — pure data
- `RouterConfig` — pure data
- Route helpers (`route`, `api_get`, `wrap`, `with_mw`, `nodes`) — pure MoonBit

## Phase 1: Trait Abstraction for Router FFI

**Goal**: Make `src/router/` compilable on native by abstracting JS FFI behind traits.

### FFI in router/ (5 calls, excluding tests)

| FFI | File | Purpose | Abstraction |
|-----|------|---------|-------------|
| `ffi_parse_int` | helpers.mbt | parseInt | `@strconv.parse_int` (stdlib) |
| `ffi_is_nan` | helpers.mbt | isNaN check | Remove (use Result from parse) |
| `ffi_ensure_mars_to_handler_reschedule_symbol` | sol_routes.mbt | Async scheduler compat | Conditional (js-only, no-op on native) |
| `ffi_create_streaming_response_async` | sol_routes.mbt | SSR streaming | Platform trait |
| `ffi_set_streaming_response` | sol_routes.mbt | Set stream on ctx | Platform trait |

**Quick wins** (no trait needed):
- Replace `ffi_parse_int` / `ffi_is_nan` with `@strconv.parse_int` — pure MoonBit
- Guard `ffi_ensure_mars_to_handler_reschedule_symbol` with `_js.mbt` suffix

**Streaming trait**:
```moonbit
pub trait StreamingPlatform {
  create_streaming_response(async () -> Unit) -> @http.Response
  set_streaming_response(Ctx, stream) -> Unit
}
```

### FFI in mars_response/ (2 calls)

| FFI | Purpose | Abstraction |
|-----|---------|-------------|
| `ffi_json_stringify(@js.Any)` | Legacy `send_json_any` | Already bypassed by `send_json(Json)` |
| `ffi_json_stringify_error(String)` | Error response | Replace with `Json.stringify()` |

Both can be replaced with `Json.stringify()` on native. `send_json_any` is only used by legacy `register_routes` path.

### FFI in action/ (2 calls, client-side only)

| FFI | Purpose | Native? |
|-----|---------|---------|
| `ffi_invoke_action_cb` | Browser-only | N/A (client) |
| `ffi_submit_form_action` | Browser-only | N/A (client) |

Action client FFI is browser-only — not needed for server native. `register_actions` itself is pure.

## Phase 2: Mars Connection Prototype

**Goal**: Prove Sol routes can run on Mars native handler.

### Minimal prototype

```moonbit
// native_main.mbt
fn main {
  let app = @mars.Server::new()
  @sol.register_sol_routes(app, routes(), config=config())
  // Mars native serves via its own native adapter
  @mars_adapters.native_serve(app, port=7777)
}
```

### What Mars native provides
- `Context::json(data: Json)` — works on native
- `Context::text(body, status)` — works on native
- Route registration — pure MoonBit
- Request/response — native HTTP via `@http`

### What needs bridging
- `send_json()` already uses `Json.stringify()` — portable
- `PageProps::from_ctx()` accesses `@mars.Context` — works if Context is native
- `PageProps::body_json()` — needs native body parsing (Mars has this)

### Key insight
The handler execution path (`handle_compiled_api_route`) is:
```
ApiHandler(handler) → handler(props) → Json → send_json(ctx, json) → ctx.text(json.stringify())
```
This entire chain is already `@js.Any`-free. The only blocker is the `supported-targets` declaration and the streaming FFI.

## Phase 3: Package Split (if needed)

Split `@sol` into:
- `sol/core` — RouterConfig, SolRoutes, helpers, create_app (portable)
- `sol/runtime` — run_app, serve, streaming, static serving (JS-only)
- `sol/cli` — generate, build, dev (JS-only, tooling)

This is only needed if Phase 2 reveals structural issues.

## Non-goals

These stay JS-only:
- CLI (`sol generate`, `sol build`, `sol dev`) — Node.js tooling
- SSG/SSR streaming — requires JS stream API
- HMR — WebSocket dev tooling
- Rolldown bundling — JS bundler
- Shiki syntax highlighting — JS library
- Client islands — browser-only

## Execution Order

1. Replace `ffi_parse_int`/`ffi_is_nan` with stdlib (trivial)
2. Move streaming FFI to `_js.mbt` files with no-op `_native.mbt` stubs
3. Replace `ffi_json_stringify_error` with `Json.stringify()`
4. Remove `supported-targets: "js"` from router, action, mars_response
5. Prototype: compile `register_sol_routes` + `handle_compiled_api_route` on native
6. Prototype: connect to Mars native adapter with a minimal example
