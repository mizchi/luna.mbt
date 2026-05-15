# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## 0.22.1 (2026-05-15)

- Fix `sol --version` and the installable native shim to report the manifest
  version.
- Update `sol new` templates to depend on `mizchi/sol` 0.22.1,
  `mizchi/sol_adapter_{node,cloudflare}` 0.22.1, and `mizchi/luna` 0.22.0.

## 0.22.0 (2026-05-15)

### Added

- Add Sol contract manifest generation for routes, params, props, actions, and
  generated server/frontend glue.
- Emit TypeScript contract declarations from the generated Sol manifest so
  frontend code can consume the same route/action contracts as MoonBit server
  code.
- Add typed action request decoding, typed JSON action results, and typed
  invocation helpers.
- Add generated `TypedActionKey[Req, Res]` action identifiers to replace the
  unreleased string-based `ActionRef` API.

### Changed

- Strengthen generated route/action contracts and dogfood the user-managed
  Sol build path in the examples.
- Keep raw action payloads, untyped action invocation APIs, and internal
  builder/HMR/Rolldown escape hatches behind implementation boundaries.
- Tighten generated package/interface metadata and explicit imports to keep
  `moon check --target js` warning-free.

### Fixed

- Normalize colon route parameters in generated API helpers.
- Preserve static route TypeScript references without stringly route drift.
- Keep repeated island references unique during SSR rendering.
- Declare the Cloudflare adapter in generated Cloudflare templates instead of
  the Node adapter.

## 0.21.1 (2026-05-14)

- Fix generated/example Cloudflare projects by declaring
  `mizchi/sol_adapter_cloudflare` instead of the Node adapter.
- Update `sol new` templates and `sol --version` to the 0.21 release line.

## 0.21.0 (2026-05-14)

- Add route-scoped asset attachment APIs and Sol-generated asset manifests.
- Split Cloudflare and Node-specific runtime helpers into
  `mizchi/sol_adapter_cloudflare` and `mizchi/sol_adapter_node` so adapter
  behavior stays outside the Sol core package.
- Add Cloudflare starter generation and Wrangler-backed development flow.
- Add typed action state and API client helper generation.
- Add `sol doctor` diagnostics for generated apps and common config problems.

## 0.20.2 (2026-05-13)

- Fix `moon install mizchi/sol/cmd/sol` by making the installable entry a
  native shim and moving the JS CLI dispatcher to `mizchi/sol/cmd/sol_js`.
- Remove runtime npm-only imports from the Sol CLI path so Mooncake installs do
  not depend on npm `node_modules`.

## 0.20.1 (2026-05-10)

- Chore: workspace-wide version bump to keep all four mooncakes (luna,
  luna_components, sol, astra) on the same minor line. No API changes
  — sol's `app/server/moon.pkg.json` references for the styled
  components now resolve through `mizchi/luna_components` (split from
  `mizchi/luna/x/components` in the matching luna 0.20.1 release).

## 0.16.0 (2026-05-01)

### Breaking Changes

