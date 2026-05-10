---
name: sol-cloudflare-deploy
description: Use when deploying sol_app (or any sol-built MoonBit SSR worker) to Cloudflare Workers, debugging error 10021, or extending sol/examples/sol_app/scripts/patch-cloudflare-globals.mjs. Captures the global-scope I/O traps in MoonBit core + sol's generated bundle and the wrangler ASSETS binding URL layout.
---

# sol-cloudflare-deploy

## Purpose

Deploying `sol/examples/sol_app` (or another sol-generated SSR bundle) to Cloudflare Workers triggers three independent global-scope I/O violations and one ASSETS binding URL mismatch. Each one only surfaces *after* the previous one is fixed, so naive iteration burns one deploy cycle per trap. This skill bundles the full checklist so a future deploy goes through in one pass.

Concrete artifact: `sol/examples/sol_app/scripts/patch-cloudflare-globals.mjs`. Keep that file in sync with the rules below.

## When to use

- Adding a new sol example to a Cloudflare Workers deploy
- Bumping the MoonBit toolchain or `mizchi/sol` version (the mangled symbols in the patch script can drift)
- Debugging a fresh `error 10021` (`Disallowed operation called within global scope`)
- Auditing a Workers-bound bundle for top-level I/O before the first deploy

## Workflow

### 0. Always dry-run first

```sh
pnpm dlx wrangler@4 deploy --dry-run
```

Run this from `sol/examples/sol_app/` after `sol build` + the patch script. Validation error 10021 is detected in dry-run, not just on the live API call. **One deploy cycle per silent fix is wasteful — surface every violation locally first.**

### 1. Three global-scope I/O traps to patch

The post-build patch script rewrites three call sites. Re-run it after every `sol build` (or wire it into the deploy workflow between `sol build` and `wrangler deploy`).

