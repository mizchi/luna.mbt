# Refactoring TODO for mars Thin Wrapper

## Policy

- `sol` should converge toward being a thin wrapper around `mars`
- `sol`'s responsibilities are limited to "file-based routing assignment", "SSR", and "asset loader"
- `.wasm` mount integration assuming `mbtx` / `wasip2` / `wagi` should be implemented with a clear boundary from `mars`

## Progress

- [x] Run `moon clean`
- [x] Confirm baseline (`moon test --target js src/router`, `moon test --target js src/action`)
- [x] Split `router` by responsibility (`router_config` / `route_params` / `route_registration` / `route_rendering` / `router_hmr`)
- [x] Unify config resolution of `register_routes` / `register_server_routes` into `resolve_router_config`
- [x] Split `runtime` by startup boundary (`runtime_bootstrap` / `runtime_app_export` / `runtime_env_mount`)
- [x] Split `runtime` SSR/Island/Streaming/Static Serving into separate files (`runtime` / `runtime_island` / `runtime_streaming` / `runtime_static_serving`)
- [x] Extract Hot Reload API shared between `sol` / `mars` into a `hot_reload` package (port resolution, script injection, HTML injection)
- [x] Unify API method registration in `sol_routes` into `handle_compiled_api_route` + common registration helpers
- [x] Implement catch-all dynamic parameter handling in `routes/file_router.mbt` (value normalization / empty value handling)
- [x] Formalize `Layout` handling (`register_routes` only does path grouping; composition is in `sol_routes`)
- [x] Formalize URL encoding/decoding conventions for catch-all parameters (cases including `%2F`)
- [x] Reflect the distinction between `register_routes` and `register_sol_routes` in README

## Priority Tasks

- [x] [P1] Unify `Context` param extraction via `mars` public API
  Done: Changed `extract_route_params` to be `Context::param`-based and removed `c.params?.data` dependency

- [x] [P2] Consolidate JSON response sending into a common facade (reduce duplication in `router`/`action`)
  Done: Added `src/internal/mars_response/mars_response.mbt` and used it from `router`/`action`

- [x] [P2] Reduce route registration duplication
  Done: Removed `register_routes_inner` / `register_server_routes_inner` and consolidated into `register_route_tree` + common API registration helpers

- [x] [P2] Reorganize `runtime` startup responsibilities around the `mars` adapter
  Done: Consolidated startup boundaries into `export_runtime_app` / `maybe_start_server` / `with_initialized_fs`

- [x] [P3] Clean up wasm hint/manifest responsibilities
  Done: Added `generate_mars_adapter_hints` to output `.sol/wasm/mars-adapter.hints` using `mars` adapter's `manifest_hint` / `binding_hint`

- [x] [P2] Unify middleware execution to `mars.compose`-based approach
  Done: Changed `middleware.pipeline` to `@mars.compose`-based and removed custom middleware loops in `action` / `sol_routes`

## Next Conceptual Cleanup Candidates

- [x] [P1] Reduce `mars` duplicate APIs in `runtime` (`create_app` / `api` / `api_post` / `get_request_path`)
  Done: Removed duplicate APIs from `src/runtime.mbt` and migrated CLI-generated code / E2E references to `@mars.Server::new` and `app.get/post`
- [x] [P2] Evaluate whether `source_path` dynamic parameter format should support multiple parameters using `k=v&...` format
  Done: Extended `file_router`'s `source_path` generation to primary parameter + additional parameters in `k=v&...` format, and added multi-query restoration tests on the `page_generator` side
- [x] [P3] Consolidate routing specification descriptions between `docs/` and README (reduce duplication)
  Done: Added `docs/routing.md` as a single source of truth and unified `README` and existing routing documents to reference-based approach
- [x] [P2] Standardize 500 error handling during middleware execution
  Done: Added `@middleware.run_or_500` and removed local implementations in `action` / `sol_routes` to unify
- [x] [P2] Unify 500 JSON error response sending into a common helper
  Done: Added `@mars_response.send_internal_error` and unified 500 response branching in `action` / `sol_routes`
- [x] [P3] Gradually reduce `middleware.to_handler` (deprecation)
  Done: Marked `to_handler` as `#deprecated` and started the migration phase for public API reduction

## Additional Items Resolved (2026-02-18)

- [x] [P2] Reduce SSR page shell template processing duplication
  Done: Added `src/internal/page_shell` and unified document/template assembly in `runtime` / `router`
- [x] [P2] Reduce JavaScript object generation duplication
  Done: Added `src/internal/js_any` and unified `json_obj` implementations in `runtime` / `router`
