///|
using @test {assert_eq}

//

///|
/// Tests for server_dom module
test "render simple div" {
  let node = @static.div([@static.text("Hello")])
  let html = @static.render(node)
  assert_eq(html, "<div>Hello</div>")
}

///|
test "render div with attributes" {
  let node = @static.div(id="main", class="container", [@static.text("Content")])
  let html = @static.render(node)
  assert_true(html.contains("id=\"main\""))
  assert_true(html.contains("class=\"container\""))
  assert_true(html.contains("Content"))
}

///|
test "render nested elements" {
  let node = @static.div([
    @static.h1([@static.text("Title")]),
    @static.p([@static.text("Paragraph")]),
  ])
  let html = @static.render(node)
  assert_true(html.contains("<h1>Title</h1>"))
  assert_true(html.contains("<p>Paragraph</p>"))
}

///|
test "render html document structure" {
  let node = @static.html(lang="en", [
    @static.head([@static.title("My Page")]),
    @static.body([@static.h1([@static.text("Hello")])]),
  ])
  let html_str = @static.render(node)
  assert_true(html_str.contains("<html lang=\"en\">"))
  assert_true(html_str.contains("<title>My Page</title>"))
  assert_true(html_str.contains("<h1>Hello</h1>"))
}

///|
test "render document helper" {
  let node = @static.document(
    lang="ja",
    head_children=[@static.title("Test"), @static.meta(charset="UTF-8")],
    body_children=[@static.p([@static.text("Hello World")])],
  )
  let html = @static.render_document(node)
  assert_true(html.has_prefix("<!DOCTYPE html>"))
  assert_true(html.contains("<html lang=\"ja\">"))
  assert_true(html.contains("<meta charset=\"UTF-8\" />"))
}

///|
test "render void elements" {
  let node = @static.div([
    @static.img(src="/image.png", alt="test"),
    @static.br(),
    @static.hr(),
  ])
  let html = @static.render(node)
  assert_true(html.contains("<img"))
  assert_true(html.contains("src=\"/image.png\""))
  assert_true(html.contains("<br />"))
  assert_true(html.contains("<hr />"))
}

///|
test "render list elements" {
  let node = @static.ul([
    @static.li([@static.text("Item 1")]),
    @static.li([@static.text("Item 2")]),
  ])
  let html = @static.render(node)
  assert_true(html.contains("<ul>"))
  assert_true(html.contains("<li>Item 1</li>"))
  assert_true(html.contains("<li>Item 2</li>"))
}

///|
test "render anchor with href" {
  let node = @static.a(href="https://example.com", target="_blank", [
    @static.text("Link"),
  ])
  let html = @static.render(node)
  assert_true(html.contains("href=\"https://example.com\""))
  assert_true(html.contains("target=\"_blank\""))
}

///|
test "render script element" {
  let node = @static.script(src="/app.js", type_="module", defer_=true)
  let html = @static.render(node)
  assert_true(html.contains("src=\"/app.js\""))
  assert_true(html.contains("type=\"module\""))
  assert_true(html.contains("defer"))
}

///|
test "render style element" {
  let node = @static.style_("body { margin: 0; }")
  let html = @static.render(node)
  assert_true(html.contains("<style>body { margin: 0; }</style>"))
}

///|
test "render trusted script and style helpers" {
  let node = @static.fragment([
    @static.script_trusted(@static.unsafe_trusted_script("console.log(1)")),
    @static.style_trusted(@static.unsafe_trusted_style("body { color: red; }")),
  ])
  let html = @static.render(node)
  assert_true(html.contains("<script>console.log(1)</script>"))
  assert_true(html.contains("<style>body { color: red; }</style>"))
}

///|
test "render wc_island" {
  let node = @luna.wc_island(
    "wc-counter",
    "/components/counter.js",
    "",
    "{\"count\":0}",
    [@static.text("Loading...")],
  )
  let html = @static.render(node)
  assert_true(html.contains("luna:wc-url=\"/components/counter.js\""))
  assert_true(html.contains("Loading..."))
}

///|
test "render wc_island with visible trigger" {
  let node = @luna.wc_island(
    "wc-lazy",
    "/components/lazy.js",
    "",
    "{}",
    [@static.text("Lazy content")],
    trigger=@core.Visible,
  )
  let html = @static.render(node)
  assert_true(html.contains("luna:wc-trigger=\"visible\""))
}

///|
test "render_with_preloads collects wc_island URLs" {
  let node = @static.div([
    @luna.wc_island("wc-a", "/a.js", "", "{}", [@static.text("A")]),
    @luna.wc_island("wc-b", "/b.js", "", "{}", [@static.text("B")]),
  ])
  let result = @static.render_with_preloads(node)
  assert_eq(result.preload_urls.length(), 2)
  assert_true(result.preload_urls.contains("/a.js"))
  assert_true(result.preload_urls.contains("/b.js"))
}

///|
test "render fragment" {
  let node = @static.fragment([
    @static.text("A"),
    @static.text("B"),
    @static.text("C"),
  ])
  let html = @static.render(node)
  assert_eq(html, "ABC")
}

