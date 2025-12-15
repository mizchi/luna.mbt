///|
/// Tests for server_dom module
test "render simple div" {
  let node = @element.div(children=[@element.text("Hello")])
  let html = render(node)
  assert_eq(html, "<div>Hello</div>")
}

///|
test "render div with attributes" {
  let node = @element.div(
    id="main",
    class="container",
    children=[@element.text("Content")],
  )
  let html = render(node)
  assert_true(html.contains("id=\"main\""))
  assert_true(html.contains("class=\"container\""))
  assert_true(html.contains("Content"))
}

///|
test "render nested elements" {
  let node = @element.div(children=[
    @element.h1(children=[@element.text("Title")]),
    @element.p(children=[@element.text("Paragraph")]),
  ])
  let html = render(node)
  assert_true(html.contains("<h1>Title</h1>"))
  assert_true(html.contains("<p>Paragraph</p>"))
}

///|
test "render html document structure" {
  let node = @element.html(lang="en", children=[
    @element.head(children=[@element.title("My Page")]),
    @element.body(children=[@element.h1(children=[@element.text("Hello")])]),
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
    body_children=[@element.p(children=[@element.text("Hello World")])],
  )
  let html = render_document(node)
  assert_true(html.has_prefix("<!DOCTYPE html>"))
  assert_true(html.contains("<html lang=\"ja\">"))
  assert_true(html.contains("<meta charset=\"UTF-8\" />"))
}

///|
test "render void elements" {
  let node = @element.div(children=[
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
  let node = @element.ul(children=[
    @element.li(children=[@element.text("Item 1")]),
    @element.li(children=[@element.text("Item 2")]),
  ])
  let html = render(node)
  assert_true(html.contains("<ul>"))
  assert_true(html.contains("<li>Item 1</li>"))
  assert_true(html.contains("<li>Item 2</li>"))
}

///|
test "render anchor with href" {
  let node = @element.a(href="https://example.com", target="_blank", children=[
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
  let node = island(
    "counter",
    "/components/counter.js",
    state="{\"count\":0}",
    children=[@element.text("Loading...")],
  )
  let html = render(node)
  assert_true(html.contains("ln:id=\"counter\""))
  assert_true(html.contains("ln:url=\"/components/counter.js\""))
  assert_true(html.contains("Loading..."))
}

///|
test "render island with visible trigger" {
  let node = island_visible("lazy", "/components/lazy.js", "{}", children=[
    @element.text("Lazy content"),
  ])
  let html = render(node)
  assert_true(html.contains("ln:trigger=\"visible\""))
}

///|
test "render_with_preloads collects island URLs" {
  let node = @element.div(children=[
    island("a", "/a.js", children=[@element.text("A")]),
    island("b", "/b.js", children=[@element.text("B")]),
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
  let node = @element.main_(children=[
    @element.header_(children=[@element.nav(children=[@element.text("Nav")])]),
    @element.section(children=[
      @element.article(children=[@element.text("Content")]),
    ]),
    @element.footer_(children=[@element.text("Footer")]),
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
  let node = @element.p(children=[
    @element.text("<script>alert('xss')</script>"),
  ])
  let html = render(node)
  assert_true(html.contains("&lt;script&gt;"))
  assert_false(html.contains("<script>alert"))
}
