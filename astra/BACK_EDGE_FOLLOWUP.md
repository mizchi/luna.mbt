# Surviving `mizchi/sol/*` back-edges in astra/src

Status: deferred to Phase C (T12+). T11 closed parity gaps but did not
lift the back-edges below; the plan keeps that work for Phase C T12-T13.

These back-edges remain after T7 (SSG submodule lift). They are tracked here so that T11 cleanup can pick them up. The `mizchi/sol` dependency stays in `astra/moon.mod.json` until all of these are zero or migrated.

## Surviving imports (post-T7)

| File:line | Import | Reason for deferral |
|---|---|---|
| `astra/src/tree/moon.pkg:3` | `mizchi/sol/adapters/fs` | Shared FS abstraction (memfs + node_fs). Used by both sol/cli, sol/routes (sol-side) and astra/tree, astra/cache. Internally depends on `mizchi/sol/core/env`. Lifting requires also lifting `core/env`, and updating 4+ sol callers — too expensive for this loop. |
| `astra/src/cache/moon.pkg:4` | `mizchi/sol/core/env` | `FileSystem` trait used as a generic constraint by `DiskCache`. Heavily consumed by sol (cli, cli_common, routes, adapters/fs internal). Co-owned with `adapters/fs`; same blocker. |
| `astra/src/cache/moon.pkg:5` | `mizchi/sol/adapters/fs` | Same as tree row. |
| `astra/src/render/moon.pkg:11` | `mizchi/sol/adapters` | Deploy-target adapters (cloudflare/vercel/netlify/etc.). Used by `page_generator.mbt:126,240` (`@adapters.run_adapter`). Owned by sol semantics-wise; sol/cli is the primary consumer. Belongs in sol unless we explicitly relocate the deploy-adapter concept. |
| `astra/src/render/moon.pkg:13` | `mizchi/sol/isr` | Incremental Static Regeneration: handler/middleware/manifest. `astra/render/isr.mbt` only constructs the manifest (`@sol_isr.ISRManifest`). The runtime handler stays in sol/router. Splitting types vs. handler is a non-trivial refactor; defer. |
| `astra/src/render/moon.pkg:15` | `mizchi/sol/routes` | SSR file-router. Plan T12 line 965 explicitly says "routes/ stays in sol". DO NOT lift. |
| `astra/src/components/moon.pkg:4` | `mizchi/sol/routes` | Same as render row. Plan T12 says stays in sol. |
| `astra/src/middleware/moon.pkg:7` | `mizchi/sol/routes` | `scan_docs_dir`, `resolve_duplicate_pages`. KEEP — same plan-T12 justification as render/components. |

## Action plan for T11

1. Decide whether `sol/core/env` + `sol/adapters/fs` should be lifted to a new neutral package (e.g. `mizchi/astra/runtime/fs` or kept in sol with a clearer ownership label). Either is valid; the current placement leaks "sol" as a name into astra-owned modules, but the trait surface is small.
2. Decide whether `sol/isr` types belong in astra (manifest building) while the handler stays in sol/router. If yes, split `isr/types.mbt` + `isr/serializer.mbt` into `astra/src/isr/` and keep `isr/handler.mbt` + `isr/middleware.mbt` in sol.
3. Decide whether `sol/adapters` (deploy targets) should move to `astra/src/deploy_adapters/` or stay in sol. If they call into `sol/ssg` they probably stay; if they only consume `astra/BuildContext` + `@astra.SsgConfig` they can move.
4. `sol/routes` stays per plan T12. The two astra imports (`render`, `components`) remain a back-edge by design.

## Explicit non-goals for this followup

- We do NOT plan to remove `mizchi/sol` from `astra/moon.mod.json` until at least items 1-3 above are resolved.
- We do NOT plan to "stub out" sol calls in astra to mask the dep — better to leave the back-edge visible until the architectural split is decided.
