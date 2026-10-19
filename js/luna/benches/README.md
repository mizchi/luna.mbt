# Runtime and browser benchmarks

Run from the workspace root:

```sh
just browser-bench
just browser-bench js/luna/benches/grid.bench.ts
just browser-bench --reporter=json --outputFile.json=/tmp/browser-bench.json
just runtime-bench
just moonbench-check
moon bench --target js -p mizchi/luna/_bench -f hydrate_bench.mbt
```

The browser suite has 66 timed workloads and 13 correctness/clock checks. It uses
the Vitest 5 test-context benchmark API, production React/Preact bundles and
cross-origin isolation for a high-resolution clock. Each workload has 20 warmup
iterations and 100 measured iterations. Fixture setup, DOM checks in teardown, and
teardown are outside the timer. Initial mounts and list updates start from a fresh
fixture every iteration; lists cannot grow between samples. Preact updates flush
synchronously, and grid classes/list lengths are checked before cleanup.

Grid inputs are deterministic and identical across renderers. Each frame is 90%
empty, with the remaining cells split between four occupied states. A whole-array
update changes 20% of cell classes and notifies all 2,500 dynamic attribute
subscribers in the Luna fixture. This measures that application pattern rather
than updates to independent per-cell signals.

## Measurements

2026-10-19, macOS arm64, Node v24.21.0, Chromium 156.0.8078.4. Versions: Luna
0.24.0 workspace build, Preact 11.0.1, React 19.3.1, Vitest 5.0.5. Browser values
below are p50 milliseconds for one workload, including any loops named in it.

| Workload | Luna | Preact | React |
| --- | ---: | ---: | ---: |
| Update array-backed 2,500-cell grid | 1.483 | 0.390 | 0.275 |

The grid update is a candidate for profiling signal fanout and dynamic attribute
updates. The previous browser harness did not run with Vitest 5 and its Preact
update cases did not wait for a DOM commit, so those old results cannot establish
a performance regression or improvement.

| Luna workload | p50 ms |
| --- | ---: |
| Static 5,000-cell mount | 0.820 |
| Add 100 items to a 1,000-item list | 0.170 |
| Toggle Show 1,000 times | 0.255 |
| Update a 1,000-item For list 100 times | 6.650 |
| Deferred Show and 50-line update | 0.025 |

The deferred case waits for its mount/effect microtasks and checks all 50 lines;
its former fixed 10 ms sleep obscured the actual work. WC cases now construct and
check all five/ten nested shadow roots, and the declarative case attaches real
shadow roots with `setHTMLUnsafe`. WC workloads include construction, registration
and cleanup; they do not isolate event dispatch or selector latency. CSS cases
exercise DOM/CSSOM patterns, not the Luna CSS compiler or third-party CSS engines.

The Node signal benchmark and seven MoonBit SSR/serialization baseline checks
pass. Their committed historical baselines were measured on Linux x64, so local
macOS timings do not establish an application speedup. The 17 JSDOM hydration
benchmarks also pass with recovery disabled and success required. Their times
include restoring the SSR fixture through `innerHTML`: a 100-item list is about
287 µs, and a 50-card page fragment is about 935 µs. The old document-level page
fixture fell back to rerendering and must not be used as a hydration baseline.
