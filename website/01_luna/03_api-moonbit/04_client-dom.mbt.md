---
title: Client DOM
description: Mounting, events, portals and context from MoonBit
---

# Client DOM

`mizchi/luna/dom` is Luna's client-side renderer — the element DSL, the event
handlers, the portals, and the calls that put a tree into the page. Luna's own
examples import it as `@element`, leaving the default `@dom` alias for the
browser bindings in `mizchi/js_browser/dom`:

```moonbit
import {
  "mizchi/luna/dom" @element,
  "mizchi/luna/js/resource",
  "mizchi/js_browser/dom",
  "mizchi/js/core" @js,
}
```

> This page is a `.mbt.md` file: every ` ```mbt check ` block below is compiled
> by `moon check` and run by `moon test`, so the snippets cannot drift away
> from the API they document. Samples that touch the DOM are written as
> functions inside a test and left uncalled — `moon test` runs under Node,
> which has no `document`, so they are type-checked rather than executed. The
> trailing `let _ = …` is what marks such a function as used.

## Mounting a tree

`render_to` clears the container and then mounts; `mount_to` appends to
whatever is already there. Both take a **built `DomNode`**:

```mbt check
///|
test "render_to mounts a built node into an element" {
  fn hello() -> @element.DomNode {
    @element.div() <| [@element.p() <| [@element.text("Hello, Luna")]]
  }

  fn boot() -> Unit {
    match @dom.document().getElementById("app") {
      Some(el) => @element.render_to(el, hello())
      None => println("Error: #app element not found")
    }
  }

  let _ = boot
}
```

`getElementById` hands you a `@dom.Element`, which is exactly what `render_to`
and `mount_to` want. The `render` / `mount` pair takes Luna's own `DomElement`
wrapper instead, so wrap the element when you reach for those:

```mbt check
///|
test "render takes Luna's DomElement wrapper" {
  fn boot() -> Unit {
    match @dom.document().getElementById("app") {
      Some(el) =>
        @element.render(
          el |> @element.DomElement::from_dom,
          @element.text("Hello, Luna"),
        )
      None => ()
    }
  }

  let _ = boot
}
```

### Signatures

```moonbit
fn render_to(@dom.Element, DomNode) -> Unit   // clear, then mount
fn mount_to(@dom.Element, DomNode) -> Unit    // append
fn render(DomElement, DomNode) -> Unit
fn mount(DomElement, DomNode) -> Unit
fn clear_jsdom(@dom.Element) -> Unit
fn clear(DomElement) -> Unit
```

There is no thunk-accepting form, and none is needed: the second parameter is
typed `DomNode`, so passing a function that *returns* a node is a compile
error rather than a runtime one. The JavaScript API has to accept both shapes
because its `LunaNode` is `unknown` — see [Differences from the JavaScript
API](#differences-from-the-javascript-api).

## Event handlers

`events()` opens a `HandlerMap`, and each handler method chains onto it and
returns the map so the next one can be appended. Pass the result as the `on`
argument of any element in the DSL:

```mbt check
///|
test "events() chains typed handlers onto an element" {
  fn counter() -> @element.DomNode {
    let count = @resource.signal(0)
    @element.div()
    <| [
      @element.p() <| [@element.text_dyn(fn() { "Count: \{count.get()}" })],
      @element.button(
        on=@element.events().click(fn(_e) { count.update(fn(n) { n + 1 }) }),
      )
      <| [@element.text("Increment")],
      @element.button(on=@element.events().click(fn(_e) { count.set(0) }))
      <| [@element.text("Reset")],
    ]
  }

  let _ = counter
}
```

Each handler receives the event type that matches its name — `click`,
`dblclick` and `mouseenter` a `MouseEvent`; `keydown`, `keyup` and `keypress` a
`KeyboardEvent`; `input` an `InputEvent`; `change` a `ChangeEvent`; `submit` a
`FormEvent`; `focus` and `blur` a `FocusEvent`.

Reading the value off an input event goes through `mizchi/js/core`, because
`@dom.Element` has no `value` accessor of its own — cast the target and read
the property:

```mbt check
///|
test "several handlers chain in one expression" {
  fn search_box() -> @element.DomNode {
    let query = @resource.signal("")
    @element.input(
      type_="text",
      on=@element
        .events()
        .input(fn(e) {
          let target : @js.Any = e.target() |> @js.identity
          query.set(target._get("value").cast())
        })
        .focus(fn(_e) { println("focused") }),
    )
  }

  let _ = search_box
}
```

## Portals

A portal moves its children elsewhere in the document while keeping them under
Luna's reconciliation. The children are a plain `Array[DomNode]` — there is no
callback to defer them with:

```mbt check
///|
test "portals take plain nodes, not a callback" {
  fn modal() -> @element.DomNode {
    @element.portal_to_body([
      @element.div(class="modal") <| [@element.text("Modal content")],
    ])
  }

  fn modal_in_selector() -> @element.DomNode {
    @element.portal_to("#modal-root", [
      @element.div(class="modal") <| [@element.text("Modal content")],
    ])
  }

  let _ = modal
  let _ = modal_in_selector
}
```

```moonbit
fn portal_to_body(Array[DomNode]) -> DomNode
fn portal_to(String, Array[DomNode]) -> DomNode
fn portal(target~ : @dom.Element, children~ : Array[DomNode]) -> DomNode
```

## Context

Context lives in `mizchi/signals`. `provide` takes a **thunk**: the value is in
scope only while that function runs, which is what makes nesting and restoring
work. These two blocks touch no DOM, so they really do execute:

```mbt check
///|
test "provide scopes a context value to the thunk" {
  let theme = @signals.create_context("light")
  assert_eq(@signals.use_context(theme), "light")
  let inner = @signals.provide(theme, "dark", fn() {
    @signals.use_context(theme)
  })
  assert_eq(inner, "dark")
  // the outer value is restored on the way out
  assert_eq(@signals.use_context(theme), "light")
}

