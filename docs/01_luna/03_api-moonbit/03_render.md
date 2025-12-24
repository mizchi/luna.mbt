---
title: Render API
---

# Render API

Server-side rendering utilities for generating HTML.

## render

Render a node tree to an HTML string.

```moonbit
let node = @element.div([@element.p([@element.text("Hello, World!")])])
let html = render(node)
// Output: <div><p>Hello, World!</p></div>
```

### Signature

```moonbit
fn render(node : @luna.Node) -> String
```

## render_document

Render with DOCTYPE declaration.

```moonbit
let node = document(
  lang="en",
  head_children=[@element.title("My Page")],
  body_children=[@element.h1([@element.text("Hello")])],
)
let html = render_document(node)
// Output: <!DOCTYPE html><html lang="en">...
```

## document

Helper to create a full HTML document structure.

```moonbit
let doc = document(
  lang="ja",
  head_children=[
    @element.title("Test"),
    @element.meta(charset="UTF-8"),
  ],
  body_children=[
    @element.p([@element.text("Hello World")]),
  ],
)
```

### Signature

```moonbit
fn document(
  lang~ : String = "en",
  head_children~ : Array[@luna.Node] = [],
  body_children~ : Array[@luna.Node] = [],
) -> @luna.Node
```

## HTML Element Factories

All elements are accessed via the `@element` namespace.

### Block Elements

```moonbit
@element.div(children)
@element.div(id="main", class="container", children)

@element.p(children)
@element.article(children)
@element.section(children)
@element.main_(children)     // Note: underscore suffix
@element.header_(children)   // Note: underscore suffix
@element.footer_(children)   // Note: underscore suffix
@element.nav(children)
@element.aside(children)
```

### Headings

```moonbit
@element.h1(children)
@element.h2(children)
@element.h3(children)
@element.h4(children)
@element.h5(children)
@element.h6(children)
```

### Lists

```moonbit
@element.ul(children)
@element.ol(children)
@element.li(children)

// Example
let list = @element.ul([
  @element.li([@element.text("Item 1")]),
  @element.li([@element.text("Item 2")]),
])
```

### Links and Media

```moonbit
// Anchor
@element.a(href="https://example.com", target="_blank", children)

// Image (void element)
@element.img(src="/image.png", alt="Description")

// Line break and horizontal rule
@element.br()
@element.hr()
```

### Document Structure

```moonbit
@element.html(lang="en", children)
@element.head(children)
@element.body(children)
@element.title("Page Title")
@element.meta(charset="UTF-8")
```

### Scripts and Styles

```moonbit
// Script with attributes
@element.script(src="/app.js", type_="module", defer_=true)

// Inline style
@element.style_("body { margin: 0; }")

// Link stylesheet
@element.link(rel="stylesheet", href="/style.css")
```

## text

Create a text node with automatic XSS escaping.

```moonbit
let node = @element.text("Hello, World!")

// XSS safe - content is escaped
let safe = @element.text("<script>alert('xss')</script>")
// Renders as: &lt;script&gt;alert('xss')&lt;/script&gt;
```

## fragment

Group elements without a wrapper element.

```moonbit
let nodes = @element.fragment([
  @element.text("A"),
  @element.text("B"),
  @element.text("C"),
])
let html = render(nodes)
// Output: ABC
```

## Element Signatures

All elements follow a consistent pattern:

```moonbit
// Simple element with children only
fn div(children : Array[@luna.Node]) -> @luna.Node

// Element with common attributes
fn div(
  id~ : String = "",
  class~ : String = "",
  attrs~ : Array[Attr] = [],
  children : Array[@luna.Node],
) -> @luna.Node
```

### Attribute Examples

```moonbit
// With class
@element.div(class="container", [@element.text("Content")])

// With ID
@element.div(id="main", [@element.text("Main content")])

// With multiple attributes
@element.div(
  class="card",
  id="card-1",
  attrs=[@element.attr("data-id", "1")],
  [@element.text("Card content")],
)

// Nested
@element.div([
  @element.h1([@element.text("Title")]),
  @element.p([@element.text("Paragraph")]),
])
```

