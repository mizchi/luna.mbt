# Adding a new CSR example to `luna/src/examples/`

> Reference page for the unified `luna` skill. Read this when adding a new
> CSR-only example under `luna/src/examples/<name>/` (for `pnpm dev` and the
> `luna-examples.mizchi.workers.dev` deploy), or debugging why a freshly
> created example isn't picked up by vite / `build-demo.mjs`.

## Why this matters

A new CSR example is **not** discovered automatically. Three files go in the
new example directory and three existing files must be edited — miss any one
and the symptom is different (vite 404, `pnpm build` skips it, deploy bundle
has 6 examples instead of 7, or the landing page link 404s). This page
records the full checklist so a single PR adds the example end-to-end.

Concrete artifacts the new example must integrate with:
- `luna/vite.config.ts:48-60` — `rollupOptions.input` controls which examples vite **builds** in prod
- `luna/scripts/build-demo.mjs:35-78` — `examples[]` controls which examples ship to Cloudflare Workers
- `luna/index.html:69-118` — landing page `<ul class="demo-list">` controls which examples a human can find

A clean reference example with no extra deps is `luna/src/examples/hello_luna/`.

## When this applies

- Adding a new luna example (e.g. "i wrote a new luna demo for X, please integrate it")
- A pasted-in example shows up in `luna/src/examples/<name>/` but `pnpm dev` 404s on it
- `pnpm build` succeeds but `dist-demo/` is missing the new example
- Reviewing a PR that adds an example — verify all 6 touchpoints are present

## Files to create (3)

All paths are under `luna/src/examples/<name>/`. **`<name>` must be a valid
mooncake package name segment**: lowercase, ASCII, underscores allowed, no
hyphens (apg-playground is the lone exception, lives under `luna_components`
not luna because of the dash).

### 1. `moon.pkg`

```
import {
  "mizchi/luna/js/resource" @resource,
  "mizchi/signals",
  "mizchi/luna/dom" @element,
  "mizchi/js/core" @js,
  "mizchi/js/browser/dom" @dom,
  "mizchi/js/builtins/global",
}

supported_targets = "js"

options(
  "is-main": true,
  link: { "js": { "format": "esm" } },
)
```

Three lines that **must** be present:
- `supported_targets = "js"` — moonbit's "all" default builds wasm too, which then fails on browser-only deps
- `"is-main": true` — without this, moon doesn't emit a `main` symbol and the `<script>` tag loads an inert module
- `link.js.format: "esm"` — without this, moon emits CommonJS which the browser `<script type="module">` rejects

Add additional imports as the example needs them:
- Browser router: `"mizchi/luna/dom/router" @router`, `"mizchi/luna/core/routes"`
- Portal (modals): `"mizchi/luna/dom/portal"`
- Web Components shadow registration: `"mizchi/luna/x/luna_api" @luna_api`, `"mizchi/luna" @luna`
- CSS utility: `"mizchi/luna/x/css" @css`

### 2. `main.mbt`

Minimum skeleton (uses `@element` and `@resource` from the imports above):

```moonbit
using @element {
  div, p, button, text, text_dyn, render_to,
  events,
  type DomNode,
}

using @resource { signal }

fn counter() -> DomNode {
  let count = signal(0)
  div() <| [
    p() <| [ text_dyn(fn() { "Count: " + count.get().to_string() }) ],
    button(on=events().click(fn(_) { count.update(fn(n) { n + 1 }) })) <| [
      text("Increment"),
    ],
  ]
}

fn main {
  let doc = @dom.document()
  match doc.getElementById("app") {
    Some(el) => render_to(el, counter())
    None => println("Error: #app element not found")
  }
}
```

Key points: `fn main { ... }` (no parens, no `-> Unit`), `#app` element id (the HTML below uses it), and `render_to` from `@element`.

### 3. `index.html`

Copy verbatim from `luna/src/examples/hello_luna/index.html` and replace **two** occurrences of `hello_luna` with `<name>` in the `releaseModule` / `debugModule` paths:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><Name> — Luna Example</title>
  <script>
    const loadModule = (src) =>
      new Promise((resolve, reject) => {
        const script = document.createElement("script");
        script.type = "module";
        script.src = src;
        script.onload = () => resolve();
        script.onerror = () => reject(new Error(`Failed to load module: ${src}`));
        document.head.appendChild(script);
      });

    const isViteDev = Boolean(document.querySelector('script[src="/@vite/client"]'));
    const releaseModule = "../../../_build/js/release/build/examples/<name>/<name>.js";
    const debugModule = "../../../_build/js/debug/build/examples/<name>/<name>.js";
    const primaryModule = isViteDev ? debugModule : releaseModule;
    const fallbackModule = isViteDev ? releaseModule : debugModule;
    loadModule(primaryModule).catch(() => loadModule(fallbackModule));
  </script>
