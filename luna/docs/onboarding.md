# Luna Onboarding

For someone touching `mizchi/luna` for the first time. The goal is a working
mental model — not an API reference. After reading this you should be able to
look at a piece of luna code and know which layer it lives in.

## What luna is

Luna is a fine-grained reactive UI primitive for MoonBit (and, via JS bindings,
for TypeScript). Three traits to anchor on:

1. **Fine-grained, not VDOM-diffed.** A `Signal` read inside `text_dyn(...)`
   subscribes that text node directly. When the signal changes, that one text
   node updates. Closer to SolidJS / Svelte runes than to React.
2. **VNode is an *abstract* tree, not a virtual DOM.** The same VNode renders
   to a real browser DOM (`@dom`), to an HTML string for SSR (`@dom.static`),
   or to a streaming response (`@core.stream_render`). The tree itself
   carries no diff logic — reactivity does the updates.
3. **Luna doesn't do server / routing / SSG.** Those live in sibling mooncakes
   (`sol`, `astra`). Luna provides the primitives those packages compose with.

## Layers (this is the mental model)

```
   ┌───────────────────────────────────────────────────┐
   │ App code (your example, sol pages, astra docs)    │
   └───────────────────────────────────────────────────┘
                        │ imports
   ┌───────────────────────────────────────────────────┐
   │ Public surface (re-exported from `mizchi/luna`)   │
   │   @resource    signals: signal/memo/effect/...    │
   │   @element     CSR DSL: div/p/text_dyn/events/... │
   │   @dom.static  SSR DSL: ServerNode/island/...     │
   │   @router      BrowserRouter (CSR routing)        │
   │   @portal      portal_to_body (modals)            │
   │   @css         atomic CSS utility (build-time)    │
   └───────────────────────────────────────────────────┘
                        │ wraps
   ┌───────────────────────────────────────────────────┐
   │ Internal core (luna/src/core/, luna/src/dom/)     │
   │   VNode types, render, hydrate, stream_render,    │
   │   reconciler, routes compiler                     │
   └───────────────────────────────────────────────────┘
                        │ depends on
   ┌───────────────────────────────────────────────────┐
   │ mizchi/signals — the reactivity engine            │
   └───────────────────────────────────────────────────┘
```

You will rarely need to read the internal core. The public surface is what
sol, astra, and your own app code touch.

## Where things live in this repo

| Directory | What | Touch when |
|---|---|---|
| `luna/src/core/` | VNode, render, routes, serialize, stream_render | Building a new render target, or changing what a VNode is |
| `luna/src/dom/` | Browser DSL: `@element`, `@dom.static`, hydrate, router, portal | Writing CSR / SSR component code, or adding a DOM primitive |
| `luna/src/js/` | Re-export shims that present the underlying `mizchi/signals` API as `@resource` | Almost never — it's a thin layer |
| `luna/src/x/css/` | Atomic CSS utility (DJB2-hashed class names, build-time extraction) | Adding new styles to SSR components |
| `luna/src/x/stella/` | Shard generator (hydratable HTML fragment with `luna:*` attrs) | Internal — sol/astra emit Islands through this |
| `luna/src/x/testing/` | DOM-less VNode unit-test helpers | Writing component tests |
| `luna/src/examples/` | Runnable CSR demos (deploy to `luna-examples.mizchi.workers.dev`) | Showing off a feature; reference for new user code |
| `luna_components/` | APG-compliant headless+styled UI components (separate mooncake) | Picking up pre-built buttons / dialogs / etc. |
| `js/luna/` | TypeScript bindings + vite plugin (npm: `@luna_ui/luna`) | TS-side consumers |

`sol/` and `astra/` are siblings, not under luna. They use luna; luna doesn't
know about them.

## The smallest luna program