## Custom Attributes

```moonbit
@element.div(
  attrs=[
    @element.attr("data-id", "123"),
    @element.attr("data-name", "item"),
    @element.attr("aria-label", "Item 123"),
  ],
  [@element.text("Content")],
)
```

### Boolean Attributes

```moonbit
// For boolean attributes, use empty string
@element.input(attrs=[@element.attr("disabled", "")])
// Renders: <input disabled>

@element.input(attrs=[@element.attr("checked", "")])
// Renders: <input checked>
```

## Form Elements

### input

```moonbit
@element.input(
  type_="text",
  name="username",
  placeholder="Enter username",
  value="",
)
```

### button

```moonbit
@element.button(
  type_="submit",
  class="btn",
  [@element.text("Submit")],
)
```

### select

```moonbit
@element.select(
  name="country",
  [
    @element.option(value="us", [@element.text("United States")]),
    @element.option(value="uk", [@element.text("United Kingdom")]),
    @element.option(value="jp", [@element.text("Japan")]),
  ],
)
```

### textarea

```moonbit
@element.textarea(
  name="message",
  rows=5,
  placeholder="Enter message",
)
```

## Tables

```moonbit
@element.table([
  @element.thead([
    @element.tr([
      @element.th([@element.text("Name")]),
      @element.th([@element.text("Price")]),
    ]),
  ]),
  @element.tbody([
    @element.tr([
      @element.td([@element.text("Item 1")]),
      @element.td([@element.text("$10")]),
    ]),
    @element.tr([
      @element.td([@element.text("Item 2")]),
      @element.td([@element.text("$20")]),
    ]),
  ]),
])
```

## Semantic Elements

```moonbit
@element.main_([
  @element.header_([@element.nav([@element.text("Nav")])]),
  @element.section([@element.article([@element.text("Content")])]),
  @element.footer_([@element.text("Footer")]),
])
```

**Note:** `main_`, `header_`, `footer_` have underscore suffix to avoid MoonBit keyword conflicts.

## render_with_preloads

Render and collect island module URLs for preloading.

```moonbit
let node = @element.div([
  @luna.island("a", "/a.js", "{}", [@element.text("A")]),
  @luna.island("b", "/b.js", "{}", [@element.text("B")]),
])

let result = render_with_preloads(node)
// result.html: rendered HTML string
// result.preload_urls: ["/a.js", "/b.js"]
```

## XSS Safety

Text content is automatically escaped:

```moonbit
@element.p([@element.text("<script>alert('xss')</script>")])
// Renders: <p>&lt;script&gt;alert('xss')&lt;/script&gt;</p>
```

## Raw HTML (Escape Hatch)

For trusted HTML content only:

```moonbit
@element.raw_html("<svg>...</svg>")
```

**Warning:** Only use with trusted content. User input must be sanitized.

## API Summary

### Rendering

| Function | Description |
|----------|-------------|
| `render(node)` | Render to HTML string |
| `render_document(node)` | Render with DOCTYPE |
| `render_with_preloads(node)` | Render and collect island URLs |
| `document(lang~, head~, body~)` | Create HTML document |

### Elements

| Function | Description |
|----------|-------------|
| `@element.div`, `p`, `span`, ... | Block/inline elements |
| `@element.h1` - `h6` | Headings |
| `@element.ul`, `ol`, `li` | Lists |
| `@element.table`, `tr`, `td`, `th` | Tables |
| `@element.form`, `input`, `button` | Form elements |
| `@element.a`, `img`, `video` | Links and media |
| `@element.html`, `head`, `body` | Document structure |
| `@element.script`, `style_`, `link` | Resources |
| `@element.main_`, `header_`, `footer_` | Semantic sections |

### Content

| Function | Description |
|----------|-------------|
| `@element.text(content)` | Text node (escaped) |
| `@element.fragment(children)` | Group without wrapper |
| `@element.raw_html(html)` | Raw HTML (unsafe) |
| `@element.attr(name, value)` | Custom attribute |
