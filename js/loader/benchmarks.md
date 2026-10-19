# Island lifecycle benchmark

Run from the workspace root:

```sh
just loader-bench
just loader-bench --compare 334855bd --samples 21 --json /tmp/loader-bench.json
```

The benchmark compiles the current shared lifecycle and the implementation at the
selected Git commit with the same Rolldown settings. Both run in the same headless
Chromium page, alternating order per sample. Each sample performs 2,000 DOM updates
and awaits MutationObserver delivery after each update. Fixture setup and final
cleanup are outside the timer; cleanup counts are checked for every sample.

The fixtures use no-op renderers to isolate lifecycle overhead. They do not measure
module download, renderer execution, layout, or whole-page loading. No timing
threshold is added to CI; unit tests enforce that insertions and text-only removals
do not scan all mounted islands.

## Results

2026-10-19, macOS arm64, Node v24.21.0, Chromium 156.0.8078.4. Three warmup samples
and 21 measured samples per case. Comparison commit: `334855bd`.
Values are median milliseconds for 2,000 updates with 1,000 mounted islands.

| Workload | Before | After | Change |
| --- | ---: | ---: | ---: |
| Text replacement outside islands | 18.7 | 1.2 | -93.6% |
| Element insertion outside islands | 18.5 | 1.0 | -94.6% |
| Element replacement outside islands | 19.2 | 19.5 | +1.6% |
| Detach and remount one island | 42.7 | 25.0 | -41.5% |

The observer previously checked every mounted element after every child-list
mutation. It now scans for disconnected islands only when a batch removes an
element, and returns immediately when there are no active mounts. Text removal
and insertion alone cannot disconnect an island. Removing an ancestor still
disposes all islands below it; moving an island within a connected document in the
same batch retains its mount.

At 100 islands, text replacement drops from 2.8 to 1.1 ms and insertion from 2.8 to
0.9 ms. At one island, filtering adds 0.1–0.2 ms across 2,000 updates. Element
removal still performs a full connection scan. The optimization adds 60 gzip bytes
to the WC native ESM dependency graph (1,496 → 1,556 B).
