// Test enum for action

///|
enum TestAction {
  Increment
  DoSomething
} derive(Show)

///|
test "render_to_stream_collecting_async collects boundaries" {
  let node : @luna.Node[Unit] = @luna.fragment([
    @luna.h("div", [], [@luna.text("Header")]),
    @luna.async_(
      render=async fn() { @luna.h("div", [], [@luna.text("Async 1")]) },
      fallback=fn() { @luna.h("div", [], [@luna.text("Loading 1...")]) },
    ),
    @luna.async_(
      render=async fn() { @luna.h("div", [], [@luna.text("Async 2")]) },
      fallback=fn() { @luna.h("div", [], [@luna.text("Loading 2...")]) },
    ),
    @luna.h("div", [], [@luna.text("Footer")]),
  ])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  let boundaries = render_to_stream_collecting_async(node, writer)

  // Should collect 2 async boundaries
  assert_eq(boundaries.length(), 2)

  // Output should contain fallbacks
  let html = chunks.iter().join("")
  assert_true(html.contains("Loading 1..."))
  assert_true(html.contains("Loading 2..."))
  assert_true(html.contains("Header"))
  assert_true(html.contains("Footer"))

  // Should have placeholder divs with IDs
  assert_true(html.contains("id=\"A:0\""))
  assert_true(html.contains("id=\"A:1\""))
}

///|
test "render_to_stream no async returns empty boundaries" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [@luna.text("Simple")])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  let boundaries = render_to_stream_collecting_async(node, writer)

  // No async nodes = no boundaries
  assert_eq(boundaries.length(), 0)
  let html = chunks.iter().join("")
  assert_eq(html, "<div>Simple</div>")
}

///|
test "render_to_stream nested async" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.async_(
      render=async fn() { @luna.h("span", [], [@luna.text("Loaded")]) },
      fallback=fn() { @luna.h("span", [], [@luna.text("Loading...")]) },
    ),
  ])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  let boundaries = render_to_stream_collecting_async(node, writer)
  assert_eq(boundaries.length(), 1)
  let html = chunks.iter().join("")
  assert_true(html.contains("Loading..."))
  assert_true(html.contains("id=\"A:0\""))
}

// =============================================================================
// ErrorBoundary Tests
// =============================================================================

///|
test "render error_boundary children when no error" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() { @luna.h("div", [], [@luna.text("Success")]) },
    fallback=fn(_err, _reset) { @luna.h("div", [], [@luna.text("Error!")]) },
  )
  let html = @render.render_to_string(node).html
  assert_eq(html, "<div>Success</div>")
}

///|
test "render error_boundary with nested content" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @luna.h("div", [("class", @luna.attr_static("container"))], [
        @luna.h("h1", [], [@luna.text("Title")]),
        @luna.h("p", [], [@luna.text("Content")]),
      ])
    },
    fallback=fn(_err, _reset) { @luna.text("Error") },
  )
  let html = @render.render_to_string(node).html
  assert_true(html.contains("<h1>Title</h1>"))
  assert_true(html.contains("<p>Content</p>"))
}

///|
test "render error_boundary with dynamic content" {
  let count = 42
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @luna.h("div", [], [
        @luna.text_dyn(fn() { "Count: " + count.to_string() }),
      ])
    },
    fallback=fn(_err, _reset) { @luna.text("Error") },
  )
  let html = @render.render_to_string(node).html
  assert_eq(html, "<div>Count: 42</div>")
}

///|
test "render error_boundary with show" {
  let visible = true
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @luna.show(fn() { visible }, fn() { @luna.text("Visible!") })
    },
    fallback=fn(_err, _reset) { @luna.text("Error") },
  )
  let html = @render.render_to_string(node).html
  assert_eq(html, "Visible!")
}

///|
test "render error_boundary with for" {
  let items = ["A", "B", "C"]
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @luna.for_each(fn() {
        let result : Array[@luna.Node[Unit]] = []
        for item in items {
          result.push(@luna.h("li", [], [@luna.text(item)]))
        }
        result
      })
    },
    fallback=fn(_err, _reset) { @luna.text("Error") },
  )
  let html = @render.render_to_string(node).html
  assert_eq(html, "<li>A</li><li>B</li><li>C</li>")
}

///|
test "render error_boundary with hydration markers" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() { @luna.h("div", [], [@luna.text("Content")]) },
    fallback=fn(_err, _reset) { @luna.text("Error") },
  )
  let html = @render.render_to_string_with_hydration(node)
  // Should have error boundary markers
  assert_true(html.contains("<!--eb:"))
  assert_true(html.contains("<!--/eb-->"))
  assert_true(html.contains("Content"))
}

