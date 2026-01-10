//

///|
/// Tests for server_dom module
test "render simple div" {
  let node = @element.div([@element.text("Hello")])
  let html = render(node)
  assert_eq(html, "<div>Hello</div>")
}

///|
test "render div with attributes" {
  let node = @element.div(id="main", class="container", [
    @element.text("Content"),
  ])
  let html = render(node)
  assert_true(html.contains("id=\"main\""))
  assert_true(html.contains("class=\"container\""))
  assert_true(html.contains("Content"))
}

///|
test "render nested elements" {
  let node = @element.div([
    @element.h1([@element.text("Title")]),
    @element.p([@element.text("Paragraph")]),
  ])
  let html = render(node)
  assert_true(html.contains("<h1>Title</h1>"))
  assert_true(html.contains("<p>Paragraph</p>"))
}

///|
test "render html document structure" {
  let node = @element.html(lang="en", [
    @element.head([@element.title("My Page")]),
    @element.body([@element.h1([@element.text("Hello")])]),
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
    head_children=[@element.title("Test"), @element.meta(charset="UTF-8")],
    body_children=[@element.p([@element.text("Hello World")])],
  )
  let html = render_document(node)
  assert_true(html.has_prefix("<!DOCTYPE html>"))
  assert_true(html.contains("<html lang=\"ja\">"))
  assert_true(html.contains("<meta charset=\"UTF-8\" />"))
}

///|
test "render void elements" {
  let node = @element.div([
    @element.img(src="/image.png", alt="test"),
    @element.br(),
    @element.hr(),
  ])
  let html = render(node)
  assert_true(html.contains("<img"))
  assert_true(html.contains("src=\"/image.png\""))
  assert_true(html.contains("<br />"))
  assert_true(html.contains("<hr />"))
}

///|
test "render list elements" {
  let node = @element.ul([
    @element.li([@element.text("Item 1")]),
    @element.li([@element.text("Item 2")]),
  ])
  let html = render(node)
  assert_true(html.contains("<ul>"))
  assert_true(html.contains("<li>Item 1</li>"))
  assert_true(html.contains("<li>Item 2</li>"))
}

///|
test "render anchor with href" {
  let node = @element.a(href="https://example.com", target="_blank", [
    @element.text("Link"),
  ])
  let html = render(node)
  assert_true(html.contains("href=\"https://example.com\""))
  assert_true(html.contains("target=\"_blank\""))
}

///|
test "render script element" {
  let node = @element.script(src="/app.js", type_="module", defer_=true)
  let html = render(node)
  assert_true(html.contains("src=\"/app.js\""))
  assert_true(html.contains("type=\"module\""))
  assert_true(html.contains("defer"))
}

///|
test "render style element" {
  let node = @element.style_("body { margin: 0; }")
  let html = render(node)
  assert_true(html.contains("<style>body { margin: 0; }</style>"))
}

///|
test "render island" {
  let node = @luna.island(
    "counter",
    "/components/counter.js",
    "{\"count\":0}",
    [@element.text("Loading...")],
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
    [@element.text("Lazy content")],
    trigger=@luna.Visible,
  )
  let html = render(node)
  assert_true(html.contains("luna:client-trigger=\"visible\""))
}

///|
test "render_with_preloads collects island URLs" {
  let node = @element.div([
    @luna.island("a", "/a.js", "{}", [@element.text("A")]),
    @luna.island("b", "/b.js", "{}", [@element.text("B")]),
  ])
  let result = render_with_preloads(node)
  assert_eq(result.preload_urls.length(), 2)
  assert_true(result.preload_urls.contains("/a.js"))
  assert_true(result.preload_urls.contains("/b.js"))
}

///|
test "render fragment" {
  let node = @element.fragment([
    @element.text("A"),
    @element.text("B"),
    @element.text("C"),
  ])
  let html = render(node)
  assert_eq(html, "ABC")
}

///|
test "render semantic elements" {
  let node = @element.main_([
    @element.header_([@element.nav([@element.text("Nav")])]),
    @element.section([@element.article([@element.text("Content")])]),
    @element.footer_([@element.text("Footer")]),
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
  let node = @element.p([@element.text("<script>alert('xss')</script>")])
  let html = render(node)
  assert_true(html.contains("&lt;script&gt;"))
  assert_false(html.contains("<script>alert"))
}

// =============================================================================
// Error Boundary Tests
// =============================================================================

///|
test "render error_boundary success" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() { @element.div([@element.text("Success!")]) },
    fallback=fn(_err, _reset) { @element.text("Error occurred") },
  )
  let html = render(node)
  assert_eq(html, "<div>Success!</div>")
}

///|
test "render error_boundary with nested elements" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @element.div(class="container", [
        @element.h1([@element.text("Title")]),
        @element.p([@element.text("Content")]),
      ])
    },
    fallback=fn(_err, _reset) { @element.text("Error") },
  )
  let html = render(node)
  assert_true(html.contains("<h1>Title</h1>"))
  assert_true(html.contains("<p>Content</p>"))
  assert_true(html.contains("class=\"container\""))
}

