---
name: playwright-pnpm-workspace
description: Use when running Playwright tests in this repo (luna.mbt) and either the test fails to discover specs ("did not expect test.describe()" / "two different versions of @playwright/test") or you're adding a new playwright config under astra/ or sol/. Captures the version-skew between root and per-package @playwright/test pins.
---

# playwright-pnpm-workspace

## Purpose

luna.mbt root pins `@playwright/test@^1.58.2`, but `astra/package.json` and `sol/package.json` independently pin `^1.59.1`. Running `pnpm exec playwright` from the repo root resolves the older root-level version, while spec files imported from `astra/e2e/` or `sol/e2e/` resolve the newer per-package one. Playwright crashes with "did not expect test.describe()" because the registered test type and the discovered file disagree on which copy of `@playwright/test` they're holding.

This skill records which command to use for which directory and avoids burning a CI cycle on a version-skew bug.

## When to use

- Adding or running a playwright config under `astra/e2e/` or `sol/e2e/`
- Seeing `Playwright Test did not expect test.describe() to be called here` at test discovery
- Adjusting `@playwright/test` versions across the monorepo
- Wiring a new `just test-…` recipe that drives playwright

## Workflow

### Pick the runner based on where the spec lives

| Specs in | Use this command | Why |
|---|---|---|
| `luna/e2e/**` | `pnpm exec playwright …` (from repo root) | `luna/` is not a separate workspace package; tests resolve through root's `@playwright/test@1.58.2`. |
| `astra/e2e/**` | `cd astra && pnpm exec playwright …` *or* `pnpm -F @mizchi/astra-e2e exec playwright …` | `astra/package.json` pins 1.59.1; root's 1.58.2 will crash. |
| `sol/e2e/**` | `pnpm -F @luna_ui/sol-workspace exec playwright …` | `sol/package.json` pins 1.59.1 too. `cd sol` is unreliable here because zsh redirects `sol` to a sibling repo via `hash -d`. |

Wired examples in `justfile`:

```just
test-deployed-luna:
    pnpm playwright test --config luna/e2e/deployed/playwright.config.mts

test-deployed-website:
    cd astra && pnpm exec playwright test --config e2e/deployed/playwright.config.mts

test-sol-chaos:
    pnpm -F @luna_ui/sol-workspace exec playwright test --config "$(pwd)/sol/e2e/playwright-sol-app-chaos.config.mts"
```

The `$(pwd)/...` absolute path on `test-sol-chaos` is intentional — `pnpm -F` runs in the workspace's own cwd, so a relative config path would resolve wrong.

### Adding a new playwright config

1. Decide which package owns the spec (root / astra / sol). The package that owns it sets which `@playwright/test` version applies.
2. If the new config lives under an existing playwright config's `testDir`, add the new path to the existing config's `testIgnore` so the original suite doesn't accidentally pick it up.
3. Add a `just test-…` recipe matching the runner table above.
4. Run locally before pushing. CI cycles on this kind of bug are expensive (only luna-e2e fails, the rest pass — easy to misdiagnose).

### Symptoms of skew

- `Playwright Test did not expect test.describe() to be called here` — you're running with the wrong `@playwright/test` for the test file.
- `Error: No tests found` after the above — same root cause; playwright bailed before discovery completed.
- A test suite under `astra/e2e/deployed/` *passes locally* but the `luna-e2e` CI job fails referencing the same file — the localhost playwright config is also picking up the deployed/ specs because of glob-greedy `testMatch`. Add `testIgnore: ["**/deployed/**"]`.

## Pitfalls

- **`cd sol`** in zsh on this machine redirects to `~/ghq/github.com/mizchi/sol.mbt` (a sibling repo), not `luna.mbt/sol/`. Use `pnpm -F` instead, or absolute paths.
- **`testMatch` is rooted at `testDir`** but `**` globs cross subdirectories. A new sibling dir under an existing `testDir` will be picked up unless explicitly ignored.
- **Don't unify versions casually.** Bumping root to 1.59.1 looks tempting, but `vitest-browser` (root devDep) currently pulls in `@vitest/browser-playwright@4.0.18` which has its own playwright peer constraint. Check the unmet-peer warnings before dragging the root version forward.
- **`pnpm -F` runs in the package's cwd.** Relative `--config` paths won't resolve as you expect when the package is nested. Pass an absolute path (`$(pwd)/sol/e2e/...`) or `cd` into the package first.

## Related

- `luna/e2e/playwright.config.mts`, `astra/e2e/playwright.config.mts`, `sol/e2e/playwright.config.mts` — the three roots; each ignores `**/deployed/**` (and luna's also ignores `**/visual-snapshots.test.ts` in CI).
- `justfile` — the canonical recipes.
