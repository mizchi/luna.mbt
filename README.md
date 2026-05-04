# luna.mbt — UI / SSR / SSG monorepo for MoonBit

Three packages share this repository, tied together by `moon.work` and
published independently to [mooncakes](https://mooncakes.io/):

| Package | Role | Path |
|---------|------|------|
| [`mizchi/luna`](./luna/)        | UI primitive — VDOM, hydration, stream renderer, Island runtime | `luna/` |
| [`mizchi/sol`](./sol/)         | Mars-based SSR framework with file-based routing                | `sol/` |
| [`mizchi/astra`](./astra/)     | Mountable Mars middleware for static site generation            | `astra/` |

Each package's README has the canonical usage doc.

## Layout

- `luna/` — luna primitives (signals, render, routing, x/components)
- `sol/` — sol SSR framework + CLI
- `astra/` — astra SSG middleware + CLI + examples
- `examples/` — luna-only demos (sol/astra examples live under their packages)

## Install (pick one)

```jsonc
// moon.mod.json — UI library only
{ "deps": { "mizchi/luna": "0.18.3" } }

// SSR framework
{ "deps": { "mizchi/sol": "0.16.0", "mizchi/luna": "0.18.3" } }

// Documentation site (SSG middleware)
{ "deps": { "mizchi/astra": "0.1.0", "mizchi/luna": "0.18.3" } }
```

## Development

```bash
just check          # Type check workspace-wide
just fmt            # Format
just test-unit      # MoonBit tests (sol + astra + luna)
just test-e2e       # Playwright e2e (sol/e2e + astra/e2e)
```

## Background

Astra was extracted from sol in `0.16.0` to give SSG its own
middleware-shaped surface that can mount on any Mars `Server`. The
extraction design lives in
`docs/superpowers/specs/2026-05-01-astra-extraction-design.md`; the
implementation plan is in `docs/superpowers/plans/2026-05-01-astra-extraction.md`.

## License

MIT
