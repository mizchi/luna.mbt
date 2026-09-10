---
title: Render API
---

# Render API

Server-side rendering: build a node tree, turn it into an HTML string. Every
name on this page comes from `mizchi/luna/dom/static`, conventionally imported
as `@server_dom` (that is the alias `sol new` scaffolds):

```
import {
  "mizchi/luna/dom/static" @server_dom,
}
```

Nodes are `@luna.Node[Unit, String]` — the `Unit` event type is what makes
them server-only. The browser-side element helpers live in `mizchi/luna/dom`
(usually aliased `@element`) and are a **different, larger** set; see
[Signals](/luna/api-moonbit/signals/) and the tutorial for client rendering.

## render

Render a node tree to an HTML string.

```moonbit
let node = @server_dom.div([@server_dom.p([@server_dom.text("Hello, World!")])])
let html = @server_dom.render(node)
// <div><p>Hello, World!</p></div>
```

### Signature

```moonbit
fn render(@luna.Node[Unit, String]) -> String
```

## render_document

Render with a `<!DOCTYPE html>` declaration.

```moonbit
let doc = @server_dom.document(
  lang="en",
  head_children=[@server_dom.title("My Page")],
  body_children=[@server_dom.h1([@server_dom.text("Hello")])],
)
let html = @server_dom.render_document(doc)
// <!DOCTYPE html><html lang="en">...
```

## document

Build a full HTML document structure. `head_children` and `body_children` are
required; everything else is optional.

### Signature

```moonbit
fn document(
  lang? : String,
  head_children~ : Array[@luna.Node[Unit, String]],
  body_children~ : Array[@luna.Node[Unit, String]],
  body_class? : String,
  body_id? : String,
) -> @luna.Node[Unit, String]
```

```moonbit
let doc = @server_dom.document(
  lang="ja",
  head_children=[
    @server_dom.title("Test"),
    @server_dom.meta(charset="UTF-8"),
  ],
  body_children=[@server_dom.p([@server_dom.text("Hello World")])],
)
```

## Element helpers

Every helper takes optional `id`, `class`, `style` and `attrs`, and — for
non-void elements — a trailing `Array[@luna.Node[Unit, String]]` of children.

### Block and inline

```moonbit
@server_dom.div(children)
@server_dom.div(id="main", class="container", children)
@server_dom.p(children)
@server_dom.span(children)
@server_dom.article(children)
@server_dom.section(children)
@server_dom.main_(children)     // trailing underscore: `main` is a keyword
@server_dom.header_(children)
@server_dom.footer_(children)
@server_dom.nav(children)
@server_dom.aside(children)
@server_dom.pre(children)
@server_dom.code(children)
@server_dom.em(children)
@server_dom.strong(children)
```

### Headings and lists

```moonbit
@server_dom.h1(children)  // through h6
@server_dom.ul([@server_dom.li([@server_dom.text("Item 1")])])
@server_dom.ol(children)
```

### Links and media

```moonbit
@server_dom.a(href="https://example.com", target="_blank", children)
@server_dom.img(src="/image.png", alt="Description", width="64", height="64")
@server_dom.br()
@server_dom.hr()
```

### Document structure

```moonbit
@server_dom.html(lang="en", children)
@server_dom.head(children)
@server_dom.body(children)
@server_dom.title("Page Title")
@server_dom.meta(charset="UTF-8")
@server_dom.meta(name="description", content="…")
```

### Scripts and styles

```moonbit
@server_dom.script(src="/app.js", type_="module", defer_=true)
@server_dom.script(content="console.log('inline')")
@server_dom.style_("body { margin: 0; }")
@server_dom.link(rel="stylesheet", href="/style.css")
```

`script_trusted` and `style_trusted` take a `TrustedScript` / `TrustedStyle`
built by `unsafe_trusted_script` / `unsafe_trusted_style`, for content you have
audited yourself.

### Forms

```moonbit
@server_dom.form(action="/search", http_method="get", [
  @server_dom.label(for_="q", [@server_dom.text("Query")]),
  @server_dom.input(type_="text", name="q", placeholder="Enter a query"),
  @server_dom.button([@server_dom.text("Submit")]),
])
```

`input` also accepts `value`, `disabled`, `readonly_`, `required` and
`checked`; `button` accepts `disabled`.

### Not provided

There are no helpers for `<table>`, `<tr>`, `<td>`, `<select>`, `<option>` or
`<textarea>` in the static package — `@server_dom` covers the elements the SSR
paths in this repo actually emit. For anything else, `@luna.h` builds an
element from a tag name:

```moonbit
@luna.h("table", [], [
  @luna.h("tr", [], [
    @luna.h("td", [], [@server_dom.text("Item 1")]),
    @luna.h("td", [], [@server_dom.text("$10")]),
  ]),
])
```

`h` is generic over the node's event type, so the same call works in the
browser. Its second argument is the same `(name, Attr)` tuple list `attrs`
takes. If you find yourself writing the same tag repeatedly, add the helper to
`luna/src/dom/static/`.

## text

Create a text node. Content is escaped on render.

```moonbit
@server_dom.text("Hello, World!")

@server_dom.text("<script>alert('xss')</script>")
// renders as &lt;script&gt;alert('xss')&lt;/script&gt;
```

## fragment

Group nodes without a wrapper element.

```moonbit
let nodes = @server_dom.fragment([
  @server_dom.text("A"),
  @server_dom.text("B"),
])
@server_dom.render(nodes) // "AB"
```

## attr

