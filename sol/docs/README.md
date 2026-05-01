# Sol Documentation Guide

This is the entry point for `docs/`. It establishes a fixed reading order by purpose and clarifies the single source of truth for specifications.

## Reading Order

1. Preparing to join development
   - `docs/onboarding.md`
2. Getting started (quickest launch)
   - `docs/quickstart.md`
3. Deploy operations
   - `docs/deploy.md`
4. Incident response
   - `docs/runbook.md`
5. Routing specification
   - `docs/routing.md`
6. Development operations (benchmarking)
   - `docs/benchmarking.md`
7. Troubleshooting
   - `docs/troubleshooting.md`
8. Development experience (HMR)
   - `docs/hot-reload.md`
9. Migration
   - `docs/migrate-from-mars.md`
10. Advanced design (Wasm entrypoint)
   - `docs/wasm-entrypoint.md`

## Links by Purpose

- Want to check specifications
  - `docs/routing.md`
  - `docs/benchmarking.md`
- Want to get it running first
  - `docs/onboarding.md`
  - `docs/quickstart.md`
- Want to check deployment
  - `docs/deploy.md`
- Want to check incident response
  - `docs/runbook.md`
- Want to isolate a problem
  - `docs/troubleshooting.md`
- Want to migrate incrementally from `mars`
  - `docs/migrate-from-mars.md`
- Want to check the HMR contract
  - `docs/hot-reload.md`
- Want to check the future design of `.mbtx` / WASI / WAGI
  - `docs/wasm-entrypoint.md`

## Document Map

| Path | Role | Notes |
|---|---|---|
| `docs/onboarding.md` | Guide | First-day steps for joining development and `just verify` |
| `docs/quickstart.md` | Guide | Shortest steps for `dev -> build -> serve` |
| `docs/deploy.md` | Guide | Preview / production deployment steps for docs |
| `docs/runbook.md` | Operations | Incident response and rollback steps for docs |
| `docs/routing.md` | Specification (single source) | API selection, Layout semantics, `source_path` convention |
| `docs/benchmarking.md` | Specification (single source) | k6 steps, `SOL_BENCH_MODE`, isolating variance under high load |
| `docs/troubleshooting.md` | Operations | Isolating 404/HMR/benchmark variance issues |
| `docs/hot-reload.md` | Design | HMR contract shared between `sol`/`mars` |
| `docs/migrate-from-mars.md` | Guide | Incremental migration from existing `mars` code |
| `docs/wasm-entrypoint.md` | Design draft | Wasm entrypoint direction based on `.mbtx` |

## Update Rules

- For specification changes, update the single source (`docs/routing.md` / `docs/benchmarking.md`) first
- README and supplementary documents should link to the single source and not duplicate the same content
