# Changelog

All notable changes to `mizchi/astra` are documented here.

## 0.20.1 (2026-05-10)

- Chore: workspace-wide version bump to keep all four mooncakes (luna,
  luna_components, sol, astra) on the same minor line. No API changes —
  astra is unaffected by the `mizchi/luna_components` extraction in
  luna 0.20.1.

## 0.1.0 (2026-05-01)

Initial release. Astra is a Mars middleware for static-site generation,
extracted from `mizchi/sol` 0.15.x's `src/ssg/` subpackage.

### What's in the box

- `Middleware::create(config, cwd~)` returns a value with `handler()` and
  `list_urls()`; mount on any Mars `Server` via `app.all("/*", mw.handler())`.
- `astra dev --port <n>` boots a node:http listener that mounts the
  middleware against the current directory's `docs/` tree.
- `astra build --out <dir>` walks `mw.list_urls()` and dumps every
  response to disk via the in-process `@testing.invoke` driver, so dev
  and build go through one rendering path.
- Asset surface: `/assets/loader.js`, `/assets/style.css` (theme-aware),
  `/assets/github-markdown.css`, `/assets/shiki.css`.
- Configuration via `astra.config.json` or back-compat `sol.config.json`.

### Working example

`astra/examples/sol_docs/` — i18n docs site with blog, MDX, components,
and parity coverage against the pre-extraction `sol --mode ssg` output
(see `astra/docs/parity-notes.md`).

### Tracked gaps (Phase C followup)

`astra/BACK_EDGE_FOLLOWUP.md` lists 7 surviving `astra → mizchi/sol/*`
imports (`adapters`, `routes`, `isr`, `core/env`, `adapters/fs`) that
will be lifted in a future release. They do not affect rendering today.

### Dev-only deps

`mizchi/sol` is declared as `{ "path": "../sol" }` in
`astra/moon.mod.json` for co-development inside the luna.mbt monorepo.
**Before publishing astra to mooncakes**, flip it to a registry version
matching the just-published sol:

```diff
  "deps": {
-    "mizchi/sol": { "path": "../sol" },
+    "mizchi/sol": "0.16.0",
  }
```

(astra and sol form a small mutual dep cycle today; both must be
published in sequence — sol first, then astra with sol pinned.)
