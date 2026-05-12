# luna.mbt — UI / SSR / SSG monorepo for MoonBit

Three packages share this repository, tied together by `moon.work` and
published independently to [mooncakes](https://mooncakes.io/):

| Package | Role | Path | Latest |
|---------|------|------|--------|
| [`mizchi/luna`](./luna/)    | UI primitive — VDOM, hydration, stream renderer, Island runtime | `luna/`  | 0.20.1 |
| [`mizchi/sol`](./sol/)      | Mars-based SSR framework with file-based routing                | `sol/`   | 0.20.2 |
| [`mizchi/astra`](./astra/)  | Mountable Mars middleware for static site generation            | `astra/` | 0.20.1 |

Each package's README has the canonical usage doc.

## Documentation

- https://luna.mizchi.workers.dev/ (Cloudflare Workers, canonical)
- https://mizchi.github.io/luna.mbt/ (GitHub Pages, mirror — accessible from regions where `workers.dev` is blocked)

## Install — library

Add to your `moon.mod.json`:

```jsonc
// UI library only
{ "deps": { "mizchi/luna": "0.20.1" } }

// SSR framework
{ "deps": { "mizchi/sol": "0.20.2", "mizchi/luna": "0.20.1" } }

// Static-site middleware (mounts on a Mars Server)
{ "deps": { "mizchi/astra": "0.20.1", "mizchi/luna": "0.20.1" } }
```

## Install — CLI

The CLIs ship as installable mooncakes binaries:

```sh
moon install mizchi/sol/cmd/sol      # → $MOON_HOME/bin/sol
moon install mizchi/astra/cmd/astra  # → $MOON_HOME/bin/astra
```

npm wrappers exist for users who already have node but not moon. The
[`@luna_ui/*`](https://www.npmjs.com/org/luna_ui) family is published in
the current npm wrapper release is `0.20.2`:

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
- `astra/`            — astra SSG middleware + CLI (`cmd/astra`)
- `js/`       — TS bindings + npm wrappers (`@luna_ui/{luna,sol,astra,components,loader,stella,testing,wcr,wcssr}`)
- `website/`  — monorepo docs site (Luna UI), built with `astra build`
- `tests/integration/` — cross-package smoke tests
- `docs/`, `scripts/` — monorepo-wide design notes + coverage tool

## Development

```sh
just check          # Type check workspace-wide
just fmt            # Format
just test-unit      # MoonBit tests (luna + sol + astra)
just test-e2e       # Playwright e2e (luna + sol + astra)
pnpm test:integration   # build/dev parity + 7-example matrix (node:test)
```

## Release pipeline

- mooncakes (`mizchi/{luna,sol,astra}`) is bumped via `luna/scripts/vup.mjs`
  and pushed to https://mooncakes.io/.
- npm (`@luna_ui/*`) is automated end-to-end:
  - `release-please` (workflow_dispatch) opens a Release PR aggregating
    Conventional Commits across `js/*`.
  - Merging the PR creates per-package GitHub Releases tagged
    `<pkg>-v<version>`.
  - `.github/workflows/publish.yml` reacts to each Release event and runs
    `npm publish --provenance` from the matching `js/<pkg>` directory using
    OIDC Trusted Publishing (no `NPM_TOKEN`).
- Documentation deploys (`luna.mizchi.workers.dev`,
  `mizchi.github.io/luna.mbt`) are tied to the `@luna_ui/luna` Release event,
  so each release-please cycle redeploys the docs once for both targets.

See `docs/internal/npm-release-onboarding.md` for the maintainer setup
(GitHub App secret, npm Trusted Publisher × 8 packages, Cloudflare API
token + account ID, GH Pages source).

## Background

This repo started as the canonical home for `mizchi/luna` only. In May 2026
the upstream `mizchi/sol.mbt` was retired and its sources moved here, then
SSG capability was extracted into the new `mizchi/astra` package
(see `docs/superpowers/specs/2026-05-01-astra-extraction-design.md` and
the implementation plan beside it). All three packages now release in
coordinated patch bumps from this repository.

## License

MIT
