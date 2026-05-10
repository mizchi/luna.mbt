# mizchi/luna

UI primitive for MoonBit / JS. Fine-grained reactive signals, VDOM,
hydration, stream renderer, file-based routing core, and the Island
runtime that powers `mizchi/sol` and `mizchi/astra`.

```jsonc
// moon.mod.json
{ "deps": { "mizchi/luna": "0.19.2" } }
```

For TypeScript consumers, the JS bindings ship as
[`@luna_ui/luna`](https://www.npmjs.com/package/@luna_ui/luna) (also at
0.19.x) — see `../js/luna/`.

## Layout

- `src/` — luna source (Moon packages: signals, render, routes, dom,
  x/css, x/stella, etc.). Headless + styled APG components live in the
  separate `mizchi/luna_components` mooncake (`../luna_components/`).
- `e2e/` — Playwright suites for the JS-side bindings
- `experiments/` — research code (css-factorize, view_transition,
  webcomponents_ssr, …)
- `spec/` — design notes
- `vite.config.ts`, `vitest.config.ts` — JS-side dev / test runners

## Development

From the repo root:

```sh
moon check --target js                # workspace check (luna + sol + astra)
moon test --target js                 # workspace test
pnpm test:browser                     # vitest browser runner
pnpm test:e2e                         # luna's Playwright suite
```

## Sibling packages

- [`mizchi/sol`](../sol/) — SSR framework on top of luna
- [`mizchi/astra`](../astra/) — Mountable SSG middleware

The monorepo overview is in [`../README.md`](../README.md).

## License

MIT
