---
name: sol-bootstrap
description: Use when running `sol new` for the first time, when `sol <subcommand>` fails with `failed to resolve path mizchi/sol/cmd/sol_js` / `Run this command inside a MoonBit project that depends on mizchi/sol.`, or when moving from `sol dev` to `sol build` / `sol serve` for the first time. Covers (a) the bootstrap rules — `sol new <name> --user <ns>` works in an empty directory as of sol 0.22.2, but `--cloudflare` / `--doc` / `--dev` still need a host moon project, and every non-new subcommand needs `.mooncakes/mizchi/sol/` locally (= `moon install` after `sol new`) — (b) the sol 0.22.x scaffold layout (`app/server/routes.mbt` holds routes + page handlers; `app/layout/` is a separate package; `/` and `/about` are pre-registered) and (c) the production flow gotchas (`sol build` writes to two directories, `sol serve` does NOT rebuild, dev & prod both default to :7777).
---

# sol-bootstrap

## Purpose

The sol native CLI (`$MOON_HOME/bin/sol`) is a thin launcher. Most subcommands (`dev` / `build` / `serve` / `generate` / `doctor` / ...) delegate to `moon run --target js mizchi/sol/cmd/sol_js`, which only resolves inside a moon project with `.mooncakes/mizchi/sol/` populated. Two friction points remain even on sol 0.22.2:

1. **`sol new` without flags** (the common path) is now handled natively in the launcher and works in an empty directory. **However**, `sol new --cloudflare` / `--doc` / `--dev` still go through the JS delegate, so they need a host moon project. If you hit `failed to resolve path mizchi/sol/cmd/sol_js` from a flagged variant of `sol new`, that is why.
2. Right after `sol new myapp --user <ns>` succeeds, the generated `myapp/` has **no `.mooncakes/`**. Running `sol dev` immediately fails with `failed to resolve path mizchi/sol/cmd/sol_js`. The `pnpm install` step alone does **not** fetch MoonBit deps; `moon install` is the missing step (`sol new` now prints this in its Next steps).

The native-new entrypoint lives in `sol/src/cmd/sol/main.mbt::try_native_new` and the underlying templates moved to `sol/src/scaffold_templates/`. The delegate fallback (`delegate_to_project_js_cli`) is still where every other subcommand goes through; it branches its error message on `moon.mod.json` / `.mooncakes/mizchi/sol` presence so the diagnostic points at the right next action.

## When to use

- Starting a brand-new sol project (no existing moon project in CWD)
- `sol <anything>` errors with `failed to resolve path mizchi/sol/cmd/sol_js` even though the binary is installed and on PATH
- Documenting / explaining sol's bootstrap flow to another agent or contributor
- Reviewing whether the gap is still present after a sol release (the launcher logic may change)

## Golden path (from zero to a working 2-route SSR app)

```sh
# 0) prerequisites: moon (MoonBit), pnpm, node v24+

# 1) install the sol native binary into $MOON_HOME/bin
moon install mizchi/sol/cmd/sol

# 2) scaffold directly in an empty dir — `sol new` (no flags) is native.
#    Namespace must be 5-39 chars (moon constraint, e.g. `myorg`, not `me`).
mkdir -p /tmp/sol-myapp && cd /tmp/sol-myapp
sol new myapp --user myorg
cd myapp

# 3) install BOTH dep trees. pnpm covers npm (hono, etc.), moon covers MoonBit.
pnpm install
moon update && moon install            # CRITICAL — `moon update` refreshes the
                                       # registry index so freshly published
                                       # mooncake versions in the scaffolded
                                       # moon.mod.json resolve; without the
                                       # pair `sol dev` fails to resolve
                                       # `mizchi/sol/cmd/sol_js`.

# 4) start dev server on :7777
sol dev                                # ready marker: "Server running at http://localhost:7777"
```

### When `sol new` still needs a host moon project

`--cloudflare` / `--doc` / `--dev` go through the JS delegate, so they require `.mooncakes/mizchi/sol/` resolvable from the cwd. Use the host-project pattern in that case:

```sh
mkdir -p /tmp/sol-host && cd /tmp/sol-host
moon new hostproject --user myorg
cd hostproject
moon add mizchi/sol                    # fetches .mooncakes/mizchi/sol
sol new myapp --user myorg --cloudflare
```

The HMR WebSocket binds to `:7877` (used by the loader, not for your curl). After step 5, the scaffolded routes already work:

```sh
curl -s http://localhost:7777/             # → SSR HTML (demo home with counter/api_tools)
curl -s http://localhost:7777/about        # → SSR HTML (demo about)
curl -s http://localhost:7777/api/health   # → {"status":"ok"}
```

When scripting startup (CI / Playwright), grep stdout for `Server running at http://localhost:7777` as the ready marker rather than polling the port.

## Generated project layout (sol 0.22.x)

`sol new myapp --user <ns>` produces:

