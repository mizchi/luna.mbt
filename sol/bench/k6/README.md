# k6 Benchmarks

Scripts for load testing the main routes of `examples/sol_app` with `k6`.

Single source of specification: `docs/benchmarking.md`

## Prerequisites

```bash
brew install k6
```

## Usage

Run from the repository root:

```bash
# Default: 20 VUs / 30s
just bench-k6

# Quick check: 5 VUs / 10s
just bench-k6-quick

# 60 VUs / 30s / think 0.05, run 5 times and check the median
just bench-k6 60 30s 0.05 5

# Diff-compare two result JSONs (mix + route)
just bench-k6-compare bench/k6/results/base.json bench/k6/results/candidate.json auto
```

## Standalone Execution

If the server is already running in another terminal, you can run `k6` directly.

```bash
BASE_URL=http://localhost:7777 k6 run bench/k6/sol-app-mix.js
```

To identify bottlenecks per route:

```bash
BASE_URL=http://localhost:7777 VUS=10 DURATION=10s k6 run bench/k6/sol-app-route-profile.js
```

In `examples/sol_app`, starting the server with `SOL_BENCH_MODE=1` disables the
logger middleware so you can measure pure response performance.

The k6 scripts use bench-dedicated APIs, not debug APIs.

- `/api/bench/ping`
- `/api/bench/test/[...path]`

When `runs > 1` is specified, `just bench-k6` saves JSON for each run and
aggregates the median at the end using `bench/k6/summarize-results.js`.

`just bench-k6-compare` compares two JSONs and displays a diff table of `p95/avg/error/rate`.
`mode` can be `mix` / `route` / `auto`.

## Isolating Variance Under High Load (Standard Procedure)

1. Pin CPU conditions
   - Run on the same machine in the same power state and stop unnecessary background jobs
   - On Linux, pin the governor to `performance` with `cpupower` if possible
2. Warm up first
   - Run `just bench-k6-quick` 1-2 times as a warm-up that is not included in the measurement
3. Fix the number of re-runs and perform the main measurement
   - For high-load verification, use `just bench-k6 60 30s 0.05 5` as a baseline and adopt the median of `runs=5`
4. If variance is large, isolate by route profile
   - If the `max-min` of `http_req_duration p95` exceeds 10% of the median, use `just bench-k6-profile 10 10s` to check per-route bias

### Parameters

- `BASE_URL` (default: `http://localhost:7777`)
- `VUS` (default: `20`)
- `DURATION` (default: `30s`)
- `THINK_TIME` (default: `0.1`)
- `runs` (4th argument of `just bench-k6`, default: `1`)
- `RESULTS_JSON` (optional, effective only when `runs=1`)
- `RESULTS_JSON_BASE` (optional, output prefix when `runs>1`. Example: `bench/k6/results/high_load`)
- `mode` (3rd argument of `just bench-k6-compare`, default: `auto`)
