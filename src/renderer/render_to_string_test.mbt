///|
/// SSR Tests - Pure MoonBit
///
/// Type alias for SSR nodes (Event type = Unit)

// Test enum for action
enum TestAction {
  Increment
  DoSomething
} derive(Show)

test "render simple text" {
  let node : @luna.Node[Unit] = @luna.vtext("Hello, World!")
  let html = render_to_string(node).html
  assert_eq(html, "Hello, World!")
}

///|
test "render escaped text" {
  let node : @luna.Node[Unit] = @luna.vtext("<script>alert('xss')</script>")
  let html = render_to_string(node).html
  assert_eq(html, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
}

///|
test "render simple element" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [])
  let html = render_to_string(node).html
  assert_eq(html, "<div></div>")
}

///|
test "render element with text child" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [@luna.vtext("Hello")])
  let html = render_to_string(node).html
  assert_eq(html, "<div>Hello</div>")
}

///|
test "render element with class" {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [("class", @luna.attr_static("container"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<div class=\"container\"></div>")
}

///|
test "render element with multiple attrs" {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [
      ("id", @luna.attr_static("main")),
      ("class", @luna.attr_static("container")),
    ],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<div id=\"main\" class=\"container\"></div>")
}

///|
test "render nested elements" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.h("span", [], [@luna.vtext("nested")]),
  ])
  let html = render_to_string(node).html
  assert_eq(html, "<div><span>nested</span></div>")
}

///|
test "render void element" {
  let node : @luna.Node[Unit] = @luna.h(
    "input",
    [
      ("type", @luna.attr_static("text")),
      ("placeholder", @luna.attr_static("Enter name")),
    ],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<input type=\"text\" placeholder=\"Enter name\" />")
}

///|
test "render br and hr" {
  let node : @luna.Node[Unit] = @luna.vfragment([
    @luna.h("br", [], []),
    @luna.h("hr", [], []),
  ])
  let html = render_to_string(node).html
  assert_eq(html, "<br /><hr />")
}

///|
test "render fragment" {
  let node : @luna.Node[Unit] = @luna.vfragment([
    @luna.vtext("A"),
    @luna.vtext("B"),
    @luna.vtext("C"),
  ])
  let html = render_to_string(node).html
  assert_eq(html, "ABC")
}

///|
test "render dynamic text" {
  let count = 42
  let node : @luna.Node[Unit] = @luna.text_dyn(fn() {
    "Count: " + count.to_string()
  })
  let html = render_to_string(node).html
  assert_eq(html, "Count: 42")
}

///|
test "render dynamic attribute" {
  let active = true
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [
      (
        "class",
        @luna.attr_dynamic(fn() { if active { "active" } else { "inactive" } }),
      ),
    ],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<div class=\"active\"></div>")
}

///|
test "render style attribute" {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [("style", @luna.attr_style("color: red; font-size: 16px"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<div style=\"color: red; font-size: 16px\"></div>")
}

///|
test "render disabled attribute true" {
  let node : @luna.Node[Unit] = @luna.h(
    "button",
    [("disabled", @luna.attr_static(""))],
    [@luna.vtext("Submit")],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<button disabled>Submit</button>")
}

///|
test "render disabled attribute false" {
  let node : @luna.Node[Unit] = @luna.h("button", [], [@luna.vtext("Submit")])
  let html = render_to_string(node).html
  assert_eq(html, "<button>Submit</button>")
}

///|
test "render show when true" {
  let visible = true
  let node : @luna.Node[Unit] = @luna.vshow(fn() { visible }, fn() {
    @luna.vtext("Visible!")
  })
  let html = render_to_string(node).html
  assert_eq(html, "Visible!")
}

///|
test "render show when false" {
  let visible = false
  let node : @luna.Node[Unit] = @luna.vshow(fn() { visible }, fn() {
    @luna.vtext("Visible!")
  })
  let html = render_to_string(node).html
  assert_eq(html, "<!--show-->")
}

///|
test "render for list" {
  let items = ["A", "B", "C"]
  let node : @luna.Node[Unit] = @luna.vfor(fn() {
    let result : Array[@luna.Node[Unit]] = []
    for i = 0; i < items.length(); i = i + 1 {
      result.push(@luna.h("li", [], [@luna.vtext(items[i])]))
    }
    result
  })
  let html = render_to_string(node).html
  assert_eq(html, "<li>A</li><li>B</li><li>C</li>")
}

///|
test "render component" {
  fn greeting(name : String) -> @luna.Node[Unit] {
    @luna.h("div", [], [@luna.vtext("Hello, " + name + "!")])
  }

  let node : @luna.Node[Unit] = @luna.vcomponent(fn() { greeting("World") })
  let html = render_to_string(node).html
  assert_eq(html, "<div>Hello, World!</div>")
}

///|
test "handlers are not rendered" {
  let node : @luna.Node[Unit] = @luna.h(
    "button",
    [
      ("onClick", @luna.attr_handler(@luna.event_handler())),
      ("class", @luna.attr_static("btn")),
    ],
    [@luna.vtext("Click me")],
  )
  let html = render_to_string(node).html
  // Handler should not appear in output
  assert_eq(html, "<button class=\"btn\">Click me</button>")
}

///|
test "escape attribute value" {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [("data-value", @luna.attr_static("a\"b&c"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<div data-value=\"a&quot;b&amp;c\"></div>")
}

///|
test "render with hydration markers for dynamic text" {
  let count = 5
  let node : @luna.Node[Unit] = @luna.text_dyn(fn() { count.to_string() })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--t:0-->5<!--/t-->")
}

///|
test "render with hydration markers for element with handler" {
  let node : @luna.Node[Unit] = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.event_handler()))],
    [@luna.vtext("Click")],
  )
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<button data-hk=\"0\">Click</button>")
}

