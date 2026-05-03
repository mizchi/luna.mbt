# Sol Troubleshooting

This document summarizes diagnostic procedures for common issues encountered during `sol` development.

## 1. Route Returns 404

Symptoms:

- `sol dev` is running, but the expected page/API returns 404

Checks:

1. Is the target route defined in `app/server/routes.mbt`?
2. Is the correct routing API being used?
   - `@router.register_routes` / `@router.register_server_routes`: path prefix assignment
   - `@router.register_sol_routes`: includes layout composition
3. Did you run `sol generate --mode dev` after making changes?

Reference: `docs/routing.md`

## 2. HMR Is Not Working

Symptoms:

- Page updates are not automatically reflected

Checks:

1. Are you running with `sol dev`? (`sol serve` does not provide HMR)
2. Are there any HMR WebSocket errors in the console?
3. Have customizations around `head` / loader broken the script injection?

Reference: `docs/hot-reload.md`

## 3. `sol build` Passes but `sol serve` Does Not Work as Expected

Checks:

1. Recreate build artifacts with `sol build --clean`
2. Run `sol generate --mode prod` just before and check for differences
3. Verify that `routes` / `output` in `sol.config.ts` (or `sol.config.json`) are configured as intended

## 4. k6 Bench Results Are Unstable

Symptoms:

- `p95` fluctuates significantly even under the same conditions

Checks:

1. Warm up with `just bench-k6-quick` before the actual measurement
2. Run multiple times with `just bench-k6 60 30s 0.05 5` and compare using medians
3. If variability is large, check per-route with `just bench-k6-profile 10 10s`

Reference: `docs/benchmarking.md`

## 5. Connection Error During Bench Execution

Symptoms:

- `connection refused` occurs when running `k6`

Checks:

1. Is the server running at `http://localhost:7777`?
2. When started with `SOL_BENCH_MODE=1`, does `/api/bench/ping` return 200?
3. If running on a different port, ensure `BASE_URL` matches

## 6. Island Hydration Not Working (Cross-Origin URL)

Symptoms:

- The module specified in `luna:url` is not loaded, and the page remains in SSR-only state

Checks:

1. By default, `loader.js` only allows module URLs from the same origin
2. To use cross-origin, set the host/origin in `window.__LUNA_ALLOWED_HOSTS__` (e.g., `127.0.0.1:3456`)
3. If adding permissions at runtime, call `window.__LUNA_SCAN__()` after `window.__LUNA_SET_ALLOWED_HOSTS__(...)`
4. Verify that the scheme of `luna:url` is `http` or `https`

## 7. Primary References to Check First

- Routing specification: `docs/routing.md`
- Benchmarking specification: `docs/benchmarking.md`
- HMR contract: `docs/hot-reload.md`