///|
test "render nested error_boundaries" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @luna.h("div", [], [
        @luna.error_boundary(children=fn() { @luna.text("Inner content") }, fallback=fn(
          _err,
          _reset,
        ) {
          @luna.text("Inner error")
        }),
      ])
    },
    fallback=fn(_err, _reset) { @luna.text("Outer error") },
  )
  let html = @render.render_to_string(node).html
  assert_eq(html, "<div>Inner content</div>")
}

///|
test "render error_boundary in island" {
  let node : @luna.Node[Unit] = @luna.island(
    "eb-island-1",
    "/components/test.js",
    "{}",
    [
      @luna.error_boundary(children=fn() { @luna.text("Island content") }, fallback=fn(
        _err,
        _reset,
      ) {
        @luna.text("Error")
      }),
    ],
  )
  let html = @render.render_to_string(node).html
  assert_true(html.contains("luna:id=\"eb-island-1\""))
  assert_true(html.contains("Island content"))
}

///|
test "stream render error_boundary children when no error" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() { @luna.h("div", [], [@luna.text("Stream Success")]) },
    fallback=fn(_err, _reset) { @luna.text("Error") },
  )
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  render_to_stream(node, writer)
  let html = chunks.iter().join("")
  assert_eq(html, "<div>Stream Success</div>")
}

///|
test "stream render error_boundary with async boundaries" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @luna.fragment([
        @luna.h("div", [], [@luna.text("Header")]),
        @luna.async_(render=async fn() { @luna.text("Async content") }, fallback=fn() {
          @luna.text("Loading...")
        }),
      ])
    },
    fallback=fn(_err, _reset) { @luna.text("Error") },
  )
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  let boundaries = render_to_stream_collecting_async(node, writer)
  assert_eq(boundaries.length(), 1)
  let html = chunks.iter().join("")
  assert_true(html.contains("Header"))
  assert_true(html.contains("Loading..."))
}

// =============================================================================
// Additional Coverage Tests
// =============================================================================

///|
test "render_to_string preload=false" {
  let node : @luna.Node[Unit] = @luna.island(
    "island-1",
    "/components/a.js",
    "{}",
    [@luna.text("Content")],
  )
  let result = @render.render_to_string(node, preload=false)
  // Should render correctly but not collect URLs
  assert_eq(result.preload_urls.length(), 0)
  assert_true(result.html.contains("luna:id=\"island-1\""))
}

///|
test "render action attribute" {
  let node : @luna.Node[Unit] = @luna.h(
    "button",
    [("onclick", @luna.action(Increment))],
    [@luna.text("Click")],
  )
  let html = @render.render_to_string(node).html
  // Action should render as data-action-click attribute
  assert_true(html.contains("data-action-click=\"Increment\""))
}

///|
test "render action attribute with enum" {
  let node : @luna.Node[Unit] = @luna.h(
    "button",
    [("onclick", @luna.action(DoSomething))],
    [@luna.text("Click")],
  )
  let html = @render.render_to_string(node).html
  // Action should render as data-action-click attribute
  assert_true(html.contains("data-action-click=\"DoSomething\""))
}

///|
test "render __remove__ attribute" {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [
      ("class", @luna.attr_static("visible")),
      ("hidden", @luna.attr_static("__remove__")),
    ],
    [],
  )
  let html = @render.render_to_string(node).html
  // __remove__ attribute should not appear
  assert_eq(html, "<div class=\"visible\"></div>")
}

///|
test "render switch first case matches" {
  let node : @luna.Node[Unit] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { true }, render=fn() { @luna.text("First") }),
      @luna.match_case(when=fn() { true }, render=fn() { @luna.text("Second") }),
    ],
    fallback=Some(fn() { @luna.text("Fallback") }),
  )
  let html = @render.render_to_string(node).html
  assert_eq(html, "First")
}

///|
test "render switch second case matches" {
  let node : @luna.Node[Unit] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() { @luna.text("First") }),
      @luna.match_case(when=fn() { true }, render=fn() { @luna.text("Second") }),
    ],
    fallback=Some(fn() { @luna.text("Fallback") }),
  )
  let html = @render.render_to_string(node).html
  assert_eq(html, "Second")
}

///|
test "render switch fallback" {
  let node : @luna.Node[Unit] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() { @luna.text("First") }),
      @luna.match_case(when=fn() { false }, render=fn() { @luna.text("Second") }),
    ],
    fallback=Some(fn() { @luna.text("Fallback") }),
  )
  let html = @render.render_to_string(node).html
  assert_eq(html, "Fallback")
}

///|
test "render switch no fallback" {
  let node : @luna.Node[Unit] = @luna.switch_(cases=[
    @luna.match_case(when=fn() { false }, render=fn() { @luna.text("First") }),
  ])
  let html = @render.render_to_string(node).html
  assert_eq(html, "<!--switch-->")
}

