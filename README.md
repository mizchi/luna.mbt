# luna.mbt — UI / SSR / SSG monorepo for MoonBit

Three packages share this repository, tied together by `moon.work` and
published independently to [mooncakes](https://mooncakes.io/):

| Package | Role | Path | Latest |
|---------|------|------|--------|
| [`mizchi/luna`](./luna/)    | UI primitive — VDOM, hydration, stream renderer, Island runtime | `luna/`  | 0.19.2 |
| [`mizchi/sol`](./sol/)      | Mars-based SSR framework with file-based routing                | `sol/`   | 0.16.2 |
| [`mizchi/astra`](./astra/)  | Mountable Mars middleware for static site generation            | `astra/` | 0.1.2  |

Each package's README has the canonical usage doc.

## Install — library

Add to your `moon.mod.json`:

```jsonc
// UI library only
{ "deps": { "mizchi/luna": "0.19.2" } }

// SSR framework
{ "deps": { "mizchi/sol": "0.16.2", "mizchi/luna": "0.19.2" } }

// Static-site middleware (mounts on a Mars Server)
{ "deps": { "mizchi/astra": "0.1.2", "mizchi/luna": "0.19.2" } }
```

## Install — CLI

The CLIs ship as installable mooncakes binaries:

```sh
moon install mizchi/sol/cmd/sol      # → $MOON_HOME/bin/sol
moon install mizchi/astra/cmd/astra  # → $MOON_HOME/bin/astra
```

An npm wrapper exists for users who already have node but not moon:

```sh
pnpm add -g @luna_ui/sol     # 0.16.2
pnpm add -g @luna_ui/astra   # 0.1.2
```

## Layout

- `luna/`     — luna primitives (signals, render, routing, x/components, e2e, vite/vitest configs, scripts/)
- `sol/`      — sol SSR framework + CLI (`cmd/sol`)
- `astra/`    — astra SSG middleware + CLI (`cmd/astra`)
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

## Background

This repo started as the canonical home for `mizchi/luna` only. In May 2026
the upstream `mizchi/sol.mbt` was retired and its sources moved here, then
SSG capability was extracted into the new `mizchi/astra` package
(see `docs/superpowers/specs/2026-05-01-astra-extraction-design.md` and
the implementation plan beside it). All three packages now release in
coordinated patch bumps from this repository.

## License

MIT