///|
test "render with hydration markers for show" {
  let visible = true
  let node : @luna.Node[Unit] = @luna.vshow(fn() { visible }, fn() {
    @luna.vtext("Content")
  })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--s:0-->Content<!--/s-->")
}

///|
test "render with hydration markers for list" {
  let node : @luna.Node[Unit] = @luna.vfor(fn() {
    [@luna.vtext("A"), @luna.vtext("B")]
  })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--f:0-->AB<!--/f-->")
}

///|
test "complex page render" {
  let title = "My App"
  let count = 0
  let items = ["Item 1", "Item 2"]
  let page : @luna.Node[Unit] = @luna.h(
    "div",
    [("class", @luna.attr_static("app"))],
    [
      @luna.h("h1", [], [@luna.vtext(title)]),
      @luna.h("p", [], [
        @luna.vtext("Count: "),
        @luna.text_dyn(fn() { count.to_string() }),
      ]),
      @luna.h("ul", [], [
        @luna.vfor(fn() {
          let result : Array[@luna.Node[Unit]] = []
          for i = 0; i < items.length(); i = i + 1 {
            result.push(@luna.h("li", [], [@luna.vtext(items[i])]))
          }
          result
        }),
      ]),
      @luna.h(
        "button",
        [("onClick", @luna.attr_handler(@luna.event_handler()))],
        [@luna.vtext("Increment")],
      ),
    ],
  )
  let html = render_to_string(page).html
  assert_true(html.contains("<h1>My App</h1>"))
  assert_true(html.contains("Count: 0"))
  assert_true(html.contains("<li>Item 1</li><li>Item 2</li>"))
  assert_true(html.contains("<button>Increment</button>"))
}

// =============================================================================
// Additional SSR Tests (for coverage)
// =============================================================================

///|
test "render text with ampersand" {
  let node : @luna.Node[Unit] = @luna.vtext("Tom & Jerry")
  let html = render_to_string(node).html
  assert_eq(html, "Tom &amp; Jerry")
}

///|
test "render text with double quote" {
  let node : @luna.Node[Unit] = @luna.vtext("Say \"hello\"")
  let html = render_to_string(node).html
  assert_eq(html, "Say &quot;hello&quot;")
}

