---
title: Extract astra (SSG middleware) from sol, monorepo with luna
date: 2026-05-01
status: draft
---

# Extract astra: a mountable Mars SSG middleware

## Goal

Cleanly separate the static-site generator (today living inside `mizchi/sol` as
`src/ssg/`) into an independent package, `mizchi/astra`, that is structured as
a Mars middleware. `astra` is mounted on a Mars app like any other middleware
and can also be statically dumped via its own CLI.

After the split:

- `mizchi/sol` contains only the SSR / Island / file-based-routing framework.
  It has no knowledge of, and no dependency on, `astra`.
- `mizchi/astra` is a self-contained SSG package consumable by any Mars app.
- Both modules, plus `mizchi/luna`, live in a single monorepo backed by
  `moon.work`.

## Background

`astra` previously existed as a standalone, mountable Mars middleware. During
later refactors, the SSG was folded into `sol` and now sits at
`sol.mbt/src/ssg/` alongside the SSR runtime. Concretely:

- `sol`'s CLI (`src/cli/`) imports `@ssg`, `@ssg_gen`, `@ssg_routes`,
  `@ssg_cache`, `@tree`, `@assets` and runs the generator inline.
- `src/cli/dev.mbt` carries an `--mode ssg` branch and a hybrid-config
  detector (`has_ssg_config`, `find_ssg_config_file`, `parse_ssg_config`).
- `src/runtime_static_serving.mbt` hard-codes lookup paths into
  `src/ssg/assets/scripts/*` so the SSR runtime can serve SSG-owned assets.

These couplings are the cleanup target. `moon.work` landing in MoonBit makes
the monorepo route viable, so we also pull `astra` and `sol` into the
`luna.mbt` repository instead of keeping three separate repos.

## Decisions

| Topic              | Decision                                                                                              |
|--------------------|-------------------------------------------------------------------------------------------------------|
| SSG shape          | Dynamic Mars middleware: requests are converted to HTML on demand at request time.                    |
| Dependency direction | Fully independent: `astra → {mars, markdown, luna}`. No `astra ↔ sol` edge in either direction.     |
| Physical layout    | Single monorepo rooted at `luna.mbt` with `moon.work`; members: `luna/`, `sol/`, `astra/`.            |
| CLI                | `astra` ships its own CLI (`astra dev`, `astra build`). `sol` CLI drops all SSG paths.                |
| Build strategy     | `astra build` boots the middleware in-process, lists URLs from the document tree, crawls and dumps.   |
| Middleware scope   | GET only: pages + static assets. Excludes POST / Server Actions / HMR / auth.                         |

## Target architecture

```
luna.mbt/                       (monorepo root, current path: ~/ghq/github.com/mizchi/luna.mbt)
├── moon.work                   (new — workspace manifest)
├── luna/                       (existing UI primitive package)
├── sol/                        (existing SSR framework, with src/ssg removed)
└── astra/                      (new package, code migrated from sol/src/ssg/)
    ├── moon.mod.json           (name: mizchi/astra)
    └── src/
        ├── middleware/         (Mars middleware entry — what consumers mount)
        ├── render/             (page render core: path → HTML)
        ├── tree/               (document tree, sidebar, nav resolution)
        ├── mdx/                (MDX parser + JSX validator)
        ├── assets/             (CSS, scripts, themes — ex sol/src/ssg/assets)
        ├── cache/              (chunk cache, hash utilities)
        ├── components/         (shared UI fragments: Header, Footer, TOC)
        ├── themes/             (theme system)
        ├── i18n/               (multi-language config)
        ├── config/             (astra.config / sol.config compatibility loader)
        └── cli/                (astra dev, astra build entry points)
```

Repository naming note: the repo name `luna.mbt` understates the new scope.
Renaming the GitHub repository is **out of scope** for this spec because it
breaks every downstream `git`/`mooncake` reference. Instead the README will
declare the repo as a monorepo holding `luna`, `sol`, and `astra`.

## Dependency graph

```
mars ←──── sol (SSR framework, mars wrapper)
mars ←──── astra (SSG middleware)
luna ←──── sol
luna ←──── astra
markdown ← astra
```

There is no edge between `sol` and `astra`. A user who wants both mounts
`astra` themselves on a Mars app that may or may not also use `sol`.

## Public API sketch

### Mounting astra

```moonbit
// In a Mars app.
let mw : @astra.Middleware = @astra.create({
  docs_dir: "docs",
  base: "/docs",
  i18n: ...,
  theme: ...,
})
app.use("/docs", mw.handler())
```

`@astra.Middleware` is a wrapper around `@mars.Handler`. Mounting it under a
prefix gives a fully working documentation site at request time.

### Building static output

```moonbit
// In `astra build` (CLI).
let mw = @astra.create(config)
let urls : Array[String] = mw.list_urls()       // GET targets the middleware claims
for url in urls {
  let req = @mars.Request::get(url)
  let res = mw.handle(req)                      // pure GET, no side effects
  write_to_disk(output_dir + url, res.body())
}
```

