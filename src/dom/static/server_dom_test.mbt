//

///|
/// Tests for server_dom module
test "render simple div" {
  let node = div([text("Hello")])
  let html = render(node)
  assert_eq(html, "<div>Hello</div>")
}

///|
test "render div with attributes" {
  let node = div(id="main", class="container", [text("Content")])
  let html = render(node)
  assert_true(html.contains("id=\"main\""))
  assert_true(html.contains("class=\"container\""))
  assert_true(html.contains("Content"))
}

///|
test "render nested elements" {
  let node = div([h1([text("Title")]), p([text("Paragraph")])])
  let html = render(node)
  assert_true(html.contains("<h1>Title</h1>"))
  assert_true(html.contains("<p>Paragraph</p>"))
}

///|
test "render html document structure" {
  let node = html(lang="en", [
    head([title("My Page")]),
    body([h1([text("Hello")])]),
  ])
  let html_str = render(node)
  assert_true(html_str.contains("<html lang=\"en\">"))
  assert_true(html_str.contains("<title>My Page</title>"))
  assert_true(html_str.contains("<h1>Hello</h1>"))
}

///|
test "render document helper" {
  let node = document(
    lang="ja",
    head_children=[title("Test"), meta(charset="UTF-8")],
    body_children=[p([text("Hello World")])],
  )
  let html = render_document(node)
  assert_true(html.has_prefix("<!DOCTYPE html>"))
  assert_true(html.contains("<html lang=\"ja\">"))
  assert_true(html.contains("<meta charset=\"UTF-8\" />"))
}

///|
test "render void elements" {
  let node = div([img(src="/image.png", alt="test"), br(), hr()])
  let html = render(node)
  assert_true(html.contains("<img"))
  assert_true(html.contains("src=\"/image.png\""))
  assert_true(html.contains("<br />"))
  assert_true(html.contains("<hr />"))
}

///|
test "render list elements" {
  let node = ul([li([text("Item 1")]), li([text("Item 2")])])
  let html = render(node)
  assert_true(html.contains("<ul>"))
  assert_true(html.contains("<li>Item 1</li>"))
  assert_true(html.contains("<li>Item 2</li>"))
}

///|
test "render anchor with href" {
  let node = a(href="https://example.com", target="_blank", [text("Link")])
  let html = render(node)
  assert_true(html.contains("href=\"https://example.com\""))
  assert_true(html.contains("target=\"_blank\""))
}

///|
test "render script element" {
  let node = script(src="/app.js", type_="module", defer_=true)
  let html = render(node)
  assert_true(html.contains("src=\"/app.js\""))
  assert_true(html.contains("type=\"module\""))
  assert_true(html.contains("defer"))
}

///|
test "render style element" {
  let node = style_("body { margin: 0; }")
  let html = render(node)
  assert_true(html.contains("<style>body { margin: 0; }</style>"))
}

///|
test "render island" {
  let node = @luna.island(
    "counter",
    "/components/counter.js",
    "{\"count\":0}",
    [text("Loading...")],
  )
  let html = render(node)
  assert_true(html.contains("luna:id=\"counter\""))
  assert_true(html.contains("luna:url=\"/components/counter.js\""))
  assert_true(html.contains("Loading..."))
}

///|
test "render island with visible trigger" {
  let node = @luna.island(
    "lazy",
    "/components/lazy.js",
    "{}",
    [text("Lazy content")],
    trigger=@core.Visible,
  )
  let html = render(node)
  assert_true(html.contains("luna:client-trigger=\"visible\""))
}

///|
test "render_with_preloads collects island URLs" {
  let node = div([
    @luna.island("a", "/a.js", "{}", [text("A")]),
    @luna.island("b", "/b.js", "{}", [text("B")]),
  ])
  let result = render_with_preloads(node)
  assert_eq(result.preload_urls.length(), 2)
  assert_true(result.preload_urls.contains("/a.js"))
  assert_true(result.preload_urls.contains("/b.js"))
}

///|
test "render fragment" {
  let node = fragment([text("A"), text("B"), text("C")])
  let html = render(node)
  assert_eq(html, "ABC")
}

///|
test "render semantic elements" {
  let node = main_([
    header_([nav([text("Nav")])]),
    section([article([text("Content")])]),
    footer_([text("Footer")]),
  ])
  let html = render(node)
  assert_true(html.contains("<main>"))
  assert_true(html.contains("<header>"))
  assert_true(html.contains("<nav>"))
  assert_true(html.contains("<section>"))
  assert_true(html.contains("<article>"))
  assert_true(html.contains("<footer>"))
}

///|
test "html escaping in text" {
  let node = p([text("<script>alert('xss')</script>")])
  let html = render(node)
  assert_true(html.contains("&lt;script&gt;"))
  assert_false(html.contains("<script>alert"))
}

// =============================================================================
// Error Boundary Tests
// =============================================================================