///|
test "render void elements img" {
  let node : @luna.Node[Unit] = @luna.h(
    "img",
    [("src", @luna.attr_static("/image.png"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<img src=\"/image.png\" />")
}

///|
test "render void element col" {
  let node : @luna.Node[Unit] = @luna.h(
    "col",
    [("span", @luna.attr_static("2"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<col span=\"2\" />")
}

///|
test "render void element wbr" {
  let node : @luna.Node[Unit] = @luna.h("wbr", [], [])
  let html = render_to_string(node).html
  assert_eq(html, "<wbr />")
}

///|
test "render void element area" {
  let node : @luna.Node[Unit] = @luna.h(
    "area",
    [("shape", @luna.attr_static("rect"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<area shape=\"rect\" />")
}

///|
test "render void element base" {
  let node : @luna.Node[Unit] = @luna.h(
    "base",
    [("href", @luna.attr_static("/"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<base href=\"/\" />")
}

///|
test "render void element link" {
  let node : @luna.Node[Unit] = @luna.h(
    "link",
    [("rel", @luna.attr_static("stylesheet"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<link rel=\"stylesheet\" />")
}

///|
test "render void element meta" {
  let node : @luna.Node[Unit] = @luna.h(
    "meta",
    [("charset", @luna.attr_static("utf-8"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<meta charset=\"utf-8\" />")
}

///|
test "render void element embed" {
  let node : @luna.Node[Unit] = @luna.h(
    "embed",
    [("src", @luna.attr_static("/video.swf"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<embed src=\"/video.swf\" />")
}

///|
test "render void element track" {
  let node : @luna.Node[Unit] = @luna.h(
    "track",
    [("kind", @luna.attr_static("subtitles"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<track kind=\"subtitles\" />")
}

///|
test "render void element source" {
  let node : @luna.Node[Unit] = @luna.h(
    "source",
    [("src", @luna.attr_static("/audio.mp3"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<source src=\"/audio.mp3\" />")
}

///|
test "render non-void element with length 7" {
  // "section" has length 7, should not be void element
  let node : @luna.Node[Unit] = @luna.h("section", [], [@luna.vtext("content")])
  let html = render_to_string(node).html
  assert_eq(html, "<section>content</section>")
}

///|
test "render dynamic style" {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [("style", @luna.attr_dynamic_style(fn() { "color: blue; margin: 10px" }))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<div style=\"color: blue; margin: 10px\"></div>")
}

///|
test "render empty dynamic style" {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [("style", @luna.attr_dynamic_style(fn() { "" }))],
    [],
  )
  let html = render_to_string(node).html
  // Empty string results in empty style attribute (no quotes needed)
  assert_eq(html, "<div style></div>")
}

// =============================================================================
// Island Node Tests
// =============================================================================

///|
test "render island basic" {
  let node : @luna.Node[Unit] = @luna.visland(
    "counter-1",
    "/components/counter.js",
    "{\"count\":5}",
    [
      @luna.h("span", [("data-count", @luna.attr_static(""))], [
        @luna.vtext("5"),
      ]),
    ],
  )
  let html = render_to_string(node).html
  // Check comment markers
  assert_true(
    html.contains(
      "<!--ln:island:counter-1 url=/components/counter.js trigger=load-->",
    ),
  )
  assert_true(html.contains("<!--/ln:island:counter-1-->"))
  // Check wrapper div with ln:* attributes
  assert_true(html.contains("ln:id=\"counter-1\""))
  assert_true(html.contains("ln:url=\"/components/counter.js\""))
  assert_true(html.contains("ln:state=\"{&quot;count&quot;:5}\""))
  assert_true(html.contains("ln:trigger=\"load\""))
  // Check children are rendered
  assert_true(html.contains("<span data-count>5</span>"))
}

///|
test "render island with idle trigger" {
  let node : @luna.Node[Unit] = @luna.visland(
    "lazy-1",
    "/components/lazy.js",
    "{}",
    [@luna.vtext("Loading...")],
    trigger=@luna.Idle,
  )
  let html = render_to_string(node).html
  assert_true(html.contains("ln:trigger=\"idle\""))
  assert_true(html.contains("trigger=idle-->"))
}

///|
test "render island with visible trigger" {
  let node : @luna.Node[Unit] = @luna.visland(
    "lazy-2",
    "/components/lazy.js",
    "{}",
    [@luna.vtext("Loading...")],
    trigger=@luna.Visible,
  )
  let html = render_to_string(node).html
  assert_true(html.contains("ln:trigger=\"visible\""))
  assert_true(html.contains("trigger=visible-->"))
}

///|
test "render island with media trigger" {
  let node : @luna.Node[Unit] = @luna.visland(
    "responsive-1",
    "/components/responsive.js",
    "{}",
    [@luna.vtext("Content")],
    trigger=@luna.Media("(min-width: 768px)"),
  )
  let html = render_to_string(node).html
  assert_true(html.contains("ln:trigger=\"media:(min-width: 768px)\""))
  assert_true(html.contains("trigger=media:(min-width: 768px)-->"))
}

///|
test "render nested islands" {
  let inner_island : @luna.Node[Unit] = @luna.visland(
    "inner-1",
    "/components/inner.js",
    "{\"value\":42}",
    [@luna.vtext("Inner")],
  )
  let outer_island : @luna.Node[Unit] = @luna.visland(
    "outer-1",
    "/components/outer.js",
    "{}",
    [@luna.h("div", [], [inner_island])],
  )
  let html = render_to_string(outer_island).html
  // Check both islands are present
  assert_true(html.contains("ln:id=\"outer-1\""))
  assert_true(html.contains("ln:id=\"inner-1\""))
  assert_true(html.contains("<!--ln:island:outer-1"))
  assert_true(html.contains("<!--ln:island:inner-1"))
  assert_true(html.contains("<!--/ln:island:outer-1-->"))
  assert_true(html.contains("<!--/ln:island:inner-1-->"))
}

///|
test "render island state escaping" {
  // State with special characters that need escaping
  let node : @luna.Node[Unit] = @luna.visland(
    "escape-1",
    "/components/test.js",
    "{\"text\":\"<script>alert(1)</script>\"}",
    [@luna.vtext("Safe")],
  )
  let html = render_to_string(node).html
  // Ensure < and > are NOT in the attribute value (they should be entity-escaped)
  // The attribute value should have &lt; and &gt; or be safe
  assert_true(not(html.contains("ln:state=\"{\"text\":\"<script>")))
}

///|
test "render island with complex children" {
  let count = 3
  let node : @luna.Node[Unit] = @luna.visland(
    "complex-1",
    "/components/complex.js",
    "{\"items\":[\"a\",\"b\",\"c\"]}",
    [
      @luna.h("h2", [], [@luna.vtext("Title")]),
      @luna.h("ul", [], [
        @luna.vfor(fn() {
          let items : Array[@luna.Node[Unit]] = []
          for i = 0; i < count; i = i + 1 {
            items.push(
              @luna.h("li", [], [@luna.vtext("Item " + i.to_string())]),
            )
          }
          items
        }),
      ]),
      @luna.vshow(fn() { true }, fn() { @luna.vtext("Visible text") }),
    ],
  )
  let html = render_to_string(node).html
  assert_true(html.contains("<h2>Title</h2>"))
  assert_true(html.contains("<li>Item 0</li>"))
  assert_true(html.contains("<li>Item 1</li>"))
  assert_true(html.contains("<li>Item 2</li>"))
  assert_true(html.contains("Visible text"))
}

///|
test "render island with hydration markers" {
  let node : @luna.Node[Unit] = @luna.visland(
    "hyd-1",
    "/components/counter.js",
    "{\"count\":10}",
    [@luna.text_dyn(fn() { "10" })],
  )
  let html = render_to_string_with_hydration(node)
  // Should have island markers
  assert_true(html.contains("<!--ln:island:hyd-1"))
  assert_true(html.contains("<!--/ln:island:hyd-1-->"))
  // Should have hydration markers for dynamic text inside
  assert_true(html.contains("<!--t:"))
  assert_true(html.contains("<!--/t-->"))
}

///|
test "trigger_to_string" {
  assert_eq(@luna.trigger_to_string(@luna.Load), "load")
  assert_eq(@luna.trigger_to_string(@luna.Idle), "idle")
  assert_eq(@luna.trigger_to_string(@luna.Visible), "visible")
  assert_eq(
    @luna.trigger_to_string(@luna.Media("(max-width: 600px)")),
    "media:(max-width: 600px)",
  )
}

// =============================================================================
// Escape Utilities Tests
// =============================================================================

///|
test "escape_html basic" {
  assert_eq(escape_html("hello"), "hello")
  assert_eq(escape_html("<script>"), "&lt;script&gt;")
  assert_eq(escape_html("a & b"), "a &amp; b")
  assert_eq(escape_html("\"quoted\""), "&quot;quoted&quot;")
  assert_eq(escape_html("'single'"), "&#39;single&#39;")
}

///|
test "escape_html no escape needed" {
  let s = "simple text without special chars"
  // Should return same string when no escaping needed
  assert_eq(escape_html(s), s)
}

///|
test "escape_attr basic" {
  assert_eq(escape_attr("hello"), "hello")
  assert_eq(escape_attr("a & b"), "a &amp; b")
  assert_eq(escape_attr("\"quoted\""), "&quot;quoted&quot;")
  // Single quotes don't need escaping in attributes
  assert_eq(escape_attr("'single'"), "'single'")
}

///|
test "escape_js_string basic" {
  assert_eq(escape_js_string("hello"), "hello")
  assert_eq(escape_js_string("line1\nline2"), "line1\\nline2")
  assert_eq(escape_js_string("tab\there"), "tab\\there")
  assert_eq(escape_js_string("\"quoted\""), "\\\"quoted\\\"")
  assert_eq(escape_js_string("back\\slash"), "back\\\\slash")
}

///|
test "escape_js_string prevents script injection" {
  let s = "</script><script>alert(1)</script>"
  let escaped = escape_js_string(s)
  // < and > should be unicode escaped
  assert_true(escaped.contains("\\u003c"))
  assert_true(escaped.contains("\\u003e"))
  assert_true(not(escaped.contains("</script>")))
}

///|
test "is_void_element" {
  // Void elements
  assert_true(is_void_element("br"))
  assert_true(is_void_element("hr"))
  assert_true(is_void_element("img"))
  assert_true(is_void_element("input"))
  assert_true(is_void_element("meta"))
  assert_true(is_void_element("link"))
  assert_true(is_void_element("area"))
  assert_true(is_void_element("base"))
  assert_true(is_void_element("col"))
  assert_true(is_void_element("embed"))
  assert_true(is_void_element("source"))
  assert_true(is_void_element("track"))
  assert_true(is_void_element("wbr"))
  assert_true(is_void_element("param"))
  // Non-void elements
  assert_true(not(is_void_element("div")))
  assert_true(not(is_void_element("span")))
  assert_true(not(is_void_element("p")))
  assert_true(not(is_void_element("button")))
  assert_true(not(is_void_element("a")))
}

///|
test "needs_html_escape" {
  assert_true(needs_html_escape("<"))
  assert_true(needs_html_escape(">"))
  assert_true(needs_html_escape("&"))
  assert_true(needs_html_escape("\""))
  assert_true(needs_html_escape("'"))
  assert_true(not(needs_html_escape("hello world")))
  assert_true(not(needs_html_escape("")))
}

///|
test "needs_attr_escape" {
  assert_true(needs_attr_escape("&"))
  assert_true(needs_attr_escape("\""))
  assert_true(not(needs_attr_escape("'")))
  assert_true(not(needs_attr_escape("<")))
  assert_true(not(needs_attr_escape(">")))
  assert_true(not(needs_attr_escape("hello world")))
}

// =============================================================================
// Preload URLs Tests
// =============================================================================

///|
test "render_to_string with preload collects island urls" {
  let node : @luna.Node[Unit] = @luna.vfragment([
    @luna.visland("island-1", "/components/a.js", "{}", [@luna.vtext("A")]),
    @luna.visland("island-2", "/components/b.js", "{}", [@luna.vtext("B")]),
  ])
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 2)
  assert_true(result.preload_urls.contains("/components/a.js"))
  assert_true(result.preload_urls.contains("/components/b.js"))
}

///|
test "render_to_string with preload deduplicates urls" {
  let node : @luna.Node[Unit] = @luna.vfragment([
    @luna.visland("island-1", "/components/shared.js", "{}", [@luna.vtext("A")]),
    @luna.visland("island-2", "/components/shared.js", "{}", [@luna.vtext("B")]),
  ])
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 1)
  assert_true(result.preload_urls.contains("/components/shared.js"))
}

///|
test "generate_preload_tags" {
  let urls = ["/a.js", "/b.js"]
  let tags = generate_preload_tags(urls)
  assert_true(tags.contains("<link rel=\"modulepreload\" href=\"/a.js\">"))
  assert_true(tags.contains("<link rel=\"modulepreload\" href=\"/b.js\">"))
}

///|
test "generate_preload_tags empty" {
  let urls : Array[String] = []
  let tags = generate_preload_tags(urls)
  assert_eq(tags, "")
}

// =============================================================================
// Async Node Tests
// =============================================================================

///|
test "render async fallback in sync mode" {
  let node : @luna.Node[Unit] = @luna.vasync(
    render=async fn() { @luna.h("div", [], [@luna.vtext("Loaded!")]) },
    fallback=fn() { @luna.h("div", [], [@luna.vtext("Loading...")]) },
  )
  // In sync rendering, fallback is rendered
  let html = render_to_string(node).html
  assert_eq(html, "<div>Loading...</div>")
}

///|
test "render async with hydration markers" {
  let node : @luna.Node[Unit] = @luna.vasync(
    render=async fn() { @luna.h("div", [], [@luna.vtext("Loaded!")]) },
    fallback=fn() { @luna.h("div", [], [@luna.vtext("Loading...")]) },
  )
  let html = render_to_string_with_hydration(node)
  // Should have async marker <!--a:ID-->
  assert_true(html.contains("<!--a:"))
  assert_true(html.contains("<!--/a-->"))
  assert_true(html.contains("Loading..."))
}

///|
test "render nested async fallback" {
  let inner : @luna.Node[Unit] = @luna.vasync(
    render=async fn() { @luna.vtext("Inner loaded") },
    fallback=fn() { @luna.vtext("Inner loading...") },
  )
  let outer : @luna.Node[Unit] = @luna.h(
    "div",
    [("class", @luna.attr_static("container"))],
    [inner],
  )
  let html = render_to_string(outer).html
  assert_eq(html, "<div class=\"container\">Inner loading...</div>")
}

///|
test "render async with on_error handler" {
  let node : @luna.Node[Unit] = @luna.vasync(
    render=async fn() { @luna.vtext("Success") },
    fallback=fn() { @luna.vtext("Loading...") },
    on_error=Some(fn(_e) {
      @luna.h("div", [("class", @luna.attr_static("error"))], [
        @luna.vtext("Error occurred"),
      ])
    }),
  )
  // Still renders fallback in sync mode
  let html = render_to_string(node).html
  assert_eq(html, "Loading...")
}

// =============================================================================
// Streaming Async Tests
// =============================================================================

///|
test "render_to_stream_collecting_async collects boundaries" {
  let node : @luna.Node[Unit] = @luna.vfragment([
    @luna.h("div", [], [@luna.vtext("Header")]),
    @luna.vasync(
      render=async fn() { @luna.h("div", [], [@luna.vtext("Async 1")]) },
      fallback=fn() { @luna.h("div", [], [@luna.vtext("Loading 1...")]) },
    ),
    @luna.vasync(
      render=async fn() { @luna.h("div", [], [@luna.vtext("Async 2")]) },
      fallback=fn() { @luna.h("div", [], [@luna.vtext("Loading 2...")]) },
    ),
    @luna.h("div", [], [@luna.vtext("Footer")]),
  ])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  let boundaries = render_to_stream_collecting_async(node, writer)

  // Should collect 2 async boundaries
  assert_eq(boundaries.length(), 2)

  // Output should contain fallbacks
  let html = chunks.iter().fold(init="", fn(acc, chunk) { acc + chunk })
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
  let node : @luna.Node[Unit] = @luna.h("div", [], [@luna.vtext("Simple")])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  let boundaries = render_to_stream_collecting_async(node, writer)

  // No async nodes = no boundaries
  assert_eq(boundaries.length(), 0)
  let html = chunks.iter().fold(init="", fn(acc, chunk) { acc + chunk })
  assert_eq(html, "<div>Simple</div>")
}

///|
test "render_to_stream nested async" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.vasync(
      render=async fn() { @luna.h("span", [], [@luna.vtext("Loaded")]) },
      fallback=fn() { @luna.h("span", [], [@luna.vtext("Loading...")]) },
    ),
  ])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  let boundaries = render_to_stream_collecting_async(node, writer)
  assert_eq(boundaries.length(), 1)
  let html = chunks.iter().fold(init="", fn(acc, chunk) { acc + chunk })
  assert_true(html.contains("Loading..."))
  assert_true(html.contains("id=\"A:0\""))
}

// =============================================================================
// ErrorBoundary Tests
// =============================================================================

///|
test "render error_boundary children when no error" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() { @luna.h("div", [], [@luna.vtext("Success")]) },
    fallback=fn(_err, _reset) { @luna.h("div", [], [@luna.vtext("Error!")]) },
  )
  let html = render_to_string(node).html
  assert_eq(html, "<div>Success</div>")
}

///|
test "render error_boundary with nested content" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @luna.h("div", [("class", @luna.attr_static("container"))], [
        @luna.h("h1", [], [@luna.vtext("Title")]),
        @luna.h("p", [], [@luna.vtext("Content")]),
      ])
    },
    fallback=fn(_err, _reset) { @luna.vtext("Error") },
  )
  let html = render_to_string(node).html
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
    fallback=fn(_err, _reset) { @luna.vtext("Error") },
  )
  let html = render_to_string(node).html
  assert_eq(html, "<div>Count: 42</div>")
}

///|
test "render error_boundary with show" {
  let visible = true
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @luna.vshow(fn() { visible }, fn() { @luna.vtext("Visible!") })
    },
    fallback=fn(_err, _reset) { @luna.vtext("Error") },
  )
  let html = render_to_string(node).html
  assert_eq(html, "Visible!")
}

///|
test "render error_boundary with for" {
  let items = ["A", "B", "C"]
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @luna.vfor(fn() {
        let result : Array[@luna.Node[Unit]] = []
        for item in items {
          result.push(@luna.h("li", [], [@luna.vtext(item)]))
        }
        result
      })
    },
    fallback=fn(_err, _reset) { @luna.vtext("Error") },
  )
  let html = render_to_string(node).html
  assert_eq(html, "<li>A</li><li>B</li><li>C</li>")
}

///|
test "render error_boundary with hydration markers" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() { @luna.h("div", [], [@luna.vtext("Content")]) },
    fallback=fn(_err, _reset) { @luna.vtext("Error") },
  )
  let html = render_to_string_with_hydration(node)
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
        @luna.error_boundary(children=fn() { @luna.vtext("Inner content") }, fallback=fn(
          _err,
          _reset,
        ) {
          @luna.vtext("Inner error")
        }),
      ])
    },
    fallback=fn(_err, _reset) { @luna.vtext("Outer error") },
  )
  let html = render_to_string(node).html
  assert_eq(html, "<div>Inner content</div>")
}

///|
test "render error_boundary in island" {
  let node : @luna.Node[Unit] = @luna.visland(
    "eb-island-1",
    "/components/test.js",
    "{}",
    [
      @luna.error_boundary(children=fn() { @luna.vtext("Island content") }, fallback=fn(
        _err,
        _reset,
      ) {
        @luna.vtext("Error")
      }),
    ],
  )
  let html = render_to_string(node).html
  assert_true(html.contains("ln:id=\"eb-island-1\""))
  assert_true(html.contains("Island content"))
}

///|
test "stream render error_boundary children when no error" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() { @luna.h("div", [], [@luna.vtext("Stream Success")]) },
    fallback=fn(_err, _reset) { @luna.vtext("Error") },
  )
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  render_to_stream(node, writer)
  let html = chunks.iter().fold(init="", fn(acc, chunk) { acc + chunk })
  assert_eq(html, "<div>Stream Success</div>")
}

///|
test "stream render error_boundary with async boundaries" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() {
      @luna.vfragment([
        @luna.h("div", [], [@luna.vtext("Header")]),
        @luna.vasync(render=async fn() { @luna.vtext("Async content") }, fallback=fn() {
          @luna.vtext("Loading...")
        }),
      ])
    },
    fallback=fn(_err, _reset) { @luna.vtext("Error") },
  )
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  let boundaries = render_to_stream_collecting_async(node, writer)
  assert_eq(boundaries.length(), 1)
  let html = chunks.iter().fold(init="", fn(acc, chunk) { acc + chunk })
  assert_true(html.contains("Header"))
  assert_true(html.contains("Loading..."))
}

// =============================================================================
// Additional Coverage Tests
// =============================================================================

///|
test "render_to_string preload=false" {
  let node : @luna.Node[Unit] = @luna.visland(
    "island-1",
    "/components/a.js",
    "{}",
    [@luna.vtext("Content")],
  )
  let result = render_to_string(node, preload=false)
  // Should render correctly but not collect URLs
  assert_eq(result.preload_urls.length(), 0)
  assert_true(result.html.contains("ln:id=\"island-1\""))
}

///|
test "render action attribute" {
  let node : @luna.Node[Unit] = @luna.h(
    "button",
    [("onclick", @luna.action(Increment))],
    [@luna.vtext("Click")],
  )
  let html = render_to_string(node).html
  // Action should render as data-action-click attribute
  assert_true(html.contains("data-action-click=\"Increment\""))
}

///|
test "render action attribute with enum" {
  let node : @luna.Node[Unit] = @luna.h(
    "button",
    [("onclick", @luna.action(DoSomething))],
    [@luna.vtext("Click")],
  )
  let html = render_to_string(node).html
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
  let html = render_to_string(node).html
  // __remove__ attribute should not appear
  assert_eq(html, "<div class=\"visible\"></div>")
}

///|
test "render switch first case matches" {
  let node : @luna.Node[Unit] = @luna.vswitch(
    cases=[
      @luna.match_case(when=fn() { true }, render=fn() { @luna.vtext("First") }),
      @luna.match_case(when=fn() { true }, render=fn() { @luna.vtext("Second") }),
    ],
    fallback=Some(fn() { @luna.vtext("Fallback") }),
  )
  let html = render_to_string(node).html
  assert_eq(html, "First")
}

///|
test "render switch second case matches" {
  let node : @luna.Node[Unit] = @luna.vswitch(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() { @luna.vtext("First") }),
      @luna.match_case(when=fn() { true }, render=fn() { @luna.vtext("Second") }),
    ],
    fallback=Some(fn() { @luna.vtext("Fallback") }),
  )
  let html = render_to_string(node).html
  assert_eq(html, "Second")
}