`attr` wraps a single **value**; the attribute *name* is the first half of the
tuple you pass to `attrs`:

```moonbit
@server_dom.div(
  attrs=[
    ("data-id", @server_dom.attr("123")),
    ("aria-label", @server_dom.attr("Item 123")),
  ],
  [@server_dom.text("Content")],
)
```

Boolean attributes take an empty value:

```moonbit
@server_dom.input(attrs=[("disabled", @server_dom.attr(""))])
// <input disabled>
```

`input` and `button` already have `disabled` as a named parameter, so reach for
`attrs` only for attributes that have no dedicated one.

### Signature

```moonbit
fn attr(String) -> @luna.Attr[Unit, String]
```

## Raw HTML (escape hatch)

`raw_html` lives in `mizchi/luna` rather than the static package, and is
generic, so the same call works on the server and in the browser:

```moonbit
@luna.raw_html("<svg>…</svg>")
```

**Warning:** the string is emitted verbatim. Only pass content you trust.

## render_with_preloads

Render and collect the island module URLs the tree references, so you can emit
`<link rel="modulepreload">` tags for them.

```moonbit
let result = @server_dom.render_with_preloads(node)
result.html          // String
result.preload_urls  // Array[String]

let tags = @server_dom.generate_preload_tags(result.preload_urls)
```

`render_document_with_preloads` does the same and adds the DOCTYPE.

## Sol integration helpers

These exist for sol's SSR pipeline and are only meaningful inside it:

| Function | Purpose |
|----------|---------|
| `sol_link(href~, children, prefetch?, replace?)` | Client-routed `<a>` |
| `outlet(name~, children)` | Named slot filled by a nested layout |
| `template_outlet(name~, children)` / `template_title(String)` | Streaming-template equivalents |
| `wc_island(tag, id, children, styles?, state?, trigger?)` | Emit a web-component island with a hydration trigger |
| `generate_utility_css()` | Collected utility-class CSS for the page |

## Utility class helpers

`ucss`, `ustyles`, `ucombine`, `uhover`, `ufocus`, `uactive`, `udark`, `uon`,
`uat_md` and `uat_lg` build atomic class names for the utility-CSS pipeline.
See [CSS](/luna/css/) for how they compose.

## XSS safety

`text` escapes on render; `attr` values are escaped too. The only ways to emit
unescaped markup are `@luna.raw_html`, `script_trusted` and `style_trusted` —
all three are explicit about it.

## Low level: the node type

`@server_dom` is a set of builders over one enum in `mizchi/luna/core`. You
rarely construct these by hand, but the shape explains what the helpers can
and cannot express:

```moonbit
pub enum Node[E, A] {
  Element(VElement[E, A])       // an HTML element
  Text(String)                  // static text (escaped on render)
  DynamicText(() -> String)     // text driven by a signal (client only)
  Fragment(Array[Node[E, A]])
  Show(condition~, child~)      // conditional
  For(render~)                  // list
  Component(render~)
  WcIsland(VWcIsland[E, A])     // hydration boundary
  Async(VAsync[E, A])
  ErrorBoundary(VErrorBoundary[E, A])
  Switch(VSwitch[E, A])
  InternalRef(VInternalRef[E, A])
  RawHtml(String)               // what `@luna.raw_html` builds
}

pub enum Attr[E, A] {
  VStatic(A)                    // literal value
  VDynamic(() -> A)             // signal-driven (client only)
  VHandler(EventHandler[E])     // event handler
  VAction(String)               // declarative action
}
```

`E` is the event type and `A` the attribute-value type. SSR nodes are
`Node[Unit, String]`: `Unit` events means no handler can be attached, which is
what makes them safe to render on the server.

`mizchi/luna/core/render` holds the renderer the helpers above call into:

```moonbit
fn render_to_string(@luna.Node[E, A], preload? : Bool, size_hint? : Int) -> SSRResult
fn render_to_string_with_hydration(@luna.Node[E, A], size_hint? : Int) -> String

pub struct SSRResult {
  html : String
  preload_urls : Array[String]
}
```

Note that `render_to_string` returns an `SSRResult`, not a `String` —
`@server_dom.render` is the convenience wrapper that hands back just the HTML.

## API summary

### Rendering

| Function | Description |
|----------|-------------|
| `render(node)` | Render to an HTML string |
| `render_document(node)` | Render with DOCTYPE |
| `render_with_preloads(node)` | Render + island preload URLs |
| `render_document_with_preloads(node)` | Both of the above |
| `document(head_children~, body_children~, lang?)` | Build a document node |

### Elements

| Group | Helpers |
|-------|---------|
| Block / inline | `div` `p` `span` `article` `section` `aside` `main_` `header_` `footer_` `nav` `pre` `code` `em` `strong` |
| Headings | `h1`–`h6` |
| Lists | `ul` `ol` `li` |
| Links / media | `a` `img` `br` `hr` |
| Document | `html` `head` `body` `title` `meta` |
| Resources | `script` `script_trusted` `style_` `style_trusted` `link` |
| Forms | `form` `input` `button` `label` |
| SVG | `svg` and `svg_*` (path, circle, rect, text, …) |

### Content

| Function | Description |
|----------|-------------|
| `text(content)` | Text node (escaped) |
| `fragment(children)` | Group without a wrapper |
| `attr(value)` | Attribute value for the `attrs` tuple list |
| `@luna.h(tag, attrs, children)` | Any element with no dedicated helper |
| `@luna.raw_html(html)` | Unescaped markup (unsafe) |