</head>
<body>
  <div id="app"></div>
</body>
</html>
```

The `loadModule` block is matched verbatim by `build-demo.mjs:rewriteExampleHtml` (`pattern` regex on line 83). Change its shape and the build will throw `loadModule(primaryModule) script block not found`.

## Files to register (3)

### 4. `luna/vite.config.ts`

Add a line under `build.rollupOptions.input`:

```ts
<name>: resolve(rootDir, 'src/examples/<name>/index.html'),
```

Without this, `pnpm build` (vite prod build) skips the example silently.

If the example uses `@css` utility, also add the directory to `lunaCss({ src: [...] })`.

### 5. `luna/scripts/build-demo.mjs`

Append an entry to the `examples` array:

```js
{
  id: "<name>",
  mooncake: "luna",  // or "luna_components" if it lives there
  title: "<Name>",
  desc: "<one-line description>",
},
```

`mooncake` selects which `_build/js/release/build/mizchi/<mooncake>/examples/...` tree to read from. For luna's own examples this is always `"luna"`.

### 6. `luna/index.html`

Append a `<li class="demo-item">` to the `<ul class="demo-list">` block:

```html
<li class="demo-item">
  <a href="./src/examples/<name>/" class="demo-link">
    <div class="demo-title"><Name></div>
    <div class="demo-desc"><one-line description></div>
  </a>
</li>
```

`build-demo.mjs:rewriteLanding` rewrites `./src/examples/<name>/` → `./<name>/` automatically when shipping the static bundle, so the same href works for both dev and prod.

## Verification recipe

```sh
# From repo root
moon check --target js                  # 0 errors (594 warnings is the current baseline)
moon build --target js --release        # produces _build/js/release/build/mizchi/luna/examples/<name>/<name>.js
ls _build/js/release/build/mizchi/luna/examples/<name>/<name>.js
pnpm --filter ./luna dev                # vite dev: visit http://localhost:4100/src/examples/<name>/
pnpm --filter ./luna build              # vite prod build: dist/<name>/index.html should exist
node luna/scripts/build-demo.mjs        # static bundle: dist-demo/<name>/{index.html,index.js}
ls luna/dist-demo/<name>/
```

If `build-demo.mjs` fails with `Missing build artifact`, you skipped the `moon build --target js --release` step — moon outputs only the artifacts you ask for, nothing is autobuilt.

## Pitfalls

- **Don't use a hyphenated `<name>` for a luna-side example.** moon package paths use `/` and the dir name maps to the package id. apg-playground gets away with it because it lives in `luna_components` and stayed for historical reasons. New examples should use snake_case.
- **Don't change the `loadModule(primaryModule)` script block shape** in `index.html`. `build-demo.mjs:rewriteExampleHtml` matches it with a regex and rewrites the whole block to a single `<script src="./index.js">` for the static deploy. Reformatting it (extra newline, different variable names) will make the build script throw.
- **Don't hard-code `/demo/<name>` in code that has to work in dev too.** vite serves at `/`, the static deploy serves at `/<name>/`. `browser_router` dodged this by hard-coding `/demo/browser_router` and `build-demo.mjs:139` patches the compiled JS to swap it. Prefer reading the base from `window.location` if you need it.
- **Don't forget `pnpm install` after a fresh checkout** — `lunaCss` is imported from `../js/luna/dist/vite-plugin.js`, so the js/luna build must have run. `pnpm install` triggers it; if it didn't, run `pnpm --filter @luna_ui/luna build` once.
- **The deployed worker URL is `https://luna-examples.mizchi.workers.dev/<name>/`.** Deploy is via `wrangler deploy` from `luna/`; the deploy is triggered by the website CI workflow (or manually). After adding an example, you don't have to deploy in the same PR — just merging adds it to the next deploy.

## When the example needs more than CSR

This page covers **vanilla CSR**: signals + DOM, no SSR, no hydration, no per-page bundling beyond what vite gives you. If the example needs:

- **Browser routing** → `examples/browser_router/` is the reference. Add `@router` / `@routes` imports to `moon.pkg`. Read `references/signal-tracking.md` before writing the route effect.
- **Web Components** → see `examples/wc/` (shadow DOM via `@luna_api.register_shadow`) or `examples/wc_counter/` (`wc.json` + `setup`/`template`).
- **Atomic CSS via `@css.css(...)`** → also wire `lunaCss({ src: ['src/examples/<name>'] })` in `vite.config.ts:20`.
- **Markdown / MDX / SSR** → wrong package. Use sol or astra — luna examples are CSR-only by convention.