///|
test "render switch fallback" {
  let node : @luna.Node[Unit] = @luna.vswitch(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() { @luna.vtext("First") }),
      @luna.match_case(when=fn() { false }, render=fn() {
        @luna.vtext("Second")
      }),
    ],
    fallback=Some(fn() { @luna.vtext("Fallback") }),
  )
  let html = render_to_string(node).html
  assert_eq(html, "Fallback")
}

///|
test "render switch no fallback" {
  let node : @luna.Node[Unit] = @luna.vswitch(cases=[
    @luna.match_case(when=fn() { false }, render=fn() { @luna.vtext("First") }),
  ])
  let html = render_to_string(node).html
  assert_eq(html, "<!--switch-->")
}

///|
test "render switch with preloads" {
  let node : @luna.Node[Unit] = @luna.vswitch(cases=[
    @luna.match_case(when=fn() { true }, render=fn() {
      @luna.visland("sw-island", "/sw.js", "{}", [@luna.vtext("Island")])
    }),
  ])
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 1)
  assert_true(result.preload_urls.contains("/sw.js"))
}

///|
test "render switch with hydration markers case match" {
  let node : @luna.Node[Unit] = @luna.vswitch(
    cases=[
      @luna.match_case(when=fn() { true }, render=fn() {
        @luna.vtext("Matched")
      }),
    ],
    fallback=Some(fn() { @luna.vtext("Fallback") }),
  )
  let html = render_to_string_with_hydration(node)
  assert_true(html.contains("<!--sw:"))
  assert_true(html.contains("<!--/sw-->"))
  assert_true(html.contains("Matched"))
}

