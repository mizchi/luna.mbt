# `astra → mizchi/sol/*` back-edges (post-cleanup)

Status: Phase C cleanup complete. Only 3 routes-import back-edges
remain, all by design per plan T12 ("routes/ stays in sol — it's the
SSR file router").

## Surviving imports

| File:line | Import | Why |
|---|---|---|
| `astra/src/middleware/moon.pkg:9` | `mizchi/sol/routes` | `scan_docs_dir`, `resolve_duplicate_pages`. Sol owns the SSR file router (plan T12). |
| `astra/src/render/moon.pkg:15`     | `mizchi/sol/routes` | Same. Used by `page_generator.mbt`. |
| `astra/src/components/moon.pkg:4`  | `mizchi/sol/routes` | Same. Used by sidebar/nav components. |

These three imports keep `mizchi/sol` in `astra/moon.mod.json` (currently
a `{ path: "../sol" }` dev dep; flipped to a registry version at publish
time per `astra/CHANGELOG.md`).

## What was lifted in Phase C cleanup

| Was | Now | Why |
|---|---|---|
| `mizchi/sol/adapters` (deploy_adapters) | `mizchi/astra/deploy_adapters` | Only consumed by astra/render after T12; sol/cli's import was unused. |
| `mizchi/sol/isr` (ISRManifest, ISRPageMeta types + serializer) | `mizchi/astra/isr` | Build side (astra/render) emits the manifest; runtime side (sol/router) reads it. Types belong on the emit side. |
| `mizchi/sol/core/env` (FileSystem trait) | `mizchi/astra/env` | Generic FS abstraction needed by both sides. |
| `mizchi/sol/adapters/fs` (NodeFsAdapter, MemFSAdapter) | `mizchi/astra/fs` | Concrete impls of the FS trait; co-owned. |

The lift kept all sol consumers compiling by switching their imports
from `@env`/`@fs_adapter` aliases pointing at `mizchi/sol/...` to the
same aliases pointing at `mizchi/astra/...`. Source `.mbt` files were
unchanged.

## What is NOT planned

- We do NOT plan to lift `mizchi/sol/routes`. Plan T12 line 965 keeps it
  in sol; the three back-edges above are acknowledged in the design.
- We do NOT plan to remove the `mizchi/sol` dep from astra. As long as
  routes lives in sol and astra needs it, the dep stays.
