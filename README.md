# luna.mbt — UI / SSR / SSG monorepo for MoonBit

MoonBit packages share this repository, tied together by `moon.work` and
published independently to [mooncakes](https://mooncakes.io/):

| Package | Role | Path | Latest |
|---------|------|------|--------|
| [`mizchi/luna`](./luna/)    | UI primitive — VDOM, hydration, stream renderer, Island runtime | `luna/`  | 0.23.2 |
| [`mizchi/luna_components`](./luna_components/) | Headless and styled UI components | `luna_components/` | 0.23.2 |
| [`mizchi/sol`](./sol/)      | Mars-based SSR framework with file-based routing                | `sol/`   | 0.23.2 |
| [`mizchi/sol_adapter_cloudflare`](./sol_adapter_cloudflare/) | Cloudflare/Wrangler adapter utilities for Sol | `sol_adapter_cloudflare/` | 0.23.2 |
| [`mizchi/sol_adapter_node`](./sol_adapter_node/) | Node.js adapter utilities for Sol | `sol_adapter_node/` | 0.23.2 |
| [`mizchi/astra`](./astra/)  | Mountable Mars middleware for static site generation            | `astra/` | 0.23.2 |

Each package's README has the canonical usage doc.

## Documentation

- https://luna.mizchi.workers.dev/ (Cloudflare Workers, canonical)
- https://mizchi.github.io/luna.mbt/ (GitHub Pages, mirror — accessible from regions where `workers.dev` is blocked)

## Install — library

Add imports to your `moon.mod`:

```moonbit
// UI library only
import { "mizchi/luna@0.25.0" }

// SSR framework
import { "mizchi/sol@0.23.2", "mizchi/luna@0.25.0" }

// Static-site middleware (mounts on a Mars Server)
import { "mizchi/astra@0.23.2", "mizchi/luna@0.25.0" }
```

## Install — CLI

The CLIs ship as installable mooncakes binaries:

```sh
moon install mizchi/sol/cmd/sol      # → $MOON_HOME/bin/sol
moon install mizchi/astra/cmd/astra  # → $MOON_HOME/bin/astra
```

npm wrappers exist for users who already have node but not moon. The
[`@luna_ui/*`](https://www.npmjs.com/org/luna_ui) family is published in
the current Sol npm wrapper release is `0.21.1`:

```sh
pnpm add -g @luna_ui/sol      # SSR framework CLI
pnpm add -g @luna_ui/astra    # SSG CLI

pnpm add @luna_ui/luna           # core UI library
pnpm add @luna_ui/components     # built-in components
pnpm add @luna_ui/luna-loader    # loader runtime
pnpm add @luna_ui/stella         # Suspense / streaming helpers
pnpm add @luna_ui/wcr            # web-component reactive bindings
pnpm add @luna_ui/testing        # test helpers
```

## Layout

- `luna/`             — luna primitives (signals, render, routing, e2e, vite/vitest configs, scripts/)
- `luna_components/`  — headless + styled UI components (WAI-ARIA APG patterns) + apg-playground demo
- `sol/`              — sol SSR framework + CLI (`cmd/sol`)
- `sol_adapter_cloudflare/` — Cloudflare/Wrangler adapter utilities for Sol
- `sol_adapter_node/` — Node.js adapter utilities for Sol
- `astra/`            — astra SSG middleware + CLI (`cmd/astra`)
- `js/`       — TS bindings + npm wrappers (`@luna_ui/{luna,sol,astra,components,loader,stella,testing,wcr,wcssr}`)
- `website/`  — monorepo docs site (Luna UI), built with `astra build`
- `tests/integration/` — cross-package smoke tests
- `docs/`, `scripts/` — monorepo-wide design notes + coverage tool

## Development

Use MoonBit v0.10.12 or newer and Node.js 24.15 or newer. The current
dependencies use the newer MoonBit collection APIs and jsdom's updated Node
requirements. Run `moon upgrade` and `moon update` when upgrading an older
toolchain. All npm packages and examples share the root pnpm workspace and
`pnpm-lock.yaml`; run `pnpm install` from the repository root.

The root `moon.work` includes the six libraries, documentation, and all 15
MoonBit example modules under `sol/examples`, `astra/examples`, and
`js/stella/examples`. Manifests use `moon.mod` / `moon.pkg`; local dependencies
are resolved through workspace members. Run `moon work use <directory>` when
adding a module and `moon work sync` to align member dependency versions.

Sol examples import generated `app/__gen__` packages. `just check`,
`just test-moonbit`, and `pnpm build:moon` prepare these automatically.
Before invoking `moon` directly in a fresh checkout, run `just generate-examples`.
Its `scripts/moon.work` builds the Sol generator using only library members,
then generates the examples without requiring existing build artifacts.

Example-local `moon.work` files preserve local `_build` paths for standalone
CLI and browser builds. JavaScript examples declare `supported_targets = "js"`;
the Wasm island PoC uses `wasm-gc` and is checked separately by
`just test-workspace`. The browser-driven `sol/e2e/mbt_e2e` runner remains a
separate module because it requires a running server and Playwright.
It uses `mizchi/playwright@0.3.9`, which supports the current MoonBit compiler.
Check or build it independently with `cd sol/e2e/mbt_e2e && moon check --target js`
or `moon build --target js` before starting the browser tests.

Integration test files run sequentially because the example matrix regenerates
packages that other workspace builds also read.

`pnpm build:moon` and the npm publish hooks check the compiler returned by
`moon version --all` before building. If it reports an older `moonc`, run
`moon upgrade` and `moon update` in your normal shell. An alternate toolchain
used in a separate shell does not update the compiler on your default PATH.

```sh
just check          # Generate examples, then type check workspace-wide
just fmt            # Format
just test-moonbit   # MoonBit tests across the workspace
just test-workspace # Manifest checks + all 15 examples, including wasm-gc
just test-e2e       # Playwright e2e (luna + sol + astra)
pnpm test:integration   # build/dev parity + example matrix (node:test)
```

## Release pipeline

- mooncakes (`mizchi/{luna,luna_components,sol,sol_adapter_cloudflare,sol_adapter_node,astra}`) are bumped via `luna/scripts/vup.mjs`
  and pushed to https://mooncakes.io/.
- npm (`@luna_ui/*`) is automated end-to-end:
  - `release-please` (workflow_dispatch) opens a Release PR aggregating
    Conventional Commits across `js/*`.
  - Merging the PR creates per-package GitHub Releases tagged
    `<pkg>-npm-v<version>`.
  - `.github/workflows/publish.yml` reacts to each Release event, packs
    the matching `js/<pkg>` with pnpm, and publishes the tarball with
    `npm publish --provenance` using OIDC Trusted Publishing (no `NPM_TOKEN`).
- Documentation deploys (`luna.mizchi.workers.dev`,
  `mizchi.github.io/luna.mbt`) are tied to the `@luna_ui/luna` Release event,
  so each release-please cycle redeploys the docs once for both targets.

For a local batch release, run from the repository root:

```sh
pnpm install --frozen-lockfile
pnpm publish -r --dry-run  # preview unpublished versions
pnpm publish -r           # publish unpublished versions in dependency order
```

Only the eight public packages under `js/` are eligible. Examples, internal
packages, and `js/wcssr` are private. Each package's `prepack` builds its
artifacts, including MoonBit output where needed; no separate build is
required. Internal `workspace:^` dependencies become registry semver ranges
in the tarball. `just release-npm` forwards arguments to `pnpm publish -r`.

Set the intended versions in `js/*/package.json` before publishing (normally
via release-please). npm versions are independent of Mooncake versions;
recursive publish does not bump versions and skips versions already on npm.
Local publishing uses your npm login and pnpm's default Git checks: use a
clean, committed `main` that is current with origin. For a dry run of pending
changes, use `pnpm publish -r --dry-run --no-git-checks`.

See `docs/internal/npm-release-onboarding.md` for the maintainer setup
(GitHub App secret, npm Trusted Publisher × 8 packages, Cloudflare API
token + account ID, GH Pages source).

## Background

This repo started as the canonical home for `mizchi/luna` only. In May 2026
the upstream `mizchi/sol.mbt` was retired and its sources moved here, then
SSG capability was extracted into the new `mizchi/astra` package
(see `docs/superpowers/specs/2026-05-01-astra-extraction-design.md` and
the implementation plan beside it). These packages now release in
coordinated patch bumps from this repository.

## License

MIT