| # | File | Symptom | Patch |
|---|------|---------|-------|
| 1 | `_build/.../__gen__/server/server.js` | `_M0FPB12random__seed()` called at module top-level via `globalThis.crypto.getRandomValues`. MoonBit core's eager hash-randomization seed. | `const _M0FPB4seed = _M0FPB12random__seed();` → `const _M0FPB4seed = 0;` |
| 2 | `_build/.../__gen__/server/server.js` | `run_app` mode selector picks the async `with_initialized_fs` branch on Workers (because `process.versions.node` is populated under `nodejs_compat`), which awaits `import('node:fs')` at module load. | `const mode = _p && !_p$2 ? 0 : 1;` → `const mode = 0;` (force sync export) |
| 3 | `.sol/prod/server/main.js` | `await new Promise(resolve => { ... setInterval(...) ... })` polls for `globalThis.__SOL_APP__` at top level. Workers ban timers in global scope. | Whole block → `const app = globalThis.__SOL_APP__;` (sync access — works once trap #2 is fixed) |

The script must stay **idempotent**: re-running after a partial-applied state shouldn't crash. Each rewrite checks both pre- and post-patched patterns and skips if already done.

If MoonBit core / sol changes mangled symbols, the patch script's regex pattern won't match. The script is intentionally strict (throws when the pattern is missing) so a silently-changed upstream is loud, not silent.

### 2. wrangler ASSETS binding maps `directory` verbatim

`wrangler.json`:

```jsonc
{
  "assets": {
    "directory": ".sol/prod/dist-assets",
    "binding": "ASSETS"
  }
}
```

The HTML sol generates references `/static/<island>.js` and `/__sol__/<loader>.js`. wrangler's ASSETS binding maps the configured `directory` *root* to `/`, so:

- `directory: ".sol/prod/static"` → `/__sol__/*` and `/static/*` are both 404 (the `__sol__/` siblings aren't even seen, and `static/counter.js` ends up at `/counter.js`, not `/static/counter.js`).
- Need: a `dist-assets/` tree mirroring the URL layout (`__sol__/*` + `static/*`). The patch script stages this from `.sol/prod/__sol__/` and `.sol/prod/static/`. The sibling `.sol/prod/server/` stays excluded — exposing it would leak server source.

When adding new asset prefixes (e.g. `/admin/static/...`), update both the patch script's copy step and any sol-side URL emission.

### 3. Initial deploy must not poison browser caches

The first broken deploy will return worker fallback responses (e.g. `// Not found: loader.js`). Cloudflare's Workers Static Assets default `cache-control` for ASSETS routes that fall through to the worker can be longer than expected — and clients that loaded the broken state cache it for the full TTL.

Two safeguards:

- **wrangler default for assets is currently `max-age=0, must-revalidate`**. Verify with `curl -sI https://sol-examples.mizchi.workers.dev/__sol__/loader.js` after deploy that the header reads `cache-control: public, max-age=0, must-revalidate`. If it ever drifts (custom worker handler, wrangler upgrade), re-pin in `wrangler.json` via `assets.headers` or a worker-side `Response` header.
- **Symptom of the trap**: deploy goes green, but a previously-loaded session stays broken because the script tag still resolves to a stale stub from disk cache. Clear with hard reload (Cmd+Shift+R) or new incognito; instruct users likewise. Don't waste a debug cycle re-deploying when the edge already serves correct bytes — verify with `curl` first.

Long-term upstream fix: sol should emit versioned script src (`/__sol__/loader.js?v=<deploy-hash>`) so URL changes per deploy. Until that lands, breaking the cache requires a URL change.

### 4. Verify with all three layers

After `wrangler deploy` reports success:

```sh
# Edge content
curl -s https://sol-examples.mizchi.workers.dev/__sol__/loader.js | wc -c   # ~5700 bytes
curl -s https://sol-examples.mizchi.workers.dev/static/counter.js | head -c 40
curl -sI https://sol-examples.mizchi.workers.dev/__sol__/loader.js | grep -i cache-control

# Server-rendered HTML
curl -s https://sol-examples.mizchi.workers.dev/ | grep -oE '<title>[^<]*</title>'

# Hydration (browser only): visit in incognito, click +/- on the homepage counter, value should change.
```

If hydration fails but edge serves the right bytes, suspect browser cache from an earlier broken deploy. Don't redeploy — hard reload first.

## Pitfalls

- **One trap at a time hides the others.** Each global-I/O fix unblocks the next bundle import, and the next violation only fires once the previous is patched. Always run the patch script in full + `wrangler deploy --dry-run` rather than ship-and-pray.
- **Patch script not idempotent → CI re-runs explode.** Both pre- and post-patched regex must be checked; idempotency is part of the contract.
- **Mangled symbol drift.** `_M0FPB4seed` / `_M0FPB12random__seed` etc are MoonBit core mangled names. They'll change across MoonBit toolchain bumps. The script throws if the pattern is missing — investigate and update, don't just relax the regex.
- **`directory: ".sol/prod"` exposes server source.** Don't be tempted to point ASSETS at `.sol/prod/` directly to "include everything"; `.sol/prod/server/main.js` would become a public asset.
- **`nodejs_compat` is necessary** in `compatibility_flags` because sol's bundle uses `process` and `node:fs` symbols. But it also makes `process.versions.node` truthy, which is exactly what makes sol's `runtime_is_node` mis-detect Workers — this is *why* trap #2 exists.
- **Don't re-deploy to "fix" a stale browser cache.** The edge is already correct; only the client needs to refresh.
- **Cache poison from initial broken deploy lasts for the asset's `cache-control` TTL.** If an early deploy ever emitted `max-age=3600` (older wrangler defaults / explicit override), that's how long affected sessions stay broken. The current default of `max-age=0, must-revalidate` makes this self-healing for fresh visitors.

## Related

- `sol/examples/sol_app/scripts/patch-cloudflare-globals.mjs` — the concrete artifact this skill describes
- `.github/workflows/deploy-sol-examples.yml` — wires `moon build` → `sol build` → patch → `wrangler deploy`
- `sol/CHANGELOG.md` — once upstream sol gets a Workers-aware adapter, this skill (and the patch script) can shrink