```moonbit
// luna/src/examples/hello_luna/main.mbt (abridged)
using @element { div, p, button, text, text_dyn, render_to, events, type DomNode }
using @resource { signal }

fn counter() -> DomNode {
  let count = signal(0)
  div() <| [
    p()                                                    <| [ text_dyn(fn() { "Count: " + count.get().to_string() }) ],
    button(on=events().click(fn(_) { count.update(n => n + 1) })) <| [ text("+") ],
  ]
}

fn main {
  match @dom.document().getElementById("app") {
    Some(el) => render_to(el, counter())
    None    => println("missing #app")
  }
}
```

Three things to notice:

- `signal(0)` returns a `Signal[Int]`. `count.get()` reads it; calling `.get()`
  inside a closure passed to `text_dyn` is what subscribes that text node.
- `div() <| [...]` is the children-application operator. The DSL is plain
  MoonBit; there is no template language.
- `events().click(fn)` builds an event handler. `events()` is a builder; `.click`,
  `.input`, `.submit` etc. all return something compatible with the `on=...`
  argument of element factories.

This file is paired with a `moon.pkg` that declares the JS target and is-main,
plus an `index.html` that loads the moon-built JS. The full set of files
required for a new example is in `.claude/skills/luna-csr-app-scaffolding/`.

## CSR vs SSR vs Island — when does each apply

- **CSR (`@element`, `@dom`)**: The whole tree is built and rendered in the
  browser. Examples in `luna/src/examples/*` are CSR.
- **SSR (`@dom.static`, `@core.render`)**: The tree is rendered to an HTML
  string on the server. Sol and astra both use this for their initial-HTML
  responses. The output is pure HTML — no luna runtime in the page.
- **Island**: SSR with a hydratable boundary. The server emits HTML +
  `luna:id` / `luna:url` markers; the loader script in the page fetches the
  Island's JS and `hydrate()`s the marked subtree. App authors don't write
  Island plumbing directly — sol's `island(component_ref)` helper does it.

If you're writing pure CSR (a luna example, a small SPA), you'll never see
SSR or Island APIs. If you're writing a sol page, you're writing SSR by
default and opt into Islands as needed.

## What is *not* in luna

- No file-based routing — that's sol.
- No static-site generation — that's astra.
- No bundler — vite (with `vite-plugin-moonbit` and `lunaCss`) builds luna
  examples; `astra build` builds docs sites.
- No CSS-in-JS runtime — `@css.css(...)` produces a class name and a CSS rule
  is extracted at build time. The runtime is just a string.

## Where to read next

In rough order of usefulness for a newcomer:

1. **`luna/src/examples/hello_luna/`** — minimum running example. ~40 lines.
2. **`luna/src/examples/spa/`** — covers `memo`, `effect`, `show`, `for_each`,
   `portal`. The "I want to see most of the API in one file" example.
3. **`luna/src/examples/browser_router/`** — CSR routing + the `untracked`
   pattern. Read `.claude/skills/luna-signal-tracking/SKILL.md` alongside it.
4. **`luna/spec/`** — five short ADRs (signal system, CSS utility, VNode
   abstraction, hydration, web components). For *why* the design is what it is.
5. **`luna/src/x/css/README.md`** — atomic CSS utility, including the rule
   that only string-literal calls are extracted.
6. **`luna/src/dom/render.mbt`** — luna's own `Show` / `For` / `Loading`
   primitives. Read this if you're adding a new render primitive; it's the
   reference for how `untracked` and `render_effect` cooperate.

Sibling onboarding docs:

- `../sol/docs/onboarding.md` — sol (SSR framework) bootstrap.
- `../astra/README.md` — astra (mountable SSG middleware) usage.

## Repo-wide commands relevant to luna

```sh
moon check --target js                # workspace-wide check (luna + sol + astra + luna_components)
moon test --target js                 # workspace test (must stay 2794 PASS)
pnpm --filter ./luna dev              # vite dev for luna examples (port 4100)
pnpm --filter ./luna build            # vite prod build to luna/dist/
node luna/scripts/build-demo.mjs      # static bundle to luna/dist-demo/ for the Cloudflare Workers deploy
pnpm test:browser                     # vitest browser runner (js/luna)
pnpm test:e2e                         # playwright (luna's own e2e — see playwright-pnpm-workspace skill)
```