- [x] [P2] Remove `router`-side HMR relay layer
  Done: Removed `src/router/router_hmr.mbt` and unified to `@hot_reload.with_dev_head_script`
- [x] [P3] Introduce HMR message type and fix timestamp overflow
  Done: Added `HmrMessage` and changed `notify_update` timestamp to send as `Double`
- [x] [P3] Fix CLI entry path inconsistency in `just sol`
  Done: Unified `justfile` reference to `_build/js/debug/build/cli/cli.js`
- [x] [P3] Resolve deprecated warnings
  Done: Separated internal implementation of `create_app_then` / `serve` and removed deprecated symbols from internal calls
- [x] [P3] Reduce static css/js serving logic duplication
  Done: Consolidated into `serve_static_text_file`
- [x] [P2] Prepare a step-by-step migration guide for `mars` users
  Done: Added `docs/migrate-from-mars.md` and added a link from README

## Next Candidates (Not Started)

- [x] [P2] Deprecate `get_hmr_script` / `get_hmr_port` in `runtime_env_mount` and migrate to direct `@hot_reload` usage
  Done: Unified `get_port` to `@hot_reload.app_port_from_env` and deprecated `get_hmr_script` / `get_hmr_port` / `set_env` while maintaining backward compatibility
- [x] [P2] Check usage of `text_response` / `js_response` / `static_response` in `runtime_static_serving` and reduce unnecessary public APIs
  Done: Deprecated all 3 APIs and `read_file_sync`, migrated internals to `read_file_text` while maintaining backward compatibility without warnings

## Physical Deletion (breaking)

- [x] [P1] Physically remove deprecated public APIs
  Done: Removed `create_app_then` / `serve` / `get_hmr_script` / `get_hmr_port` / `set_env` / `text_response` / `js_response` / `static_response` / `read_file_sync` / `middleware.to_handler` / `get_port`
- [x] [P1] Remove `@sol.App` / `@sol.Ctx` public type aliases
  Done: Unified to direct usage of `@mars.Server` / `@mars.Context` and updated templates and migration documentation

## Additional Items Resolved (2026-02-19)

- [x] [P3] Minimize debug API responses in k6 benchmark mode to reduce measurement noise
  Done: When `SOL_BENCH_MODE=1`, lighten responses from `/api/middleware-test` and `/api/test/[...path]`

## Next Phase (Not Started)

- [x] [P1] Standardize k6 measurement with "multiple runs + median adoption"
  Done: Added `runs` argument to `just bench-k6` and aggregate medians with `bench/k6/summarize-results.js`

- [x] [P1] Auto-generate diff reports between route profiles and mix profiles
  Done: Added `bench/k6/compare.js` and `just bench-k6-compare` to output `p95/avg/error/rate` diff tables

- [x] [P2] Reflect `SOL_BENCH_MODE` behavior documentation in docs as well
  Done: Added `docs/benchmarking.md` as a single source of truth, referenced from `README.md` / `bench/k6/README.md`

- [x] [P2] Separate bench-purpose APIs from debug-purpose APIs in `examples/sol_app`
  Done: Added `/api/bench/*` endpoints and k6 now uses bench-dedicated APIs

- [x] [P3] Document procedures for isolating variance under high load
  Done: Added CPU pinning, warm-up, re-measurement count (`runs=5`), and variance judgment criteria to `bench/k6/README.md` / `docs/benchmarking.md`

## Review-Driven Improvements (2026-02-19)

- [x] [P2] Integrate docs consistency tests into `just` / `ci`
  Done: Added `test-docs` target and integrated into `ci` / `test-all` and `.github/workflows/check.yaml` (`docs-index` / `docs-chapters` / `docs-ci`)

- [x] [P3] Unify root README Quick Start to scaffold-based approach (`pnpm install` / `pnpm dev`)
  Done: Unified Playground and Quick Start dependency installation / startup commands to `pnpm`-based

- [x] [P2] Verify and unify consistency between GitHub Actions build output path (`_build`) and local development (`target`)
  Done: Unified references in `justfile` / `check.yaml` / `README` / `src/cli` / `src/ssg` / `examples/sol_auth` to `_build` standard; `target` retained only for compatibility cleanup

- [x] [P1] Fix cleanup order for `target -> _build` environment in `sol clean --all` and `sol dev --clean`
  Done: Unified to delete legacy `target` first then `_build`, eliminating the risk of broken symlink remnants

- [x] [P2] Verify `register_sol_routes` streaming output as an actual response
  Done: Added a test in `sol_routes_wbtest` that reads the stream via `Response.text()`, ensuring header/body/footer concatenation

