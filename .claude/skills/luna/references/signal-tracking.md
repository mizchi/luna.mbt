# luna signal tracking — `untracked` and `batch`

> Reference page for the unified `luna` skill. Read this when an effect / route
> renderer re-runs on signal changes that should be local to a child component,
> or when grouped `signal.set()` calls fire too many effect runs.

## Why this matters

luna's reactivity is fine-grained: any `Signal::get()` that runs while an
`effect` / `render_effect` / route effect is *being defined* gets registered
as a dependency. Component construction in luna reads child signals during
initial render (e.g. `text_dyn(fn() { count.get() })` evaluates the closure
once during build to know what to render), so a route-level effect that
builds a component tree containing a counter ends up subscribed to the
counter signal — every counter click triggers a full route rebuild.

The fix is `@resource.untracked(fn() { ... })` around component construction.

Concrete artifacts to mirror:
- `luna/src/examples/browser_router/main.mbt:432-466` — router effect with `untracked` around `nav` / `page` / `app` construction
- `luna/src/examples/wiki/main.mbt:247-278` — same shape, sidebar + content
- `luna/src/_bench/dom_bench.mbt:247` etc. — batched writes example

## When this applies

- An effect / route renderer re-runs on signal changes that should be local to a child component
- Symptom: "navigate works, but typing in an input on page A also clears and rebuilds page A"
- Symptom: nested `Show` causes infinite re-render
- Adding a new top-level `@resource.effect` in luna that constructs DOM / VNodes inside its body
- Multiple correlated `signal.set()` calls fire too many effect runs (e.g. setting `a`, `b_`, `c` triggers 3 effects instead of 1)
- Reviewing a PR that adds a new browser router or a new top-level renderer

## Pattern 1 — Router / top-level renderer: `untracked` around component construction

The effect should depend on **only** the signals that decide *what* to render
(route match, page id, mode flag). Constructing the actual VNode tree must
not introduce new dependencies.

```moonbit
let _ = @resource.effect(fn() {
  // INTENTIONAL deps: things that should re-trigger the route effect
  let match_result = router.match_signal().get()
  let path = router.path_signal().peek()        // peek = read without subscribing
  console_log("Route changed: " + path)

  clear(container)

  // UNTRACKED: component bodies read their own internal signals. Without
  // untracked, those reads propagate back to this effect.
  let (nav, page) = @resource.untracked(fn() {
    let nav = nav_component(router)
    let page = match match_result {
      Some(m) => resolve_component(router, m)
      None => not_found_component(router)
    }
    (nav, page)
  })

  // Layout assembly also calls element factories — keep it under untracked.
  let app = @resource.untracked(fn() {
    div(class="app") <| [ nav, div() <| [ page ] ]
  })

  mount(container, app)
})
```

Two extra rules from the `browser_router` example:

- Use `signal.peek()` (not `get()`) for signals you want to *read* in the effect but not *subscribe to*.
- Don't wrap `clear(container)` / `mount(container, app)` in `untracked` — those are pure DOM mutations and don't read signals; wrapping them just adds noise.

## Pattern 2 — Grouped writes: `batch`

When you set multiple signals in sequence and they all feed the same effect, wrap the writes:

```moonbit
@resource.batch(fn() {
  a.set(1)
  b_.set(2)
  c.set(3)
})  // -> one effect run, not three
```

This is most visible in `_bench/dom_bench.mbt` (`dom_batched_3_updates`) and
`_bench/signals_bench.mbt`. Use it whenever a user action produces multiple
correlated state changes (form submit clearing input + advancing index +
appending log, etc.).

## API quick reference (re-exported via `mizchi/luna`)

| Function | Use for |
|---|---|
| `@resource.signal(initial)` | Reactive cell |
| `@resource.memo(fn)` | Cached derived value, re-computes only when reads change |
| `@resource.effect(fn)` | Side-effect that re-runs when its tracked reads change |
| `@resource.render_effect(fn)` | Synchronous DOM-update effect (used inside luna's own `Show`/`For`) |
| `@resource.untracked(fn)` | Run `fn` reading signals **without** subscribing the surrounding effect |
| `@resource.batch(fn)` | Defer effect runs until `fn` returns; collapses multiple writes |
| `Signal::peek()` | Read current value without subscribing |
| `@resource.on_cleanup(fn)` | Register a teardown for the current owner |

## Pitfalls

- **Don't put intentional deps inside untracked.** If you wrap `match_signal().get()` in `untracked`, the effect will only fire once and route changes won't re-render. The intentional `get()` calls live *outside* `untracked`.
- **Don't reach for `untracked` to silence warnings.** If a `Signal::get()` is firing your effect when it shouldn't, first ask whether the signal even belongs in this effect's body. Often the right answer is to move the read into a memoized child component, not to wrap it.
- **`render_effect` is for primitives (Show, For, render_to)**, not app-level code. App authors should default to `effect`. Reaching for `render_effect` usually means you're rebuilding a primitive that already exists — check `luna/src/dom/render.mbt` first.
- **Don't `batch` event handlers that already produce one update.** A click handler that calls `count.update(n => n + 1)` once doesn't need batching; the cost (function allocation + bookkeeping) is real.
- **Component bodies are evaluated lazily for `text_dyn` / `attr_dynamic` but eagerly for static reads.** A `let label = sig.get()` at the top of a component body subscribes the surrounding scope. If you're trying to break a tracking chain and the wrapper above is already `untracked`, make sure you're not moving the read out of it accidentally.

## Verification recipe

Before claiming the fix works:

1. Add a `console_log("route effect fired")` at the top of the route effect body
2. Click a counter / toggle a local Island state
3. The log should fire **only on actual route navigation**, not on local state changes

If the log fires on local-state changes, the `untracked` boundary still has a `get()` outside it.

## Related

- `luna/spec/001-signal-system.md` — ADR for the reactive system (high-level rationale, no usage rules)
- `luna/src/dom/render.mbt` — luna's `Show`/`For`/`Loading` primitives, all use `untracked` internally; reference when building a new primitive
- `mizchi/signals` mooncake — the underlying reactivity engine; luna re-exports its surface through `@resource`