- **SSG removed; use `mizchi/astra` instead.**
  Static-site generation moved to a dedicated middleware package
  ([`mizchi/astra`](https://mooncakes.io/docs/mizchi/astra/)) that mounts
  on any Mars `Server`. Migration:

  ```diff
  - sol build --mode ssg
  + astra build

  - sol dev --mode ssg
  + astra dev
  ```

  ```diff
  // moon.mod.json
  {
    "deps": {
  -    "mizchi/sol": "0.15.3"
  +    "mizchi/sol": "0.16.0",
  +    "mizchi/astra": "0.1.0"
    }
  }
  ```

  See `astra/README.md` for usage and `astra/examples/sol_docs/` for a
  working starter.

- **`sol new --doc` removed.**
  Document-site scaffolding now lives in astra's example surface; copy
  `astra/examples/sol_docs/` as a template.

- **CLI no-op flags removed: `--parallel`, `--workers`, `--force` on `sol build`.**
  These drove the SSG cache; they are not relevant to SSR builds.

- **`sol lint` and `sol ssg` subcommands removed.**
  Both now exit non-zero with a forwarder pointing at the astra CLI.

- **Runtime asset path moved.**
  `sol/src/ssg/assets/scripts/` is gone. Sol's runtime resolves
  loader/wc-loader/sol-nav/lib via `.mooncakes/mizchi/astra/src/assets/scripts/`.

- **Dropped deps**: `mizchi/markdown`, `mizchi/jsonschema`,
  `mizchi/process_pool`, `mizchi/syntree` (only used by the moved SSG).

### Dev-only deps

`mizchi/astra` is currently declared as a `{ "path": "../astra" }` dep
in `sol/moon.mod.json` because astra is not yet published to mooncakes.
**Before publishing sol to mooncakes**, flip it to a registry version:

```diff
  "deps": {
-    "mizchi/astra": { "path": "../astra" },
+    "mizchi/astra": "0.1.0",
  }
```

The same applies to `mizchi/sol` in `astra/moon.mod.json` (path dep
during co-development; flip to registry once both publish).

## 0.13.0 (2026-03-19)

### Breaking Changes

- **`ApiHandler` return type: `@js.Any` → `Json`**
  API handlers now return MoonBit's built-in `Json` type instead of `@js.Any`.
  This enables wasm/native compatibility and eliminates `@core.any()` wrappers.

  ```moonbit
  // Before
  async fn handler(_props : @router.PageProps) -> @core.Any {
    @sol.json_obj([("status", @core.any("ok"))])
  }

  // After (typed response — recommended)
  priv struct HealthResponse { status : String } derive(ToJson)
  async fn handler(_props : @sol.PageProps) -> HealthResponse {
    { status: "ok" }
  }
  ```

- **`api_get` / `api_post` / etc. are now generic `[T : ToJson]`**
  Handlers can return any type implementing `ToJson`, not just `Json`.
  Existing `-> Json` handlers continue to work (`Json : ToJson`).

- **`@sol` re-exports replace direct `@router` / `@action` imports**
  Use `@sol.route()`, `@sol.api_get()`, `@sol.ok()`, `@sol.PageProps` etc.
  Direct `@router` import still works but is no longer needed in most cases.

- **`shiki` (JS) replaced with `syntree` (pure MoonBit)**
  Syntax highlighting now uses `mizchi/syntree` (zero deps, native compatible).
  `create_default_highlighter()` is now synchronous (no `.wait()`).
  17 languages supported (was ~30 with shiki).

- **`supported-targets` syntax: `["js"]` → `"js"`**

### New Features

- **`@sol.create_app()` facade** — one-call app creation
- **`PageProps::body_as[T : FromJson]()`** — typed request body extraction
- **Island Props round-trip test auto-generation** via `sol generate`
- **Island hydration Props validation** via `@json.from_json` (replaces `@js.identity`)
- **User-managed server entry point** (`app/server/main.mbt`)
- **Native Sol CLI** (`src/cmd/sol/`) — `sol new`, `sol clean`, `sol build`
- **Portable streaming SSR** via `luna/core/stream_render`
- **`api_put` / `api_delete` / `api_patch`** shortcut helpers

### Security

- HTML-escape `<title>` in all render paths (XSS prevention)
- Hide internal error details from clients
- try/catch in ReadableStream for stream error handling

### Dependencies

- `mizchi/luna`: 0.17.0 → 0.18.0
- `mizchi/mars`: 0.3.9 → 0.3.10 (fixes query string routing)
- `mizchi/syntree`: 0.2.3 (new — replaces shiki)

### Migration Guide

1. Update `moon.mod.json`: `"mizchi/sol": "0.13.0"`, `"mizchi/luna": "0.18.0"`, `"mizchi/mars": "0.3.10"`, add `"moonbitlang/async": "0.16.6"`
2. API handlers: `-> @core.Any` → `-> Json` (or typed struct with `derive(ToJson)`)
3. Replace `@core.any(x)` with `x.to_json()`
4. Replace `@sol.json_obj([...])` with `@sol.ok([...]).to_json()` or typed struct
5. Replace `@router.*` with `@sol.*` (optional)
6. Fix `supported-targets`: `["js"]` → `"js"`

### Added

- Add hydration module URL origin policy in `loader.js` with `window.__LUNA_ALLOWED_HOSTS__` and `window.__LUNA_SET_ALLOWED_HOSTS__`
- Add asset sync workflows and checks: `scripts/sync-example-static-assets.mjs`, `scripts/sync-luna-loader-assets.mjs`, `just sync-*` tasks, and E2E sync tests
- Add type-safe `island(cref, children)` and `island_with(cref, render)` that accept `ComponentRef[T]` instead of raw strings
- Add `ActionRef` type for type-safe action references with `url()`, `to_def()`, `register_ref()`, `invoke_action_ref()`, `ActionFormConfig::from_ref()`

### Changed

- Unify loader runtime asset sources under `src/ssg/assets/scripts/*` and keep `examples/*/static/*` synchronized from canonical sources
- Update example package scripts (`predev` / `prebuild` / `preserve` / `pretest`) to auto-sync runtime static assets
- **Breaking:** Rename string-based `island()` / `island_with()` to `island_raw()` / `island_with_raw()` — use `ComponentRef`-based `island()` for type safety
- **Breaking:** Rename `wc_island()` / `wc_island_with()` to `wc_island_raw()` / `wc_island_with_raw()` — use `island()` with WC-prefixed ComponentRef instead

### Fixed

- Preserve API response headers set in handlers while keeping JSON `Content-Type` and `X-Content-Type-Options: nosniff` defaults

## [0.8.0] - 2026-02-19

### Added

- Add blackbox tests for `register_sol_routes` streaming/fragment/ISR branching via `app.to_handler`
- Add `render_streaming_template_parts` to apply `root_template` in streaming SSR path

### Changed

- Merge streaming SSR and route rendering behavior around `root_template`
- Improve route/middleware/runtime cleanup and duplication reduction toward thin `mars` wrapper
- Expand docs coverage and consistency checks (`test-docs`, benchmark docs, routing/docs references)

### Fixed

- Preserve `ctx.set_header` headers in streaming responses (`X-Sol-Cache-Strategy` etc.)
- Harden cleanup order for `target -> _build` transition
- Align generated/scaffolded project templates with latest Sol/Mars setup

## [0.7.1] - 2026-02-19

### Changed

- Upgrade `mizchi/mars` dependency to `0.3.9`
- Align example modules to `mizchi/mars` `0.3.9`

## [0.2.0] - 2026-01-13

### Added

- **ISR (Incremental Static Regeneration)**: Add ISR cache system with Cloudflare KV support
- **Cloudflare Workers**: Add deployment support with KV-based ISR
- **TypeScript Support**: Add JSX runtime for TypeScript SSR (`@luna_ui/luna` package)
- **sol_tsx example**: Pure TypeScript mode example project
- **sol_blog example**: Blog with ISR caching demonstration
- **Benchmark suite**: Add Sol vs Hono comparison and k6 load testing scripts
- **sol CLI npm bin**: Install sol CLI via npm package

### Changed

- **luna 0.5.2**: Upgrade luna dependency with updated import paths (`mizchi/luna/*`)
- **pnpm monorepo**: Convert to pnpm workspace with package references
- **CI**: Migrate from illusory0x0/setup-moonbit to hustcer/setup-moonbit@v1
- **Templates**: Align with `app/server` structure and `sol.config.ts`

### Fixed

- WC (Web Component) hydration after CSR navigation
- Dev mode cache control headers
- CLI paths in example projects
- E2E test stability improvements

## [0.1.0] - Initial Release

- SSR/SSG Framework for Luna UI
- Island Architecture with partial hydration
- File-based routing
- Markdown/MDX support
- CSS Utilities extraction
