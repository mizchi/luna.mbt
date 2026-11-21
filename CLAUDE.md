# luna.mbt — Agent Notes

## TODO: finish the release migration (delete this section when done)

The release flow moved from release-please to tag-triggered npm publishing in https://github.com/mizchi/luna.mbt/pull/133. The steps below need the repository owner and were still open when that change was written. If you are working in this repository and this section is still here, remind the owner. Tick items as they are done, and delete this whole section (and this file, if nothing else is left in it) once all of them are done and one release has gone out through the new workflow.

- [ ] Protect release tags: `protect-tags.sh --pattern '*-npm-v*' mizchi/luna.mbt` (npm-release skill)
- [ ] `npm trust list @luna_ui/luna`; if `publish.yml` is not listed: `npm trust github @luna_ui/luna --repo mizchi/luna.mbt --file publish.yml --allow-publish -y`
- [ ] `npm trust list @luna_ui/sol`; if `publish.yml` is not listed: `npm trust github @luna_ui/sol --repo mizchi/luna.mbt --file publish.yml --allow-publish -y`
- [ ] `npm trust list @luna_ui/astra`; if `publish.yml` is not listed: `npm trust github @luna_ui/astra --repo mizchi/luna.mbt --file publish.yml --allow-publish -y`
- [ ] `npm trust list @luna_ui/components`; if `publish.yml` is not listed: `npm trust github @luna_ui/components --repo mizchi/luna.mbt --file publish.yml --allow-publish -y`
- [ ] `npm trust list @luna_ui/luna-loader`; if `publish.yml` is not listed: `npm trust github @luna_ui/luna-loader --repo mizchi/luna.mbt --file publish.yml --allow-publish -y`
- [ ] `npm trust list @luna_ui/stella`; if `publish.yml` is not listed: `npm trust github @luna_ui/stella --repo mizchi/luna.mbt --file publish.yml --allow-publish -y`
- [ ] `npm trust list @luna_ui/testing`; if `publish.yml` is not listed: `npm trust github @luna_ui/testing --repo mizchi/luna.mbt --file publish.yml --allow-publish -y`
- [ ] `npm trust list @luna_ui/wcr`; if `publish.yml` is not listed: `npm trust github @luna_ui/wcr --repo mizchi/luna.mbt --file publish.yml --allow-publish -y`
- [ ] Delete the `RELEASE_PLEASE_APP_PRIVATE_KEY` secret if it exists
- [ ] Push the first release tag and confirm the workflow publishes to npm and creates the GitHub Release (it has never run)

GitHub creates no push event when more than three tags are pushed at once, so push at most three tags per `git push`. Push a dependency tag (wcr, luna) and wait for it before its dependents (stella, testing). The existing `just changelog` recipes now pick up the new root `cliff.toml` and would overwrite the root `CHANGELOG.md`; they need a follow-up.

Monorepo for six MoonBit packages plus their npm wrappers. Each
mooncake publishes independently but lives and is tested together.

## Layout

| Path | Mooncake / npm | Role |
|------|----------------|------|
| `luna/`  | `mizchi/luna`  / `@luna_ui/luna`  | UI primitives — VDOM, hydration, stream renderer, Island runtime, signals, vite plugin |
| `luna_components/` | `mizchi/luna_components` / `@luna_ui/components` | Headless and styled UI components |
| `sol/`   | `mizchi/sol`   / `@luna_ui/sol`   | SSR framework over Mars (file-based routes, CLI under `sol/src/cmd/sol`) |
| `sol_adapter_cloudflare/` | `mizchi/sol_adapter_cloudflare` / n/a | Cloudflare/Wrangler adapter utilities for Sol; depends on Sol, never the other way around |
| `sol_adapter_node/` | `mizchi/sol_adapter_node` / n/a | Node.js adapter utilities for Sol |
| `astra/` | `mizchi/astra` / `@luna_ui/astra` | Mountable Mars middleware for SSG (CLI under `astra/src/cmd/astra`) |

`moon.work` ties the six libraries and 15 examples together, plus `website/` — a docs-only
module (`mizchi/luna_docs`) whose `.mbt.md` pages carry compiled sample
code. Run `just generate-examples` before calling `moon` in a fresh checkout;
`just check` and `just test-moonbit` do this automatically. The JS checks cover
the libraries, docs, and JS examples; `just test-workspace` also checks the
Wasm island example with `wasm-gc`. The browser runner in `sol/e2e/mbt_e2e`
is a separate module. `js/*`
holds the npm wrappers — most are thin re-exports; `js/luna` is the real
npm artifact (built by tsdown).

Other top-level dirs:
- `js/` — TS bindings + npm wrappers (`@luna_ui/{luna,sol,astra,components,loader,stella,testing,wcr,wcssr}`)
- `tests/integration/` — cross-package smoke tests (`pnpm test:integration`)
- `website/` — monorepo docs site, built with `astra build`
- `docs/`, `scripts/` — repo-wide notes + coverage tool
- See root `README.md` for the public-facing story.

CHANGELOGs are per-package: `luna/` (only this one currently has cliff
config — `luna/cliff.toml`), `sol/CHANGELOG.md`, `astra/CHANGELOG.md`.

## Commands

`just --list` enumerates everything. The ones an agent normally needs:

```sh
just check          # moon check --target js --deny-warn (workspace-wide)
just fmt            # moon fmt
just test-moonbit   # moon test --target js (baseline: 2943 passing tests)
just test-workspace # manifests + standalone checks for all 15 examples
just test-vitest    # node + browser vitest (luna)
just test-e2e       # playwright (luna)
pnpm test:integration   # cross-package smoke (build/dev parity + 15-example matrix)
```

Coordinated bumps:
```sh
node luna/scripts/vup.mjs --dry-run patch   # preview
just vup patch                              # bump + per-package CHANGELOG
just vup patch --release                    # commit + per-pkg tags (idempotent: reuses the pending bump above)
```
`vup` is idempotent on semver bumps: if `moon.mod` in the working tree
is already ahead of HEAD, `--release` will NOT bump again — it will commit
and tag the pending version. So the two-step flow above is safe, and so is
running `just vup patch --release` directly from a clean tree.
The script bumps the 6 mooncake manifests (`luna`, `luna_components`,
`sol`, `sol_adapter_cloudflare`, `sol_adapter_node`, `astra`) and the mooncake inter-dep refs.
It synchronizes those dependencies in example manifests while preserving
the examples' own versions.
It also rewrites the version literals embedded in
`sol/src/cli/templates.mbt`, `sol/src/scaffold_templates/templates.mbt`,
and `sol/src/version/version.mbt` so `sol new` scaffolds and the
`sol --version` output stay aligned with the just-bumped versions.
Tags are per-package: `luna-v<v>`, `luna_components-v<v>`, `sol-v<v>`,
`sol_adapter_cloudflare-v<v>`, `sol_adapter_node-v<v>`, `astra-v<v>`.

Mooncake publish after the tags land on origin:
```sh
just release-mooncakes               # publish all 6 in dep-order, moon update between each
just release-mooncakes --dry-run     # preview the publish plan
```
`moon update` between each `moon publish` is required: without it, the
next package's dep resolver still sees the old version in the local
registry index and the publish fails ("no version satisfies …"). The
`scripts/release-mooncakes.sh` helper handles the order and the index
refresh.

CLI installs (mooncakes):
```sh
moon install mizchi/sol/cmd/sol
moon install mizchi/astra/cmd/astra
```

npm batch publishing (from the root):
```sh
just test-npm-pack                    # inspect all eight package archives
pnpm publish -r --dry-run             # preview unpublished npm versions
pnpm publish -r                       # or: just release-npm
```
Only the eight tag-released `js/*` packages are public. Keep
examples, internal `@sol/core`, and `js/wcssr` private. Each public package
has a `prepack` build; MoonBit-backed packages build MoonBit first. Use
`workspace:^` for internal npm dependencies; pnpm rewrites them when packing.
Inspect packed manifests when testing registry dependency ranges. CI uses
`pnpm pack` followed by `npm publish <tarball>` for OIDC. npm versions are
independent of Mooncake versions, and recursive publish does not bump them.

npm release (per package, independent versions; CI publishes on tag push):
```sh
(cd js/luna && npm version 0.24.3 --no-git-tag-version)   # bump
just changelog-npm luna 0.24.3                            # add the section to js/luna/CHANGELOG.md
git commit -am "chore(release): @luna_ui/luna 0.24.3"
git tag luna-npm-v0.24.3 && git push origin main luna-npm-v0.24.3
```
Tags are `<component>-npm-v<version>` (`<component>` = npm name without
`@luna_ui/`, so `js/loader` is `luna-loader-npm-v…`). Push at most three tags
per `git push`. `.github/workflows/publish.yml` must keep its filename (npm
trusted publishing is bound to it) and must not receive an npm token. Details:
`docs/internal/npm-release-onboarding.md`.

## Conventions

- Conventional Commits (`feat`/`fix`/`refactor`/`docs`/`chore`/...).
- English for commit messages and public docs.
- JS packages declare `supported_targets = "js"` in `moon.pkg` —
  use the statement form, not the deprecated `options("supported-targets": ...)`.
  `sol/examples/wasm_island_poc` targets `wasm-gc`.
- Keep `moon check --target js --deny-warn` passing. The MoonBit test baseline
  is 2943 passing tests; retain existing coverage when adding or reorganizing tests.
- Code generation: sol's `__gen__/` lives under example projects and
  is regenerated by `sol generate`. Generators live in
  `sol/src/cli/{server,type,hydrate}_generator.mbt` and `templates.mbt` —
  edit them, not the generated output.

## Test pyramid

| Layer | Where | Targets |
|-------|-------|---------|
| MoonBit unit | `*/src/**/*_test.mbt` | Pure logic, no DOM |
| Propagation counts | `luna/src/_bench/propagation_test.mbt` | Reactivity invariants as exact counts (cutoff, glitch-freedom, batching) |
| Doc tests | `website/**/*.mbt.md` | Sample code in the docs site, compiled via ` ```mbt check ` fences |
| Vitest | `js/**/tests/*.test.ts` | DOM, hydration, browser |
| Playwright e2e | `*/e2e/**/*.test.ts` | Full page interaction |
| Integration | `tests/integration/`, `astra/e2e/build_dev_parity.test.js` | Cross-package smoke (`node:test`) |