///|
test "render switch with hydration markers fallback" {
  let node : @luna.Node[Unit] = @luna.vswitch(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() { @luna.vtext("Never") }),
    ],
    fallback=Some(fn() { @luna.vtext("Fallback") }),
  )
  let html = render_to_string_with_hydration(node)
  assert_true(html.contains("<!--sw:"))
  assert_true(html.contains("<!--/sw-->"))
  assert_true(html.contains("Fallback"))
}

///|
test "render switch with hydration markers no fallback" {
  let node : @luna.Node[Unit] = @luna.vswitch(cases=[
    @luna.match_case(when=fn() { false }, render=fn() { @luna.vtext("Never") }),
  ])
  let html = render_to_string_with_hydration(node)
  assert_true(html.contains("<!--sw:"))
  assert_true(html.contains("<!--/sw-->"))
  // Should be empty between markers
}

///|
test "stream render switch first case" {
  let node : @luna.Node[Unit] = @luna.vswitch(
    cases=[
      @luna.match_case(when=fn() { true }, render=fn() {
        @luna.vtext("Stream First")
      }),
    ],
    fallback=Some(fn() { @luna.vtext("Fallback") }),
  )
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  render_to_stream(node, writer)
  let html = chunks.iter().fold(init="", fn(acc, chunk) { acc + chunk })
  assert_eq(html, "Stream First")
}