| Path | Role |
|------|------|
| `app/server/main.mbt`    | `async fn main` — entrypoint for the SSR server |
| `app/server/routes.mbt`  | Route registrations **and page handlers in the same file** (no separate `pages.mbt`) |
| `app/server/alias.mbt`   | `using @server_dom { div, span, h1, p, text, button, ... }` — add tags here before referencing them in handlers |
| `app/server/moon.pkg`    | Package manifest for the server-side mbt sources |
| `app/layout/layout.mbt`  | Shared HTML layout — **separate package** under `app/layout/`, not `app/server/layout.mbt` |
| `app/layout/alias.mbt`   | DOM tag aliases for the layout package |
| `app/client/counter.mbt`, `app/client/api_tools.mbt` | Island components scaffolded by default (delete or keep) |
| `app/__gen__/`           | Generated by `sol generate` — never edit; `client/` and `server/` are git-ignored, `types/` is committed for first-build |

Two routes (`/` and `/about`) and one API (`/api/health`) are already registered in `routes.mbt` at scaffold time. The home handler is a heavy demo that uses both island components.

## Adapting the scaffold to a minimal 2-page app

Use case: replace the demo with a custom `/` and `/about` (the typical first edit).

The Routes API used by `sol new` is the `@sol.SolRoutes` family, not the lower-level `@router.page`. The scaffolded `routes.mbt` shape is:

```moonbit
pub fn routes() -> Array[@sol.SolRoutes] {
  [
    @sol.wrap("", @layout.root_layout, [
      @sol.route("/", home, title="Home"),
      @sol.route("/about", about, title="About"),
    ]),
    @sol.api_get("/api/health", api_health),
  ]
}

async fn home(_props : @sol.PageProps) -> @server_dom.ServerNode { ... }
async fn about(_props : @sol.PageProps) -> @server_dom.ServerNode { ... }
```

Minimum diff:

1. Rewrite the `home` body in `app/server/routes.mbt` with `@sol.nodes([...])` returning your DOM. Drop every `@server_dom.client(...)` call so the counter / api_tools islands disappear from `/`.
2. Rewrite the `about` body in the same file. The `/about` route is **already registered** at scaffold time — no need to add the registration.
3. In `app/server/alias.mbt`, extend `using @server_dom { ... }` with any tags you newly reference (e.g. `ul`, `li`). Tags you stop using produce harmless `unused_value` warnings — remove them from `alias.mbt` to reach 0 warnings.
4. `app/client/counter.mbt` and `app/client/api_tools.mbt` can stay as orphans; they only matter if `home` calls them. Delete the files (and their lines in `app/client/moon.pkg`) for a true minimum project.
5. `sol dev` runs `sol generate` internally — no explicit regenerate needed. If HMR misses an edit (sometimes happens for the first edit made within a second of startup), kill and restart `sol dev`. `sol generate --mode dev` is the manual fallback.

`@router.page` / `@router.register_routes` exist for embedding sol into a host Worker — see `sol/docs/routing.md` for the API selection matrix. New apps stay on `@sol.SolRoutes` / `@sol.route` because the scaffold uses them.

## Common failure modes

| Symptom | Root cause | Fix |
|---------|------------|-----|
| `sol new <name> --cloudflare` in `/tmp/empty/` → `Run this command inside a MoonBit project that depends on mizchi/sol.` | Flagged variants of `sol new` still go through the JS delegate, which needs `.mooncakes/mizchi/sol/` | Create a host moon project (see "When `sol new` still needs a host moon project" above) |
| `sol new <name>` → `Error: --user option is required` | `--user` is mandatory; `sol --help` now annotates this on the `new` row | Pass `--user <namespace>` (5-39 chars) |
| Right after `sol new`, `sol dev` → `failed to resolve path mizchi/sol/cmd/sol_js` | Generated project has no `.mooncakes/` yet — `pnpm install` doesn't fetch MoonBit deps | `moon update && moon install` in the project dir, then retry. `moon install` alone fails when the registry index hasn't seen the freshly published mooncake versions; `moon update` refreshes the index first. The `sol new` Next steps now print this pair explicitly. |
| `moon new bootstrap --user me` → `Username must be between 5 and 39 characters long` | Moon's username validator, not a sol issue | Use a ≥5-char namespace (e.g. `myorg`, `dogfood`) |
| Route edit applied but curl returns the old page | Earlier versions of the HMR watcher only listened for `"change"` events and missed atomic-save / `rename` writers. Fixed (watcher now also accepts `"rename"` and re-verifies existence). | If still observed, kill and restart `sol dev`; report which editor / write pattern was used. |
| Want to bypass the launcher entirely | Delegate fallback uses module ref form that moon's `run` cannot resolve as a path | Run `moon run --target js .mooncakes/mizchi/sol/src/cmd/sol_js -- <subcommand>` directly. Useful when binary path resolution fails for unknown reasons. |