`list_urls()` is the explicit contract that lets the build crawler enumerate
generated URLs without scanning the file system itself. The middleware owns
both the URL surface and the rendering logic; the CLI only drives it.

### CLI surface

```
astra dev      [--port 3000]      (boots the middleware behind a Mars dev server)
astra build    [--out dist]       (crawls list_urls() and dumps to disk)
astra new      <name>             (scaffolds an astra-only project — optional, low priority)
```

The dev mode may layer additional middleware (HMR / live-reload) on top, but
the SSG core middleware is unchanged between dev and build.

## Internal structure of astra

- **render core** (`src/render/`) — pure function `(path, ctx) → Html`.
  Knows how to convert a Markdown / MDX document plus theme + components to
  an HTML response. No I/O beyond reading source files via the configured FS.
- **document tree** (`src/tree/`) — builds the hierarchy of documents from
  `docs_dir`. Source of truth for `list_urls()`, sidebar, nav, OGP metadata.
- **assets pipeline** (`src/assets/`) — serves CSS, theme JS, hydration
  loader scripts. Owns paths today hard-coded inside
  `sol/src/runtime_static_serving.mbt`.
- **cache** (`src/cache/`) — disk cache keyed by content hash. Used by the
  render core to avoid recomputing identical pages between dev requests and
  during incremental builds.
- **middleware entry** (`src/middleware/`) — a thin Mars handler that
  dispatches GETs to the asset pipeline or the render core based on URL
  shape. Returns 404 for anything outside `list_urls()`.
- **CLI** (`src/cli/`) — argv parsing + boot of dev server + the build crawler.

## Removal list in sol

- Delete `sol/src/ssg/` in its entirety.
- `sol/src/runtime_static_serving.mbt`: drop the four-way fallback into
  `src/ssg/assets/scripts/`. Sol's runtime should not serve SSG assets.
- `sol/src/cli/dev.mbt`: drop `--mode ssg`, `has_ssg_config`,
  `find_ssg_config_file`, `parse_ssg_config`, `run_ssg_dev`, hybrid mode
  warnings, and the SSG-mode help text.
- `sol/src/cli/moon.pkg`: remove imports `@ssg`, `@ssg_gen`, `@ssg_routes`,
  `@ssg_cache`, `@tree`, `@assets`.
- `sol/src/cli/templates.mbt`: drop SSG-only scaffolding paths if any remain.
- `sol/src/cli/mdx_props_validator_wbtest.mbt`: move to `astra/` since it
  validates astra-owned MDX types.
- `sol.mbt/moon.mod.json`: remove the `mizchi/markdown` dependency if nothing
  else in `sol` core needs it after the move (verify before removal).

## Examples and end-to-end tests

- `sol.mbt/examples/sol_docs/` and `sol.mbt/examples/sol_blog/` are
  documentation-site examples and migrate to `astra/examples/`.
- `sol.mbt/examples/sol_app/`, `sol_api/`, `sol_auth/`, `sol_sqlite/`,
  `sol_todo/`, `wasm_island_poc/` stay with `sol/`.
- `sol.mbt/e2e/` Playwright suites split along the same axis: docs/blog
  cases move to `astra/e2e/`, app/api/auth/sqlite stay with `sol/e2e/`.

## Migration sequencing (high level — details belong in the impl plan)

1. Initialize the monorepo skeleton in `luna.mbt` with `moon.work`. Move
   the existing `luna` source under `luna/` if it is not already nested.
2. Vendor the current `sol.mbt` source tree under `luna.mbt/sol/`.
3. Carve `astra/` out of `sol/src/ssg/` plus the SSG-flavored bits of the
   CLI and runtime. Land it as a self-compiling MoonBit package that
   depends only on `mars`, `markdown`, `luna`.
4. Wire the Mars middleware entry point and the `list_urls()` contract.
   Add a smoke test that crawls a tiny fixture and dumps it to disk.
5. Build the `astra dev` and `astra build` CLIs around the middleware.
6. Cut SSG out of `sol`: delete `src/ssg/`, the CLI imports, the dev
   subcommand branches, and the runtime static-serving fallback.
7. Migrate examples and e2e suites along the split.
8. Update READMEs in all three packages and at the monorepo root.
9. Tag a coordinated release: `luna-vX`, `sol-vY`, `astra-v0.1`.

The original `sol.mbt` repository is retired (or kept frozen as a
historical mirror) once the monorepo is the source of truth.

## Out of scope

- Rewriting the Mars middleware composition pipeline.
- Adding any new SSG features. This is a pure structural extraction.
- Renaming the `luna.mbt` GitHub repository.
- Designing per-package release automation; the sequencing above defers
  that to the implementation plan.

## Open questions

- Do we keep `sol.config.json` as the shared config schema (with a `ssg`
  section that astra reads), or does astra introduce a dedicated
  `astra.config.json`? The default in this spec is shared schema with a
  parser shipped from `astra` and a small compatibility shim if needed.
- Whether to keep `sol_docs` / `sol_blog` example names or rename them
  under `astra/examples/` to `astra_docs` / `astra_blog` (cosmetic).