///|
test "stream render switch fallback" {
  let node : @luna.Node[Unit] = @luna.vswitch(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() { @luna.vtext("Never") }),
    ],
    fallback=Some(fn() { @luna.vtext("Stream Fallback") }),
  )
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  render_to_stream(node, writer)
  let html = chunks.iter().fold(init="", fn(acc, chunk) { acc + chunk })
  assert_eq(html, "Stream Fallback")
}

///|
test "stream render switch no fallback" {
  let node : @luna.Node[Unit] = @luna.vswitch(cases=[
    @luna.match_case(when=fn() { false }, render=fn() { @luna.vtext("Never") }),
  ])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  render_to_stream(node, writer)
  let html = chunks.iter().fold(init="", fn(acc, chunk) { acc + chunk })
  assert_eq(html, "<!--switch-->")
}

///|
test "stream render collecting async switch" {
  let node : @luna.Node[Unit] = @luna.vswitch(cases=[
    @luna.match_case(when=fn() { true }, render=fn() {
      @luna.vasync(render=async fn() { @luna.vtext("Loaded") }, fallback=fn() {
        @luna.vtext("Loading...")
      })
    }),
  ])
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  let boundaries = render_to_stream_collecting_async(node, writer)
  assert_eq(boundaries.length(), 1)
  let html = chunks.iter().fold(init="", fn(acc, chunk) { acc + chunk })
  assert_true(html.contains("Loading..."))
}

