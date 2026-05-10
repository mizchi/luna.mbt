---
name: luna
description: Use whenever working with `mizchi/luna` in the luna.mbt repo — writing CSR examples, fixing reactivity bugs (effects re-running on unrelated signal changes), adding new luna features, or onboarding to luna's mental model. This is the unified entry point; pick the right reference page below for the specific situation.
---

# luna (luna.mbt project skill)

## Purpose

`mizchi/luna` is the fine-grained reactive UI primitive that sits under sol
and astra. It's small in surface but easy to misuse in two specific ways
(reactivity tracking, example-pipeline registration) that have already burned
real time in this repo. This skill collects the recovered knowledge as one
entry point so a luna task lands on the right page in one hop.

## When to use

- Writing or modifying any `mizchi/luna` MoonBit code in this repo
- Adding or moving an example under `luna/src/examples/` or `luna_components/src/examples/`
- A luna effect / route / component re-renders on signal changes that should be local
- Onboarding to luna for the first time, or coming back after a long break
- Reviewing a PR that touches luna's public API or examples

## Step 1 — orient (only on first encounter)

Read `luna/docs/onboarding.md` once. It establishes the mental model
(fine-grained reactivity, abstract VNode, no server / routing / SSG inside
luna) and the directory map (luna/src/{core,dom,js,x}, luna_components/,
js/luna/, sol & astra siblings). Skip if you already have that model.

## Step 2 — pick the reference page

Match the situation to one of the pages under `references/`:

| Situation | Reference page |
|---|---|
| "the route effect / a top-level effect re-runs on local state changes", "nested Show infinite loop", "I'm about to write a new top-level `@resource.effect` that builds DOM", "multiple `signal.set()` calls fire too many effect runs" | `references/signal-tracking.md` |
| "add a new example under `luna/src/examples/<name>/`", "vite dev 404s on my new example", "`pnpm build` skips it", "deploy bundle is missing the new example" | `references/csr-app-scaffolding.md` |

If the situation is **outside** both pages (e.g. CSS extraction, web component
authoring, hydration internals), the existing per-module README in
`luna/src/x/<area>/README.md` and the ADRs in `luna/spec/00*-*.md` are the
canonical source — there is no skill page for those areas yet.

## Step 3 — verify before claiming done

The reference pages each include a verification recipe. If the page you
followed didn't, the minimum baseline for any luna change is:

```sh
moon check --target js     # 0 errors (594 warnings is the current baseline)
moon test --target js      # must stay 2794 PASS
```

For CSR example changes, also run the full `moon build --target js --release`
+ `pnpm --filter ./luna dev` + `node luna/scripts/build-demo.mjs` chain in
`references/csr-app-scaffolding.md`. For reactivity changes, use the
`console_log` verification in `references/signal-tracking.md`.

## Related

- `luna/docs/onboarding.md` — newcomer mental model + directory map (Step 1 above)
- `luna/spec/00{1..5}-*.md` — ADRs for signal system, CSS utility, VNode abstraction, hydration, web components
- `luna/src/x/css/README.md` — atomic CSS utility usage rules (string-literal extraction, SSR vs Island placement)
- `luna/src/x/stella/README.md` — Shard / Island fragment generator (sol/astra internal)
- `luna/src/x/testing/README.md` — DOM-less VNode unit-test helpers
- Sibling skills: `sol-cloudflare-deploy`, `playwright-pnpm-workspace` (when the work crosses into sol or e2e tests)