- [x] [P1] Fix inconsistency where `set_header`-applied headers are missing in streaming responses
  Done: `ffi_set_streaming_response` now carries over `ctx.response_headers`, preserving headers like `X-Sol-Cache-Strategy`

- [x] [P2] Lock down streaming/fragment/ISR branching in `register_sol_routes` as a black box
  Done: Added tests via `app.to_handler` to verify full-page uses streaming and fragment/ISR uses non-streaming

- [x] [P1] Absorb `mars.to_handler`'s `reschedule` reference absence via a `sol`-side compatibility layer
  Done: Initialized compatibility symbols in `register_routes` / `register_server_routes` / `register_sol_routes` and removed wbtest-side polyfills

- [x] [P2] Use `root_template` in streaming SSR
  Done: Split template into header/footer at `__LUNA_MAIN__` and applied to streaming; falls back to built-in shell when placeholder is absent

## Type-Safe API Migration (2026-03)

Goal: Replace string-based APIs with type-safe alternatives via `sol generate` code generation.

### A. Immediate (leverages existing `sol generate` infrastructure)

#### A1. `wc_island` -> ComponentRef-based (Low effort)

Current: `wc_island("my-counter", "/static/my_counter.js", styles, state, children)`
Target: `@sol.island(@types.wc_counter(props), children)` — already works via `cref.wc == true`

- [x] `island()` already supports `wc: true` through ComponentRef
- [x] Rename `wc_island` -> `wc_island_raw`, `wc_island_with` -> `wc_island_with_raw`
- [x] Update docs referencing `wc_island`

#### A2. Route params: `get_param("slug")` -> typed accessor (Medium effort)

Current: `props.get_param("slug")` — typo-prone, returns `String?`
Target: typed param struct generated from route path patterns

- [x] Extract param names from route path patterns (`:slug`, `[id]`, `[...path]`, `[[...slug]]`)
- [x] Generate `pub let param_slug : String = "slug"` constants via `sol generate`
- [ ] Design typed params approach (per-route struct vs shared typed map)
- [ ] Keep `get_param(String)` as escape hatch

#### A3. Action IDs -> ActionRef (Medium effort)

Current: `ActionDef::new("create-user", handler)` / `registry.get("create-user")`
Target: `ActionRef` type with generated factory functions (like ComponentRef)

- [x] Define `ActionRef` type with `id`, `base_path` fields and `url()` method
- [x] Add `ActionRef::to_def(handler)` -> `ActionDef`
- [x] Add `ActionRegistry::register_ref(aref, handler)`
- [x] Add `invoke_action_ref(aref, payload, callback)`
- [x] Add `create_action_invoker_ref(aref)`
- [x] Add `ActionFormConfig::from_ref(aref)`
- [x] Extend `sol generate` to collect action definitions and generate factory functions

### B. Medium-term (requires design decisions)

#### B1. Route paths -> typed route builder

Current: `page("/blog/:slug", handler)` — string path patterns
Target: `page(@routes.blog_slug, handler)` — generated route constants

- [x] Generate `pub let route_blog_slug : String = "/blog/:slug"` constants via `sol generate`
- [x] Parse route paths from `routes.mbt` at Step 1.5 (early text scan)
- [ ] Decide if file-based routing should auto-generate typed routes
- [ ] Integrate with A2 (typed params derived from route paths)

#### B2. `invoke_action(url, ...)` -> typed client action

Current: `invoke_action("/_action/create-user", payload, callback)`
Target: `invoke_action_ref(@actions.create_user(), payload, callback)`

- [x] Add `invoke_action_ref` accepting `ActionRef`
- [x] Add `create_action_invoker_ref(ActionRef)`
- [x] Add `ActionFormConfig::from_ref(ActionRef)` constructor
- [x] Generate ActionRef factories via `sol generate`

#### B3. Locale codes -> Locale enum

Current: `build_localized_url(path, "ja", i18n)` — string locale codes
Target: `build_localized_url(path, @locale.Ja, i18n)` — generated enum

- [x] Generate `pub enum Locale { En; Ja }` with `code()` and `label()` methods via `sol generate`
- [ ] Keep String overloads as `_raw` suffix

### C. Low priority (intentionally string-based)

- `island_raw()` / `island_with_raw()` — low-level escape hatch
- CORS methods/headers — standard HTTP patterns
- File path utilities — build tool internals
- `IslandConfig` builder — superseded by ComponentRef

### Implementation Order

1. A1 (wc_island rename) — minimal, consistent with island refactor
2. A2 (typed route params) — high user impact
3. A3 (ActionRef) — follows ComponentRef pattern
4. B1-B3 — after A items validated