///|
test "render_to_string returns SSRResult with html field" {
  // Test that render_to_string returns SSRResult
  let node : @luna.Node[Unit] = @luna.vtext("Hello")
  let result = render_to_string(node)
  assert_eq(result.html, "Hello")
  assert_eq(result.preload_urls.length(), 0)
}

///|
test "stream_async_replacement" {
  let chunks : Array[String] = []
  let writer = StreamWriter::from_callback(fn(chunk) { chunks.push(chunk) })
  stream_async_replacement(42, writer, fn(w) { (w.0)("Replaced Content") })
  let html = chunks.iter().fold(init="", fn(acc, chunk) { acc + chunk })
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
  let html = render_to_string(node).html
  // < should NOT be escaped in attributes
  assert_eq(html, "<div data-expr=\"a < b\"></div>")
}

// ============================================================================
// escape.mbt tests
// ============================================================================

///|
test "needs_html_escape - returns false for safe strings" {
  assert_eq(needs_html_escape("Hello World"), false)
  assert_eq(needs_html_escape("12345"), false)
  assert_eq(needs_html_escape(""), false)
}

///|
test "needs_html_escape - returns true for dangerous characters" {
  assert_eq(needs_html_escape("a < b"), true)
  assert_eq(needs_html_escape("a > b"), true)
  assert_eq(needs_html_escape("Tom & Jerry"), true)
  assert_eq(needs_html_escape("\"quoted\""), true)
  assert_eq(needs_html_escape("it's"), true)
}