///|
test "render semantic elements" {
  let node = @static.main_([
    @static.header_([@static.nav([@static.text("Nav")])]),
    @static.section([@static.article([@static.text("Content")])]),
    @static.footer_([@static.text("Footer")]),
  ])
  let html = @static.render(node)
  assert_true(html.contains("<main>"))
  assert_true(html.contains("<header>"))
  assert_true(html.contains("<nav>"))
  assert_true(html.contains("<section>"))
  assert_true(html.contains("<article>"))
  assert_true(html.contains("<footer>"))
}

///|
test "html escaping in text" {
  let node = @static.p([@static.text("<script>alert('xss')</script>")])
  let html = @static.render(node)
  assert_true(html.contains("&lt;script&gt;"))
  assert_false(html.contains("<script>alert"))
}

// =============================================================================
// Error Boundary Tests
// =============================================================================

///|
test "render error_boundary success" {
  let node : @luna.Node[Unit, String] = @luna.error_boundary(
    children=fn() { @static.div([@static.text("Success!")]) },
    fallback=fn(_err, _reset) { @static.text("Error occurred") },
  )
  let html = @static.render(node)
  assert_eq(html, "<div>Success!</div>")
}

///|
test "render error_boundary with nested elements" {
  let node : @luna.Node[Unit, String] = @luna.error_boundary(
    children=fn() {
      @static.div(class="container", [
        @static.h1([@static.text("Title")]),
        @static.p([@static.text("Content")]),
      ])
    },
    fallback=fn(_err, _reset) { @static.text("Error") },
  )
  let html = @static.render(node)
  assert_true(html.contains("<h1>Title</h1>"))
  assert_true(html.contains("<p>Content</p>"))
  assert_true(html.contains("class=\"container\""))
}

///|
test "render error_boundary with wc_island inside" {
  let node : @luna.Node[Unit, String] = @luna.error_boundary(
    children=fn() {
      @static.div([
        @luna.wc_island(
          "wc-counter",
          "/components/counter.js",
          "",
          "{\"count\":0}",
          [@static.text("Loading...")],
        ),
      ])
    },
    fallback=fn(_err, _reset) { @static.text("Error") },
  )
  let html = @static.render(node)
  assert_true(html.contains("luna:wc-url=\"/components/counter.js\""))
}

///|
test "render nested error_boundaries" {
  let node : @luna.Node[Unit, String] = @luna.error_boundary(
    children=fn() {
      @static.div([
        @luna.error_boundary(
          children=fn() { @static.span([@static.text("Inner content")]) },
          fallback=fn(_err, _reset) { @static.text("Inner error") },
        ),
      ])
    },
    fallback=fn(_err, _reset) { @static.text("Outer error") },
  )
  let html = @static.render(node)
  assert_true(html.contains("<span>Inner content</span>"))
}

///|
test "render error_boundary with show" {
  let visible = true
  let node : @luna.Node[Unit, String] = @luna.error_boundary(
    children=fn() {
      @luna.show(fn() { visible }, fn() { @static.text("Visible!") })
    },
    fallback=fn(_err, _reset) { @static.text("Error") },
  )
  let html = @static.render(node)
  assert_eq(html, "Visible!")
}

///|
test "render error_boundary with fragment" {
  let node : @luna.Node[Unit, String] = @luna.error_boundary(
    children=fn() {
      @static.fragment([@static.text("A"), @static.text("B"), @static.text("C")])
    },
    fallback=fn(_err, _reset) { @static.text("Error") },
  )
  let html = @static.render(node)
  assert_eq(html, "ABC")
}

///|
test "render_with_preloads error_boundary collects wc_island URLs" {
  let node : @luna.Node[Unit, String] = @luna.error_boundary(
    children=fn() {
      @static.div([
        @luna.wc_island("wc-a", "/a.js", "", "{}", [@static.text("A")]),
        @luna.wc_island("wc-b", "/b.js", "", "{}", [@static.text("B")]),
      ])
    },
    fallback=fn(_err, _reset) { @static.text("Error") },
  )
  let result = @static.render_with_preloads(node)
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
    @static.fragment([
      @static.div([@static.text("A")]),
      @static.div([@static.text("B")]),
    ])
  })
  let html = @static.render(node)
  assert_true(html.contains("<div>A</div>"))
  assert_true(html.contains("<div>B</div>"))
}

///|
test "render show with fragment (multiple children) - hidden" {
  let visible = false
  let node : @luna.Node[Unit, String] = @luna.show(fn() { visible }, fn() {
    @static.fragment([
      @static.div([@static.text("A")]),
      @static.div([@static.text("B")]),
    ])
  })
  let html = @static.render(node)
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
        @static.fragment([
          @static.span([@static.text("First")]),
          @static.span([@static.text("Second")]),
        ])
      }),
    ],
    fallback=Some(fn() { @static.text("Fallback") }),
  )
  let html = @static.render(node)
  assert_true(html.contains("<span>First</span>"))
  assert_true(html.contains("<span>Second</span>"))
  assert_false(html.contains("Fallback"))
}

///|
test "render switch with match fallback" {
  let node : @luna.Node[Unit, String] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() {
        @static.fragment([
          @static.span([@static.text("First")]),
          @static.span([@static.text("Second")]),
        ])
      }),
    ],
    fallback=Some(fn() { @static.text("Fallback") }),
  )
  let html = @static.render(node)
  assert_false(html.contains("<span>First</span>"))
  assert_false(html.contains("<span>Second</span>"))
  assert_true(html.contains("Fallback"))
}