## Production build & serve

`sol dev` is for development only. The production path is `sol build` (one-shot bundling) followed by `sol serve` (Node HTTP server reading the build output).

### Output layout

`sol build` writes to **two** directories that together form the production artifact:

| Path | Contents | Purpose |
|------|----------|---------|
| `.sol/prod/server/main.js` | Tiny loader (≈KB) | Entry that `sol serve` boots — re-exports the bundle below |
| `.sol/prod/static/<island>.js` | Minified island bundles (~5× smaller than dev) | Served as client modules |
| `.sol/prod/__sol__/{loader,lib,sol-nav,wc-loader}.js` | Sol runtime helpers | Hydration / island loader / CSR navigation |
| `.sol/prod/manifest.json` | Island registry | Used by `sol serve` and the loader |
| `_build/js/release/build/server/server.js` | The **real** ~1.6 MB SSR bundle | What `.sol/prod/server/main.js` ends up importing |

Trap: `_build/` looks like a MoonBit intermediate directory but in release mode is **part of the deployable**. A naive `rsync .sol/prod/ <host>` ships a broken bundle. Either ship both `.sol/prod/` and `_build/js/release/`, or use the deploy adapter (Cloudflare path in `sol-cloudflare-deploy`).

### Commands

```sh
sol build                          # → builds the full production artifact
sol build --skip-minify            # iterate faster (minify is the slowest step)
sol build --skip-bundle            # rebuild SSR without re-bundling islands
sol build --skip-generate          # build without regenerating __gen__
sol build --clean                  # wipe .sol/ and _build/ first
sol serve --port 8888              # → http://localhost:8888 (dev's 7777 is busy if dev is running)
```

`sol serve` does **not** rebuild on source changes. After editing `.mbt` files, re-run `sol build && sol serve`. There is no `--watch` flag.

### dev vs prod cheat sheet

| Aspect | `sol dev` | `sol serve` |
|--------|-----------|-------------|
| Prerequisite | none beyond `moon install` | `sol build` must succeed first |
| Default port | 7777 (HTTP) + 7877 (HMR WS) | 7777 |
| Port flag | (not exposed in `--help`) | `-p, --port <port>` |
| Output | `.sol/dev/` (~312 KB) | `.sol/prod/` (~128 KB) + `_build/js/release/build/` (~1.6 MB SSR bundle) |
| Bundle minified | no | yes (5× smaller per island) |
| HMR | enabled, WS on :7877 | disabled (fixed in 0.22.2: `SOL_DEV` is no longer set when mode = `"prod"`, so prod HTML no longer embeds the dev HMR `<script>`) |
| File watch | yes (`Watching for .mbt file changes...`); accepts both `"change"` and `"rename"` events since 0.22.2 — atomic-save editors are no longer dropped | no |
| Cold-start time | ~15s (generate + moon build + rolldown) | ~3s after `sol build` (4–5s) |
| Ready marker | `Server running at http://localhost:7777` | `Server running at http://localhost:<port>` |

### Known production gotchas (sol 0.22.2+)

1. **`sol build` exits 0 even when generate is stale.** By default `sol build` runs `sol generate --mode prod` first, so this only matters when `--skip-generate` is passed — in that case 0.22.2 prints a yellow warning. `sol build --clean` is the safe option when in doubt.
2. **`_build/js/release/` is part of the deployable.** `.sol/prod/server/main.js` re-exports `_build/js/release/build/server/server.js` (~1.6 MB). A naive `rsync .sol/prod/ <host>` ships a broken bundle. Use the platform adapter (`sol-cloudflare-deploy` skill) or ship both directories.

## Source of truth

- Launcher: `sol/src/cmd/sol/main.mbt` — `try_native_new` handles `sol new` natively (flag-less form), `delegate_to_project_js_cli` handles every other subcommand with branched diagnostics
- Native-shared templates: `sol/src/scaffold_templates/` (`supported_targets = "js + native"`, zero deps, pure string fns)
- JS-side `sol new` wrapper: `sol/src/cli/new.mbt` (still owns `--cloudflare` / `--doc` / `--dev`)
- JS-side templates re-export + cloudflare/doc extras: `sol/src/cli/templates.mbt`
- `sol build` pipeline: `sol/src/cli/build.mbt` (rolldown invocation + manifest emission)
- `sol serve` entry: `sol/src/cli/serve.mbt` (`--port` default 7777, reuses `run_server(cwd, port, "prod")`)
- Reference app matching the current scaffold: `sol/examples/sol_todo/app/{server,layout}/`
- Routing API reference: `sol/docs/routing.md` — `@sol.SolRoutes` (scaffold default) vs `@router.register_routes` (host-worker embedding)
- Quickstart: `sol/docs/quickstart.md`
- Cloudflare deploy follow-up: `sol-cloudflare-deploy` skill (in this repo's `.claude/skills/`)
