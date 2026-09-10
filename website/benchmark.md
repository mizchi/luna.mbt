---
title: Benchmark Report
sidebar: false
---

# Luna Benchmark Report

Every figure on this page was produced by a script in this repository, and the
command that produces it is printed next to the table. Nothing here is quoted
from memory or from a third-party benchmark.

Numbers are grouped by how much you should trust them:

| Tier | Metric | Varies between machines? |
|------|--------|--------------------------|
| **Exact** | Bundle bytes, propagation counts | No — byte- and count-identical anywhere |
| **Comparative** | Grid benchmarks vs Preact / React | Ratios hold; absolute ops/s do not |
| **Indicative** | Signal throughput, MoonBit micro-benchmarks | Machine- and run-dependent |

## 1. Bundle size

Luna has no single bundle size. The published entry points are tree-shakeable,
so what you ship is what you import — from 351 B for `resource-lite` to 24.5 KB
for the full router + resource surface.

```sh
node luna/scripts/treeshake-size.mjs --check
```

| Entry point | Minified | Gzip |
|-------------|---------:|-----:|
| `resource-lite` | 351 B | 210 B |
| `router-lite` | 2,539 B | 1,149 B |
| `render` | 7,021 B | 2,264 B |
| `signals-only` | 7,370 B | 2,591 B |
| `memo` | 8,487 B | 2,917 B |
| `raw-signals` | 8,657 B | 2,869 B |
| `signals-effect` | 8,900 B | 3,005 B |
| `resource-index` | 9,988 B | 3,305 B |
| `split-signals-shared` | 11,933 B | 3,861 B |
| `split-signals` | 14,540 B | 4,195 B |
| `router-index` | 21,482 B | 5,900 B |
| `router-resource` | 24,534 B | 6,800 B |

These are checked into `luna/scripts/treeshake-baseline.json` and CI fails on a
single byte of drift, so the table above is exact rather than approximate.

### Head to head with Preact

The comparison builds the *same program* twice — once against Luna, once
against Preact — and measures the resulting bundle:

```sh
node luna/scripts/preact-size-compare.mjs --build
```

| Scenario | Luna (min / gzip) | Preact (min / gzip) | Smaller |
|----------|------------------:|--------------------:|---------|
| `signals-only` | 7,370 / 2,591 B | 4,538 / 1,645 B | Preact |
| `signals-effect` | 8,900 / 3,005 B | 4,560 / 1,660 B | Preact |
| `memo` | 8,487 / 2,917 B | 4,604 / 1,673 B | Preact |
| `render-static` | 7,021 / 2,264 B | 10,577 / 4,494 B | **Luna** |
| `render-reactive` | 11,915 / 3,851 B | 20,100 / 7,880 B | **Luna** |
| `context-basic` | 4,413 / 1,468 B | 12,854 / 5,360 B | **Luna** |

**Preact wins 3, Luna wins 3.** Preact's signals core is smaller than Luna's;
Luna's renderer is smaller than Preact's VDOM. Once you render anything, Luna's
total comes out ahead in these cases.

The script reports two recurring contributors to Luna's signal bundles — the
bounds-check panic string and the stack-trace parsing path — both from the
MoonBit runtime rather than from Luna itself.

React is not part of the size harness, so this page makes no claim about React
bundle sizes.

## 2. Reactivity, as exact counts

Timing is noisy; update counts are not. This suite asserts *how many times*
each piece of the graph runs, so a regression in propagation shows up as a
failing test rather than as a slow benchmark.

```sh
moon test --target js -p mizchi/luna/_bench
```

Five signal writes drive every scenario:

| Scenario | Measured | Meaning |
|----------|---------:|---------|
| Effect on an unrelated signal | **0** | No spurious wakeups |
| Effect on the signal it reads | **5** | One run per write |
| Effect behind a diamond (2 paths) | **5** | Glitch-free: no double run |
| Memo bodies in a depth-8 chain | **40** | 8 memos × 5 writes, no redundancy |
| Effect for a batch of 5 writes | **1** | `batch` collapses the flush |
| `watch` on an unchanging value | **0** | Structural equality cuts off |
| Effect behind a value-collapsing memo | **5** | See below |
| Effect behind an `Eq`-aware memo | **0** | |

The seventh row is the one gap: `memo` cuts off on **identity**
(`physical_equal`), so a memo that maps many different inputs to an equal-but-
newly-allocated value still notifies its dependents. `watch` compares with
`Eq` and does cut off. When cutoff matters, wrap the memo:

```moonbit
fn[T : Eq] memo_eq(f : () -> T) -> () -> T {
  let out = @resource.signal(f())
  let _ = @signals.watch(f, (next, _prev) => out.set(next))
  () => out.get()
}
```

That is the difference between rows 7 and 8 — 5 effect runs versus 0.

## 3. Signal throughput

`runtime-bench.mjs` runs each scenario against a **control loop** of pure
integer arithmetic and reports the ratio, so results survive being run on a
different machine better than raw ops/s do.

```sh
node luna/scripts/runtime-bench.mjs
```

Median of three runs on the machine described at the bottom of this page:

| Scenario | ns/op | × control loop |
|----------|------:|---------------:|
| `control-loop` (reference) | 2.83 | 1.00 |
| `signal-set-get` | 6.85 | 2.42 |
| `signal-update-fn` | 9.62 | 3.40 |
| `batch-10-updates` | 20.36 | 7.25 |
| `create-signal` | 33.09 | 11.04 |
| `memo-after-update` | 46.41 | 16.42 |