## `/__sol__/` Asset Serving & IO Abstraction (2026-03)

### Completed

- [x] Serve framework built-in assets (loader.js, wc-loader.js, sol-nav.js, lib.js) at `/__sol__/*` routes
- [x] Pre-write assets to `.sol/prod/__sol__/` via `sol generate`
- [x] In prod mode, serve directly from `.sol/prod/__sol__/`; in dev mode, dynamically resolve candidate paths
- [x] Unify `RouterConfig::default()` default URL to `/__sol__/loader.js`
- [x] Remove loader mappings from `StaticFileConfig`
- [x] Migrate all `/static/loader.js` references in examples / templates / tests to `/__sol__/`
- [x] Remove runtime asset files from examples' `static/`

### Completed: Memory Cache for Prod Asset Serving

- [x] [P2] Lazily memory-cache assets in prod mode (load on first request, then map lookup only)

### TODO: Consider Removing Unnecessary APIs

- [ ] [P3] `StaticFileConfig::dev()` — unnecessary since `serve_static` auto-detects via `is_dev_mode()`
- [ ] [P3] `StaticFileConfig::mappings` — default empty after `/__sol__/` introduction. Decide whether to keep as a user extension point

### TODO: IO Abstraction — Leveraging `mizchi/x` Package

Currently `ffi_read_file_sync` in `runtime_static_serving.mbt` and `ffi_read_file` in `isr/handler.mbt`
each call Node.js APIs directly via `extern "js"`, which does not work on native targets.

`mizchi/x` (v0.1.5) provides the following async FS APIs for both js and native:
- `@x_fs.read_file(path)` -> `&@io.Data`
- `@x_fs.write_file(path, data)` -> `Unit`
- `@x_fs.exists(path)` -> `Bool`
- `@x_fs.mkdir(path, recursive?)` -> `Unit`

#### Steps

- [x] [P1] Replace `ffi_read_file` in `isr/handler.mbt` with `@x_fs.read_file`
- [x] [P2] Replace `ffi_read_file_sync` in `runtime_static_serving.mbt` with `@x_fs.read_file`
- [ ] [P3] Consider unifying `@fs.read_file_as_string` in `cli/generate_utils.mbt` to `@x_fs`
  - Since CLI is js-target only, the benefit of unification is limited

## ISR + Cloudflare Async Stale-While-Revalidate (2026-03)

### Background

Cloudflare rolled out **async stale-while-revalidate** to all zones on 2026-02-26.
Previously, the first request after cache expiration would block waiting for the origin response.
With the new behavior, stale content is returned immediately and revalidation happens asynchronously in the background.

### Relationship with sol ISR

sol's ISR (`src/isr/`) already implements the SWR pattern at the **application layer**:
- `CacheStatus::Stale` -> returns stale content while setting `needs_revalidation=true`
- `ISRCache::schedule_revalidation` -> background regeneration via Workers `waitUntil`
- Backend switching between `MemoryCache` (dev/standalone) / `KVCache` (Workers KV)

Cloudflare's async SWR does the equivalent at the **CDN edge layer**. This results in a double SWR.

### Considerations

- [x] [P1] Design coordination between CDN-layer SWR and app-layer ISR
  - `CDNCacheStrategy` enum: `CdnSwr(grace)` / `Hybrid(cdn_ttl, cdn_grace)` / `AppIsr`
  - Each strategy generates `Cache-Control` header values via `cache_control(revalidate)`

- [x] [P2] Add `cache_strategy` option to `RouterConfig`
  - `RouterConfig::with_cache_strategy(@isr.CDNCacheStrategy)` builder
  - Automatically attach `Cache-Control` and `X-Sol-CDN-Cache` headers to ISR page responses
  - Per-route `revalidate` values are mapped to `s-maxage`

- [x] [P2] Make ISR cache status diagnosable via `X-Sol-ISR-Status` header
  - Returns `HIT` / `STALE` / `MISS` (corresponding to ISR internal `CacheStatus`)
  - Enables identifying which layer of the two-tier cache served the response by comparing with CDN-layer `cf-cache-status`

- [ ] [P3] Mechanism to set different `s-maxage` per `revalidate` value in CDN-layer SWR
  - Reflect per-page `revalidate` values from the ISR manifest into response headers
  - Middleware to dynamically set `Cache-Control` per route

### References

- Cloudflare changelog: https://developers.cloudflare.com/changelog/post/2026-02-26-async-stale-while-revalidate/
- sol ISR implementation: `src/isr/` (types.mbt, cache.mbt, handler.mbt, middleware.mbt)
- ISR trait: `ISRCache` (get/put/delete/schedule_revalidation)