///|
test "provide nests" {
  let theme = @signals.create_context("light")
  let seen = @signals.provide(theme, "outer", fn() {
    let a = @signals.use_context(theme)
    let b = @signals.provide(theme, "inner", fn() {
      @signals.use_context(theme)
    })
    let c = @signals.use_context(theme)
    (a, b, c)
  })
  assert_eq(seen, ("outer", "inner", "outer"))
}
```

Here too the thunk is a type, not a convention: `provide` is
`fn[T, R] (Context[T], T, () -> R) -> R`, so handing it an already-computed
value does not compile.

## Differences from the JavaScript API

`@luna_ui/luna` wraps this same renderer, but its `LunaNode` is `unknown`, so
mistakes MoonBit rejects at compile time can only surface at run time there.
The JavaScript side therefore accepts more shapes:

| | MoonBit | JavaScript |
|---|---|---|
| Mount | `render_to(el, node)` — a built node only | `render(el, node)` **or** `render(el, () => node)` |
| Portal children | `Array[DomNode]` | a node **or** a thunk |
| Context children | `provide(ctx, v, fn)` — the thunk is in the type | `Provider` throws if children is not a function |
| Events | `events().click(fn)` | `onClick={fn}` in JSX — `events()` is not exported to JS |

`events()` is the one that does not cross over. `HandlerMap::click` and its
siblings are MoonBit `extern "js"` methods: they work here, but they never
attach to the object the compiled function returns, so calling `events()` from
JavaScript gave back a bare `{}`. It is a MoonBit-only DSL, and the JavaScript
package no longer exports it.

Argument order is the same on both sides — the container comes first — which is
the opposite of SolidJS's `render(code, element)`.

## API summary

| Function | Description |
|----------|-------------|
| `render_to(el, node)` | Clear the element, then mount the node |
| `mount_to(el, node)` | Append the node to the element |
| `render(dom_el, node)` | As `render_to`, taking a `DomElement` |
| `mount(dom_el, node)` | As `mount_to`, taking a `DomElement` |
| `DomElement::from_dom(el)` | Wrap a `@dom.Element` |
| `events()` | Open a `HandlerMap` to chain handlers onto |
| `portal_to_body(children)` | Render children into `<body>` |
| `portal_to(selector, children)` | Render children into the first match |
| `portal(target~, children~)` | Render children into a known element |
| `@signals.create_context(default)` | Create a context |
| `@signals.provide(ctx, value, fn)` | Run `fn` with `value` in scope |
| `@signals.use_context(ctx)` | Read the innermost provided value |