A signal write plus read costs about **2.4×** a hand-written arithmetic loop
iteration. The ratios still move between machines — the baseline committed in
`runtime-bench-baseline.json` records 4.41 for `signal-set-get` on the machine
that generated it — which is why CI checks these with a 20 % tolerance instead
of exact equality.

## 4. DOM benchmarks against Preact and React

```sh
pnpm test:bench     # vitest bench, real Chromium via Playwright
```

This runs in a **headless Chromium**, not jsdom. That distinction matters: an
earlier revision of this page reported jsdom figures, which understated Luna by
roughly an order of magnitude on mount-heavy cases.

Median of three runs, ops/s (higher is better):

| Scenario | Luna | Preact | React |
|----------|-----:|-------:|------:|
| Initial mount, 2,500 static cells | 818 | 954 | 91 |
| Initial mount, 2,500 reactive cells | 305 | 443 | 81 |
| Update all 2,500 cells | 442 | 9,790 | 95 |
| Initial mount, 5,000 cells | 424 | 444 | 49 |
| Append 100 items to a list | 275 | 2,704 | 61 |

Relative to Luna:

| Scenario | Preact | React |
|----------|-------:|------:|
| Initial mount, 2,500 static cells | 1.17× faster | 9.0× slower |
| Initial mount, 2,500 reactive cells | 1.45× faster | 3.8× slower |
| Update all 2,500 cells | 22.1× faster | 4.7× slower |
| Initial mount, 5,000 cells | 1.05× faster | 8.7× slower |
| Append 100 items to a list | 9.8× faster | 4.5× slower |

Read that honestly:

- **Mounting is close.** Luna is within 1.05×–1.45× of Preact, and at 5,000
  cells the two are level. React is 4×–9× behind both.
- **"Update all 2,500 cells" is Luna's worst case, by construction.** The
  benchmark holds the whole grid in one signal and gives every cell a dynamic
  `className` binding. One write therefore re-runs 2,500 independent bindings,
  while Preact does one component render and one keyed diff. Fine-grained
  reactivity is designed for the opposite shape — few bindings changing out of
  many — so this scenario measures the case it is not built for.
- **Appending to a list** is the same story at smaller scale.

The run-to-run spread is real: across three runs "initial mount, 2,500 reactive
cells" measured 166 / 305 / 321 ops/s for Luna, and vitest reported up to ±63 %
relative margin of error on that case. Treat single-digit percentage
differences on this table as noise.

## 5. MoonBit-side benchmarks

`moon bench` covers the SSR renderer and the serializer. Wall-clock results in
containerised environments swing far too wide to publish as headline numbers —
the same `core/render` suite has been observed varying by more than 10× on an
unmodified tree — so CI compares against a recorded baseline with a **35 %**
tolerance rather than asserting absolute speed:

```sh
node luna/scripts/moonbench-check.mjs --check
```

The recorded baseline (`luna/scripts/moonbench-baseline.json`):

| Suite | Case | ns/op |
|-------|------|------:|
| `core/render` | list (10 items) | 2,530 |
| `core/render` | page | 2,665 |
| `core/render` | large_list (100 items, escaped) | 63,770 |
| `core/stream_render` | list (10 items) | 2,585 |
| `core/stream_render` | page | 2,980 |
| `core/stream_render` | large_list (100 items, escaped) | 72,740 |
| `core/serialize` | state_value_to_json: large_array | 3,200 |

Streaming render costs 2–14 % more than buffered render on the same input,
which is the trade for emitting the first bytes earlier.

## Where Luna fits

Based on the measurements above rather than on aspiration:

- **A good fit** when pages are mostly static with a few reactive regions
  (documentation, content sites, dashboards with localised updates), when you
  want SSR plus partial hydration, and when you want the UI layer written in
  MoonBit's type system.
- **A poor fit** when most of the DOM changes on most updates. Preact's VDOM
  diff wins that shape by an order of magnitude, and no amount of Luna tuning
  changes the asymptotics of "2,500 bindings re-run".
- **Not yet comparable to React/Preact in ecosystem** — component libraries,
  devtools, and hiring pool are all in a different league. Nothing on this page
  measures that, and it usually matters more than any row above.

`Signal`, `render` and hydration compile to every MoonBit backend
(`luna/src` and `luna/src/core` declare `supported_targets = "all"`), but the
DOM layer (`luna/src/dom`) is JS-only, and the published npm package targets JS.
The wasm-gc story is not something this page can benchmark yet.

## Environment

All figures on this page were measured on:

- Linux x86-64, Intel Xeon @ 2.10 GHz, 4 vCPU (containerised)
- Node.js v22.22.2
- Vitest 4.1.10, headless Chromium via Playwright
- esbuild 0.28.1 (bundle measurements)
- moon 0.1.20260904 / moonc v0.10.12
- React 19.2.7 + ReactDOM 19.2.7, Preact 10.29.5

Re-run everything with:

```sh
node luna/scripts/treeshake-size.mjs --check
node luna/scripts/preact-size-compare.mjs --build
node luna/scripts/runtime-bench.mjs
node luna/scripts/moonbench-check.mjs --check
moon test --target js -p mizchi/luna/_bench
pnpm test:bench
```