///|
test "render switch with preloads" {
  let node : @luna.Node[Unit] = @luna.switch_(cases=[
    @luna.match_case(when=fn() { true }, render=fn() {
      @luna.island("sw-island", "/sw.js", "{}", [@luna.text("Island")])
    }),
  ])
  let result = @render.render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 1)
  assert_true(result.preload_urls.contains("/sw.js"))
}

///|
test "render switch with hydration markers case match" {
  let node : @luna.Node[Unit] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { true }, render=fn() { @luna.text("Matched") }),
    ],
    fallback=Some(fn() { @luna.text("Fallback") }),
  )
  let html = @render.render_to_string_with_hydration(node)
  assert_true(html.contains("<!--sw:"))
  assert_true(html.contains("<!--/sw-->"))
  assert_true(html.contains("Matched"))
}

///|
test "render switch with hydration markers fallback" {
  let node : @luna.Node[Unit] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() { @luna.text("Never") }),
    ],
    fallback=Some(fn() { @luna.text("Fallback") }),
  )
  let html = @render.render_to_string_with_hydration(node)
  assert_true(html.contains("<!--sw:"))
  assert_true(html.contains("<!--/sw-->"))
  assert_true(html.contains("Fallback"))
}

///|
test "render switch with hydration markers no fallback" {
  let node : @luna.Node[Unit] = @luna.switch_(cases=[
    @luna.match_case(when=fn() { false }, render=fn() { @luna.text("Never") }),
  ])
  let html = @render.render_to_string_with_hydration(node)
  assert_true(html.contains("<!--sw:"))
  assert_true(html.contains("<!--/sw-->"))
  // Should be empty between markers
}

///|
test "stream render switch first case" {
  let node : @luna.Node[Unit] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { true }, render=fn() {
        @luna.text("Stream First")
      }),
    ],
    fallback=Some(fn() { @luna.text("Fallback") }),
  )
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  render_to_stream(node, writer)
  let html = chunks.iter().join("")
  assert_eq(html, "Stream First")
}

///|
test "stream render switch fallback" {
  let node : @luna.Node[Unit] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() { @luna.text("Never") }),
    ],
    fallback=Some(fn() { @luna.text("Stream Fallback") }),
  )
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  render_to_stream(node, writer)
  let html = chunks.iter().join("")
  assert_eq(html, "Stream Fallback")
}

///|
test "stream render switch no fallback" {
  let node : @luna.Node[Unit] = @luna.switch_(cases=[
    @luna.match_case(when=fn() { false }, render=fn() { @luna.text("Never") }),
  ])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  render_to_stream(node, writer)
  let html = chunks.iter().join("")
  assert_eq(html, "<!--switch-->")
}

///|
test "stream render collecting async switch" {
  let node : @luna.Node[Unit] = @luna.switch_(cases=[
    @luna.match_case(when=fn() { true }, render=fn() {
      @luna.async_(render=async fn() { @luna.text("Loaded") }, fallback=fn() {
        @luna.text("Loading...")
      })
    }),
  ])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  let boundaries = render_to_stream_collecting_async(node, writer)
  assert_eq(boundaries.length(), 1)
  let html = chunks.iter().join("")
  assert_true(html.contains("Loading..."))
}

///|
test "render_to_string returns SSRResult with html field" {
  // Test that render_to_string returns SSRResult
  let node : @luna.Node[Unit] = @luna.text("Hello")
  let result = @render.render_to_string(node)
  assert_eq(result.html, "Hello")
  assert_eq(result.preload_urls.length(), 0)
}

///|
test "stream_async_replacement" {
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  stream_async_replacement(42, writer, fn(w) { (w.0)("Replaced Content") })
  let html = chunks.iter().join("")
  assert_true(html.contains("<template id=\"T:42\">"))
  assert_true(html.contains("Replaced Content"))
  assert_true(html.contains("</template>"))
  assert_true(html.contains("<script>"))
  assert_true(html.contains("document.getElementById('T:42')"))
  assert_true(html.contains("document.getElementById('A:42')"))
}

///|
test "escape_attr with special characters" {
  // Test less-than and greater-than in attributes (should pass through)
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [("data-expr", @luna.attr_static("a < b"))],
    [],
  )
  let html = @render.render_to_string(node).html
  // < should NOT be escaped in attributes
  assert_eq(html, "<div data-expr=\"a < b\"></div>")
}

// ============================================================================
// escape.mbt tests
// ============================================================================

///|
test "needs_html_escape - returns false for safe strings" {
  assert_eq(@render.needs_html_escape("Hello World"), false)
  assert_eq(@render.needs_html_escape("12345"), false)
  assert_eq(@render.needs_html_escape(""), false)
}