///|
test "escape_html - passes through safe strings" {
  let safe = "Hello World"
  assert_eq(escape_html(safe), safe)
}

///|
test "escape_html - escapes all dangerous characters" {
  assert_eq(escape_html("<script>"), "&lt;script&gt;")
  assert_eq(escape_html("&nbsp;"), "&amp;nbsp;")
  assert_eq(escape_html("\"quote\""), "&quot;quote&quot;")
  assert_eq(escape_html("it's"), "it&#39;s")
}

///|
test "escape_html_to - writes to StringBuilder" {
  let sb = StringBuilder::new()
  escape_html_to(sb, "<div>")
  assert_eq(sb.to_string(), "&lt;div&gt;")
}

///|
test "needs_attr_escape - only & and quote need escaping" {
  assert_eq(needs_attr_escape("Hello World"), false)
  assert_eq(needs_attr_escape("a < b"), false) // < is safe in attributes
  assert_eq(needs_attr_escape("a > b"), false) // > is safe in attributes
  assert_eq(needs_attr_escape("&nbsp;"), true)
  assert_eq(needs_attr_escape("\"quoted\""), true)
}

///|
test "escape_attr - escapes & and quote only" {
  assert_eq(escape_attr("a < b"), "a < b")
  assert_eq(escape_attr("Tom & Jerry"), "Tom &amp; Jerry")
  assert_eq(escape_attr("say \"hi\""), "say &quot;hi&quot;")
}

///|
test "escape_attr_to - writes to StringBuilder" {
  let sb = StringBuilder::new()
  escape_attr_to(sb, "Tom & \"Jerry\"")
  assert_eq(sb.to_string(), "Tom &amp; &quot;Jerry&quot;")
}

///|
test "escape_js_string - escapes control characters" {
  assert_eq(escape_js_string("line1\nline2"), "line1\\nline2")
  assert_eq(escape_js_string("tab\there"), "tab\\there")
  assert_eq(escape_js_string("return\rhere"), "return\\rhere")
}

///|
test "escape_js_string - escapes quotes and backslash" {
  assert_eq(escape_js_string("say \"hi\""), "say \\\"hi\\\"")
  assert_eq(escape_js_string("path\\to\\file"), "path\\\\to\\\\file")
}

///|
test "escape_js_string - prevents script injection" {
  let dangerous = "</script><script>alert(1)"
  let escaped = escape_js_string(dangerous)
  assert_true(escaped.contains("\\u003c/script\\u003e"))
  assert_true(not(escaped.contains("</script>")))
}

///|
test "is_void_element - recognizes void elements" {
  assert_eq(is_void_element("br"), true)
  assert_eq(is_void_element("hr"), true)
  assert_eq(is_void_element("img"), true)
  assert_eq(is_void_element("input"), true)
  assert_eq(is_void_element("meta"), true)
  assert_eq(is_void_element("link"), true)
  assert_eq(is_void_element("area"), true)
  assert_eq(is_void_element("base"), true)
  assert_eq(is_void_element("col"), true)
  assert_eq(is_void_element("wbr"), true)
  assert_eq(is_void_element("embed"), true)
  assert_eq(is_void_element("track"), true)
  assert_eq(is_void_element("param"), true)
  assert_eq(is_void_element("source"), true)
  assert_eq(is_void_element("keygen"), true)
}

///|
test "is_void_element - returns false for regular elements" {
  assert_eq(is_void_element("div"), false)
  assert_eq(is_void_element("span"), false)
  assert_eq(is_void_element("p"), false)
  assert_eq(is_void_element("a"), false)
  assert_eq(is_void_element("button"), false)
  assert_eq(is_void_element("section"), false)
}

///|
test "is_void_element - handles edge cases" {
  assert_eq(is_void_element(""), false)
  assert_eq(is_void_element("x"), false)
  assert_eq(is_void_element("verylong"), false)
}