///|
test "render error_boundary with island inside" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @element.div([
        @luna.island("counter", "/components/counter.js", "{\"count\":0}", [
          @element.text("Loading..."),
        ]),
      ])
    },
    fallback=fn(_err, _reset) { @element.text("Error") },
  )
  let html = render(node)
  assert_true(html.contains("luna:id=\"counter\""))
  assert_true(html.contains("luna:url=\"/components/counter.js\""))
}

///|
test "render nested error_boundaries" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @element.div([
        @luna.error_boundary(
          children=fn() { @element.span([@element.text("Inner content")]) },
          fallback=fn(_err, _reset) { @element.text("Inner error") },
        ),
      ])
    },
    fallback=fn(_err, _reset) { @element.text("Outer error") },
  )
  let html = render(node)
  assert_true(html.contains("<span>Inner content</span>"))
}

///|
test "render error_boundary with show" {
  let visible = true
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @luna.show(fn() { visible }, fn() { @element.text("Visible!") })
    },
    fallback=fn(_err, _reset) { @element.text("Error") },
  )
  let html = render(node)
  assert_eq(html, "Visible!")
}

///|
test "render error_boundary with fragment" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @element.fragment([
        @element.text("A"),
        @element.text("B"),
        @element.text("C"),
      ])
    },
    fallback=fn(_err, _reset) { @element.text("Error") },
  )
  let html = render(node)
  assert_eq(html, "ABC")
}

///|
test "render_with_preloads error_boundary collects island URLs" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @element.div([
        @luna.island("a", "/a.js", "{}", [@element.text("A")]),
        @luna.island("b", "/b.js", "{}", [@element.text("B")]),
      ])
    },
    fallback=fn(_err, _reset) { @element.text("Error") },
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
  let node : @luna.Node[Unit] = @luna.show(fn() { visible }, fn() {
    @element.fragment([
      @element.div([@element.text("A")]),
      @element.div([@element.text("B")]),
    ])
  })
  let html = render(node)
  assert_true(html.contains("<div>A</div>"))
  assert_true(html.contains("<div>B</div>"))
}

///|
test "render show with fragment (multiple children) - hidden" {
  let visible = false
  let node : @luna.Node[Unit] = @luna.show(fn() { visible }, fn() {
    @element.fragment([
      @element.div([@element.text("A")]),
      @element.div([@element.text("B")]),
    ])
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
  let node : @luna.Node[Unit] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { true }, render=fn() {
        @element.fragment([
          @element.span([@element.text("First")]),
          @element.span([@element.text("Second")]),
        ])
      }),
    ],
    fallback=Some(fn() { @element.text("Fallback") }),
  )
  let html = render(node)
  assert_true(html.contains("<span>First</span>"))
  assert_true(html.contains("<span>Second</span>"))
  assert_false(html.contains("Fallback"))
}

///|
test "render switch with match fallback" {
  let node : @luna.Node[Unit] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() {
        @element.fragment([
          @element.span([@element.text("First")]),
          @element.span([@element.text("Second")]),
        ])
      }),
    ],
    fallback=Some(fn() { @element.text("Fallback") }),
  )
  let html = render(node)
  assert_false(html.contains("<span>First</span>"))
  assert_false(html.contains("<span>Second</span>"))
  assert_true(html.contains("Fallback"))
}
