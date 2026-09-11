# Astra dependency boundary

The routes-import follow-up is complete. Astra owns `mizchi/astra/routes`,
and its middleware, renderer, and components import that package.
`astra/moon.mod` has no dependency on `mizchi/sol`; Sol depends on Astra.
The local modules are resolved together through the root `moon.work`.

The current dependency manifests are `astra/moon.mod` and `sol/moon.mod`.
The extraction plans under `sol/docs/superpowers/` describe earlier stages
and retain the configuration names used at the time.

## Earlier extraction work

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
