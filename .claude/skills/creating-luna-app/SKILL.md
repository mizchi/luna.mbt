---
name: creating-luna-app
description: Use when scaffolding a new standalone CSR app that uses luna (@luna_ui/luna) outside the luna.mbt monorepo — running `npx @luna_ui/luna new`, choosing TSX vs MoonBit, or fixing a broken `--mbt` scaffold (moon build `_bench` import error, or vite `failed to resolve import "mbt:..."`).
---

# creating-luna-app

## Overview

`@luna_ui/luna` ships a scaffolding CLI: `npx @luna_ui/luna new <name>`. It
generates a complete standalone CSR app. **TSX is the default and works out of
the box.** The `--mbt` (MoonBit) variant scaffolds correctly but does **not**
build as-generated — its printed getting-started steps are wrong on two points.
This skill gives the verified working flow for each and the exact fixes for the
`--mbt` breakage.

This is for building an *external* app that consumes luna. For adding an example
*inside* this monorepo (`luna/src/examples/`), use the `luna` skill's
`references/csr-app-scaffolding.md` instead — different layout, different tooling.

## Choose the variant

| You want… | Command | Status |
|---|---|---|
| TypeScript/JSX app (default) | `npx @luna_ui/luna new myapp` | Works as-generated |
| MoonBit app | `npx @luna_ui/luna new myapp --mbt` | Needs 2 manual fixes (below) |

`new` only accepts `--mbt` and `--help`. There is **no** `--user` / `--cloudflare`
/ `--dev` flag — those belong to `sol new`, not luna.

## TSX flow (recommended)

```sh
npx @luna_ui/luna new myapp
cd myapp
npm install
npm run dev      # or: npm run build && npm run preview
```

That's it — verified end-to-end (`vite build` succeeds). Key facts:

- **No vite plugin needed.** CSR works purely through esbuild JSX:
  `vite.config.ts` sets `esbuild.jsxImportSource: "@luna_ui/luna"` and
  `tsconfig.json` sets `"jsx": "preserve"` + `"jsxImportSource": "@luna_ui/luna"`.
- `@luna_ui/luna/vite-plugin` (the `lunaCss` export) is **optional** — it only
  does atomic-CSS extraction for `css()`/`styles()`. Don't add it just to "make
  luna work"; it isn't required.
- `package.json` pins `"@luna_ui/luna": "latest"` (resolves to the current npm
  release, e.g. 0.22.0). Runtime API lives at the package root:
  `createSignal`, `createEffect`, `createMemo`, `For`, `Show`, `Portal`, `render`.

## MoonBit (`--mbt`) flow — with the required fixes

> The in-repo template (`js/luna/bin/cli.ts`) was fixed to scaffold correctly.
> The steps below still apply to apps scaffolded from a **published**
> `@luna_ui/luna` ≤ 0.22.0 (which predates that fix). If your generated
> `moon.mod.json` already pins `0.23.1` and `package.json` build script already
> has `--target js --release`, the scaffold is fixed — just run the printed steps.

The (pre-fix) scaffold prints `moon update && npm install && moon build && npm run dev`.
That fails. Two fixes are needed:

```sh
npx @luna_ui/luna new myapp --mbt
cd myapp

# FIX 1 — moon.mod.json pins a broken luna. Bump 0.23.0 -> 0.23.1:
#   0.23.0's _bench subpackage imports 'mizchi/js/browser/dom', which the
#   resolved mizchi/js@0.12.1 does not export, so `moon build` dies with
#   "Cannot find import 'mizchi/js/browser/dom' in mizchi/luna/_bench@0.23.0".
# Edit moon.mod.json: "mizchi/luna": "0.23.1"

moon update
npm install

# FIX 2 — build RELEASE, not debug. vite-plugin-moonbit resolves
#   `mbt:internal/myapp` to `_build/js/release/build/myapp.js`. Plain
#   `moon build` writes debug/, so vite fails with
#   "Rollup failed to resolve import 'mbt:internal/myapp'".
moon build --target js --release

npm run dev
```

For a production build the generated `"build": "moon build && vite build"` script
has the same debug/release bug — run `moon build --target js --release && vite build`
(or edit the script to add `--release`).

MoonBit-side facts:

- Entry is `main.ts` → `import "mbt:internal/myapp";`, resolved by
  `vite-plugin-moonbit` (external npm dep, not part of this repo). The scaffold
  pins `^0.1.0`; 0.1.5 works fine — the plugin version was **not** the blocker
  (release-vs-debug was). Bumping to `^0.3.0` to match the monorepo is optional.
- `src/moon.pkg.json` uses legacy array `"supported-targets": ["js"]` and emits a
  deprecation warning — harmless, but prefer the expression form if you touch it.
- MoonBit UI code uses `@signal.signal`, `@dom.{div,h1,p,button,text_dyn}`,
  `@dom.render` (imports: `mizchi/signals`, `mizchi/luna/dom`, `mizchi/js_browser/dom`).

## Gotchas

| Symptom | Cause / fix |
|---|---|
| `Cannot find import 'mizchi/js/browser/dom' in mizchi/luna/_bench@0.23.0` | Broken 0.23.0 pin. Set `mizchi/luna` to `0.23.1` in `moon.mod.json`, `moon update`. |
| `Rollup failed to resolve import "mbt:internal/<name>"` | Ran plain `moon build` (debug). Use `moon build --target js --release`. |
| Reached for a "luna vite plugin" for the TSX app | Not needed. TSX CSR uses esbuild `jsxImportSource` only. |
| Used `--user` / `--cloudflare` on `luna new` | Those are `sol new` flags. luna's `new` only has `--mbt`. |
| tsconfig `paths` points at `_build/js/release/build/app/app.js` | Cosmetic mismatch (real artifact is `.../build/<name>.js`); it's only a TS hint, the plugin resolves the real path. |

## Verify before claiming done

- **TSX:** `npm run build` produces `dist/` with no errors.
- **MBT:** `moon build --target js --release` succeeds, then `npx vite build`
  produces `dist/` with no "failed to resolve" error.

## Related

- `luna` skill — working *inside* this monorepo (signal tracking, in-repo examples)
- `sol-bootstrap` skill — `sol new` for the SSR framework (different tool, different flags)
