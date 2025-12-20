---
title: Render API
---

# Render API

Server-side rendering utilities for generating HTML.

## render_to_string

Render a VNode tree to an HTML string.

```moonbit
using @server_dom { div, p, text }
using @renderer { render_to_string }

fn main {
  let node = div([
    p([text("Hello, World!")])
  ])

  let html = render_to_string(node)
  println(html)
  // Output: <div><p>Hello, World!</p></div>
}
```

### Signature

```moonbit
fn render_to_string(node : @luna.Node) -> String
```

## HTML Element Factories

### Common Elements

```moonbit
using @server_dom {
  // Block elements
  div, p, article, section, header, footer, main_, nav, aside,

  // Headings
  h1, h2, h3, h4, h5, h6,

  // Lists
  ul, ol, li,

  // Tables
  table, thead, tbody, tr, th, td,

  // Forms
  form, input, button, label, select, option, textarea,

  // Inline elements
  span, a, strong, em, code, pre,

  // Media
  img, video, audio,

  // Semantic
  figure, figcaption, blockquote,
}
```

### Element Signature

```moonbit
fn div(
  attrs~ : Array[Attr] = [],
  class_~ : String = "",
  id~ : String = "",
  children~ : Array[@luna.Node] = [],
) -> @luna.Node
```

### Examples

```moonbit
// Basic
div([text("Hello")])

// With class
div(class_="container", [text("Content")])

// With ID
div(id="main", [text("Main content")])

// With multiple attributes
div(
  class_="card",
  id="card-1",
  attrs=[attr("data-id", "1")],
  [text("Card content")]
)

// Nested
div([
  h1([text("Title")]),
  p([text("Paragraph")]),
])
```

## text

Create a text node.

```moonbit
using @server_dom { text }

let node = text("Hello, World!")
```

### Signature

```moonbit
fn text(content : String) -> @luna.Node
```

### XSS Safety

Text content is automatically escaped:

```moonbit
text("<script>alert('xss')</script>")
// Renders as: &lt;script&gt;alert('xss')&lt;/script&gt;
```

## attr

Create a custom attribute.

```moonbit
using @server_dom { div, attr }

div(
  attrs=[
    attr("data-id", "123"),
    attr("data-name", "item"),
    attr("aria-label", "Item 123"),
  ],
  [text("Content")]
)
```

### Signature

```moonbit
fn attr(name : String, value : String) -> Attr
```

### Boolean Attributes

```moonbit
// For boolean attributes, use empty string
input(attrs=[attr("disabled", "")])
// Renders: <input disabled>

input(attrs=[attr("checked", "")])
// Renders: <input checked>
```

## Form Elements

### input

```moonbit
input(
  type_="text",
  name="username",
  placeholder="Enter username",
  value="",
)
```

### button

```moonbit
button(
  type_="submit",
  class_="btn",
  [text("Submit")]
)
```

### select

```moonbit
select(
  name="country",
  [
    option(value="us", [text("United States")]),
    option(value="uk", [text("United Kingdom")]),
    option(value="jp", [text("Japan")]),
  ]
)
```

## Links and Images

### a (anchor)

```moonbit
a(
  href="/about",
  class_="nav-link",
  [text("About Us")]
)
```

### img

```moonbit
img(
  src="/images/logo.png",
  alt="Logo",
  class_="logo",
)
```

## Tables

```moonbit
table([
  thead([
    tr([
      th([text("Name")]),
      th([text("Price")]),
    ])
  ]),
  tbody([
    tr([
      td([text("Item 1")]),
      td([text("$10")]),
    ]),
    tr([
      td([text("Item 2")]),
      td([text("$20")]),
    ]),
  ])
])
```

## Fragment

Group elements without a wrapper:

```moonbit
using @server_dom { fragment, p, text }

fragment([
  p([text("First paragraph")]),
  p([text("Second paragraph")]),
])
```

## Raw HTML

Insert raw HTML (use with caution):

```moonbit
using @server_dom { raw_html }

raw_html("<svg>...</svg>")
```

### Warning

Only use `raw_html` with trusted content. User input must be sanitized.

## API Summary

| Function | Description |
|----------|-------------|
| `render_to_string(node)` | Render to HTML string |
| `div`, `p`, `span`, ... | Element factories |
| `text(content)` | Create text node |
| `attr(name, value)` | Create attribute |
| `fragment(children)` | Group without wrapper |
| `raw_html(html)` | Insert raw HTML |