///|
test "needs_html_escape - returns true for dangerous characters" {
  assert_eq(@render.needs_html_escape("a < b"), true)
  assert_eq(@render.needs_html_escape("a > b"), true)
  assert_eq(@render.needs_html_escape("Tom & Jerry"), true)
  assert_eq(@render.needs_html_escape("\"quoted\""), true)
  assert_eq(@render.needs_html_escape("it's"), true)
}

///|
test "escape_html - passes through safe strings" {
  let safe = "Hello World"
  assert_eq(@render.escape_html(safe), safe)
}

///|
test "escape_html - escapes all dangerous characters" {
  assert_eq(@render.escape_html("<script>"), "&lt;script&gt;")
  assert_eq(@render.escape_html("&nbsp;"), "&amp;nbsp;")
  assert_eq(@render.escape_html("\"quote\""), "&quot;quote&quot;")
  assert_eq(@render.escape_html("it's"), "it&#39;s")
}

///|
test "escape_html_to - writes to StringBuilder" {
  let sb = StringBuilder::new()
  @render.escape_html_to(sb, "<div>")
  assert_eq(sb.to_string(), "&lt;div&gt;")
}

///|
test "needs_attr_escape - only & and quote need escaping" {
  assert_eq(@render.needs_attr_escape("Hello World"), false)
  assert_eq(@render.needs_attr_escape("a < b"), false) // < is safe in attributes
  assert_eq(@render.needs_attr_escape("a > b"), false) // > is safe in attributes
  assert_eq(@render.needs_attr_escape("&nbsp;"), true)
  assert_eq(@render.needs_attr_escape("\"quoted\""), true)
}

///|
test "escape_attr - escapes & and quote only" {
  assert_eq(@render.escape_attr("a < b"), "a < b")
  assert_eq(@render.escape_attr("Tom & Jerry"), "Tom &amp; Jerry")
  assert_eq(@render.escape_attr("say \"hi\""), "say &quot;hi&quot;")
}

///|
test "escape_attr_to - writes to StringBuilder" {
  let sb = StringBuilder::new()
  @render.escape_attr_to(sb, "Tom & \"Jerry\"")
  assert_eq(sb.to_string(), "Tom &amp; &quot;Jerry&quot;")
}

///|
test "escape_js_string - escapes control characters" {
  assert_eq(@render.escape_js_string("line1\nline2"), "line1\\nline2")
  assert_eq(@render.escape_js_string("tab\there"), "tab\\there")
  assert_eq(@render.escape_js_string("return\rhere"), "return\\rhere")
}

///|
test "escape_js_string - escapes quotes and backslash" {
  assert_eq(@render.escape_js_string("say \"hi\""), "say \\\"hi\\\"")
  assert_eq(@render.escape_js_string("path\\to\\file"), "path\\\\to\\\\file")
}

///|
test "escape_js_string - prevents script injection" {
  let dangerous = "</script><script>alert(1)"
  let escaped = @render.escape_js_string(dangerous)
  assert_true(escaped.contains("\\u003c/script\\u003e"))
  assert_true(not(escaped.contains("</script>")))
}

///|
test "is_void_element - recognizes void elements" {
  assert_eq(@render.is_void_element("br"), true)
  assert_eq(@render.is_void_element("hr"), true)
  assert_eq(@render.is_void_element("img"), true)
  assert_eq(@render.is_void_element("input"), true)
  assert_eq(@render.is_void_element("meta"), true)
  assert_eq(@render.is_void_element("link"), true)
  assert_eq(@render.is_void_element("area"), true)
  assert_eq(@render.is_void_element("base"), true)
  assert_eq(@render.is_void_element("col"), true)
  assert_eq(@render.is_void_element("wbr"), true)
  assert_eq(@render.is_void_element("embed"), true)
  assert_eq(@render.is_void_element("track"), true)
  assert_eq(@render.is_void_element("param"), true)
  assert_eq(@render.is_void_element("source"), true)
  assert_eq(@render.is_void_element("keygen"), true)
}

///|
test "is_void_element - returns false for regular elements" {
  assert_eq(@render.is_void_element("div"), false)
  assert_eq(@render.is_void_element("span"), false)
  assert_eq(@render.is_void_element("p"), false)
  assert_eq(@render.is_void_element("a"), false)
  assert_eq(@render.is_void_element("button"), false)
  assert_eq(@render.is_void_element("section"), false)
}

///|
test "is_void_element - handles edge cases" {
  assert_eq(@render.is_void_element(""), false)
  assert_eq(@render.is_void_element("x"), false)
  assert_eq(@render.is_void_element("verylong"), false)
}