///|
test "render error_boundary success" {
  let node : @luna.Node[Unit, String] = @luna.error_boundary(
    children=fn() { div([text("Success!")]) },
    fallback=fn(_err, _reset) { text("Error occurred") },
  )
  let html = render(node)
  assert_eq(html, "<div>Success!</div>")
}

///|
test "render error_boundary with nested elements" {
  let node : @luna.Node[Unit, String] = @luna.error_boundary(
    children=fn() {
      div(class="container", [h1([text("Title")]), p([text("Content")])])
    },
    fallback=fn(_err, _reset) { text("Error") },
  )
  let html = render(node)
  assert_true(html.contains("<h1>Title</h1>"))
  assert_true(html.contains("<p>Content</p>"))
  assert_true(html.contains("class=\"container\""))
}

///|
test "render error_boundary with island inside" {
  let node : @luna.Node[Unit, String] = @luna.error_boundary(
    children=fn() {
      div([
        @luna.island("counter", "/components/counter.js", "{\"count\":0}", [
          text("Loading..."),
        ]),
      ])
    },
    fallback=fn(_err, _reset) { text("Error") },
  )
  let html = render(node)
  assert_true(html.contains("luna:id=\"counter\""))
  assert_true(html.contains("luna:url=\"/components/counter.js\""))
}

///|
test "render nested error_boundaries" {
  let node : @luna.Node[Unit, String] = @luna.error_boundary(
    children=fn() {
      div([
        @luna.error_boundary(children=fn() { span([text("Inner content")]) }, fallback=fn(
          _err,
          _reset,
        ) {
          text("Inner error")
        }),
      ])
    },
    fallback=fn(_err, _reset) { text("Outer error") },
  )
  let html = render(node)
  assert_true(html.contains("<span>Inner content</span>"))
}

///|
test "render error_boundary with show" {
  let visible = true
  let node : @luna.Node[Unit, String] = @luna.error_boundary(
    children=fn() { @luna.show(fn() { visible }, fn() { text("Visible!") }) },
    fallback=fn(_err, _reset) { text("Error") },
  )
  let html = render(node)
  assert_eq(html, "Visible!")
}

///|
test "render error_boundary with fragment" {
  let node : @luna.Node[Unit, String] = @luna.error_boundary(
    children=fn() { fragment([text("A"), text("B"), text("C")]) },
    fallback=fn(_err, _reset) { text("Error") },
  )
  let html = render(node)
  assert_eq(html, "ABC")
}

///|
test "render_with_preloads error_boundary collects island URLs" {
  let node : @luna.Node[Unit, String] = @luna.error_boundary(
    children=fn() {
      div([
        @luna.island("a", "/a.js", "{}", [text("A")]),
        @luna.island("b", "/b.js", "{}", [text("B")]),
      ])
    },
    fallback=fn(_err, _reset) { text("Error") },
  )
  let result = render_with_preloads(node)
  assert_eq(result.preload_urls.length(), 2)
  assert_true(result.preload_urls.contains("/a.js"))
  assert_true(result.preload_urls.contains("/b.js"))
}

// =============================================================================
// Show with multiple children tests (Fragment inside Show)
// =============================================================================

///|
test "render show with fragment (multiple children) - visible" {
  let visible = true
  let node : @luna.Node[Unit, String] = @luna.show(fn() { visible }, fn() {
    fragment([div([text("A")]), div([text("B")])])
  })
  let html = render(node)
  assert_true(html.contains("<div>A</div>"))
  assert_true(html.contains("<div>B</div>"))
}

///|
test "render show with fragment (multiple children) - hidden" {
  let visible = false
  let node : @luna.Node[Unit, String] = @luna.show(fn() { visible }, fn() {
    fragment([div([text("A")]), div([text("B")])])
  })
  let html = render(node)
  // Should not contain the content
  assert_false(html.contains("<div>A</div>"))
  assert_false(html.contains("<div>B</div>"))
  // Should contain placeholder comment
  assert_true(html.contains("<!--show-->"))
}

///|
test "render switch with match containing multiple children" {
  let node : @luna.Node[Unit, String] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { true }, render=fn() {
        fragment([span([text("First")]), span([text("Second")])])
      }),
    ],
    fallback=Some(fn() { text("Fallback") }),
  )
  let html = render(node)
  assert_true(html.contains("<span>First</span>"))
  assert_true(html.contains("<span>Second</span>"))
  assert_false(html.contains("Fallback"))
}

///|
test "render switch with match fallback" {
  let node : @luna.Node[Unit, String] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() {
        fragment([span([text("First")]), span([text("Second")])])
      }),
    ],
    fallback=Some(fn() { text("Fallback") }),
  )
  let html = render(node)
  assert_false(html.contains("<span>First</span>"))
  assert_false(html.contains("<span>Second</span>"))
  assert_true(html.contains("Fallback"))
}
