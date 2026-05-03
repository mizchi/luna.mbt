# Benchmarking Specification

This document serves as the single source of truth for the `sol` benchmarking procedure and the behavior of `SOL_BENCH_MODE`.

## 1. Scope

- Target: HTTP response measurement of `examples/sol_app`
- Tool: `k6`
- Main scripts:
  - `bench/k6/sol-app-mix.js`
  - `bench/k6/sol-app-route-profile.js`

## 2. Standard Commands

Run from the repository root:

```bash
# mix profile (single run)
just bench-k6

# mix profile (multi-run, median summary)
just bench-k6 60 30s 0.05 5

# route profile
just bench-k6-profile 10 10s

# compare two JSON results
just bench-k6-compare bench/k6/results/base.json bench/k6/results/candidate.json auto
```

## 3. SOL_BENCH_MODE Behavior

`just bench-k6` starts the `examples/sol_app` server with `SOL_BENCH_MODE=1`.

In this mode, the following behaviors are fixed to reduce benchmark noise:

- Logger middleware is disabled
- k6 uses bench-dedicated APIs:
  - `/api/bench/ping`
  - `/api/bench/test/[...path]`

The purpose is relative comparison of routing/rendering performance, not verification of production behavior.

## 4. Multi-Run and Median

- `just bench-k6 <vus> <duration> <think_time> <runs>`
- When `runs > 1`:
  - JSON from each run is saved
  - `bench/k6/summarize-results.js` aggregates median/min/max

Output files:

- `runs=1`: `RESULTS_JSON` (defaults to `bench/k6/results/latest.json` if not specified)
- `runs>1`: Uses `RESULTS_JSON_BASE` (defaults to `bench/k6/results/latest` if not specified) and generates `*_runN.json`

## 5. Result Comparison

`just bench-k6-compare <baseline> <candidate> [mode]`

- `mode=mix`: Compares overall metrics (`p95/avg/error/rate`)
- `mode=route`: Compares route profile metrics (`page_*_duration`, `api_*_duration`)
- `mode=auto`:
  - Compares both mix metrics and route metrics simultaneously

Output is a table with `baseline` / `candidate` / `delta` / `delta%` / `verdict` columns.

## 6. Isolating Variability Under High Load

When results fluctuate under high load, follow these standardized steps:

1. Fix CPU conditions
   - Run on the same machine with the same power state, and stop unnecessary background processes
   - On Linux, if possible, fix the governor to `performance` using `cpupower`
2. Warm up first
   - Run `just bench-k6-quick` 1-2 times before the actual measurement to eliminate variability from JIT/file cache initialization
3. Fix the number of re-measurement runs
   - Use `just bench-k6 60 30s 0.05 5` as the baseline for high-load comparisons, and adopt the median of `runs=5`
4. If variability is large, isolate by route profile
   - If the `max-min` of `http_req_duration p95` exceeds 10% of the median, check per-route bias with `just bench-k6-profile 10 10s`
