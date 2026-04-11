///|
/// SSR Tests - Pure MoonBit
/// Type alias for SSR nodes (Event type = Unit)

///|
test "render simple text" {
  let node : @core.Node[Unit, String] = @core.text("Hello, World!")
  let html = render_to_string(node).html
  assert_eq(html, "Hello, World!")
}

///|
test "render escaped text" {
  let node : @core.Node[Unit, String] = @core.text(
    "<script>alert('xss')</script>",
  )
  let html = render_to_string(node).html
  assert_eq(html, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
}

///|
test "render simple element" {
  let node : @core.Node[Unit, String] = @core.h("div", [], [])
  let html = render_to_string(node).html
  assert_eq(html, "<div></div>")
}

///|
test "render element with text child" {
  let node : @core.Node[Unit, String] = @core.h("div", [], [@core.text("Hello")])
  let html = render_to_string(node).html
  assert_eq(html, "<div>Hello</div>")
}

///|
test "render element with class" {
  let node : @core.Node[Unit, String] = @core.h(
    "div",
    [("class", @core.attr_static("container"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<div class=\"container\"></div>")
}

///|
test "render element with multiple attrs" {
  let node : @core.Node[Unit, String] = @core.h(
    "div",
    [
      ("id", @core.attr_static("main")),
      ("class", @core.attr_static("container")),
    ],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<div id=\"main\" class=\"container\"></div>")
}

///|
test "render nested elements" {
  let node : @core.Node[Unit, String] = @core.h("div", [], [
    @core.h("span", [], [@core.text("nested")]),
  ])
  let html = render_to_string(node).html
  assert_eq(html, "<div><span>nested</span></div>")
}

///|
test "render void element" {
  let node : @core.Node[Unit, String] = @core.h(
    "input",
    [
      ("type", @core.attr_static("text")),
      ("placeholder", @core.attr_static("Enter name")),
    ],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<input type=\"text\" placeholder=\"Enter name\" />")
}

///|
test "render br and hr" {
  let node : @core.Node[Unit, String] = @core.fragment([
    @core.h("br", [], []),
    @core.h("hr", [], []),
  ])
  let html = render_to_string(node).html
  assert_eq(html, "<br /><hr />")
}

///|
test "render fragment" {
  let node : @core.Node[Unit, String] = @core.fragment([
    @core.text("A"),
    @core.text("B"),
    @core.text("C"),
  ])
  let html = render_to_string(node).html
  assert_eq(html, "ABC")
}

///|
test "render dynamic text" {
  let count = 42
  let node : @core.Node[Unit, String] = @core.text_dyn(fn() {
    "Count: " + count.to_string()
  })
  let html = render_to_string(node).html
  assert_eq(html, "Count: 42")
}

///|
test "render dynamic attribute" {
  let active = true
  let node : @core.Node[Unit, String] = @core.h(
    "div",
    [
      (
        "class",
        @core.attr_dynamic(fn() { if active { "active" } else { "inactive" } }),
      ),
    ],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<div class=\"active\"></div>")
}

///|
test "render style attribute" {
  let node : @core.Node[Unit, String] = @core.h(
    "div",
    [("style", @core.attr_style("color: red; font-size: 16px"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<div style=\"color: red; font-size: 16px\"></div>")
}

///|
test "render disabled attribute true" {
  let node : @core.Node[Unit, String] = @core.h(
    "button",
    [("disabled", @core.attr_static(""))],
    [@core.text("Submit")],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<button disabled>Submit</button>")
}

///|
test "render disabled attribute false" {
  let node : @core.Node[Unit, String] = @core.h("button", [], [
    @core.text("Submit"),
  ])
  let html = render_to_string(node).html
  assert_eq(html, "<button>Submit</button>")
}

///|
test "render show when true" {
  let visible = true
  let node : @core.Node[Unit, String] = @core.show(fn() { visible }, fn() {
    @core.text("Visible!")
  })
  let html = render_to_string(node).html
  assert_eq(html, "Visible!")
}

///|
test "render show when false" {
  let visible = false
  let node : @core.Node[Unit, String] = @core.show(fn() { visible }, fn() {
    @core.text("Visible!")
  })
  let html = render_to_string(node).html
  assert_eq(html, "<!--show-->")
}

///|
test "render for list" {
  let items = ["A", "B", "C"]
  let node : @core.Node[Unit, String] = @core.for_each(fn() {
    items.map(fn(item) { @core.h("li", [], [@core.text(item)]) })
  })
  let html = render_to_string(node).html
  assert_eq(html, "<li>A</li><li>B</li><li>C</li>")
}

///|
test "render component" {
  fn greeting(name : String) -> @core.Node[Unit, String] {
    @core.h("div", [], [@core.text("Hello, " + name + "!")])
  }

  let node : @core.Node[Unit, String] = @core.component(fn() {
    greeting("World")
  })
  let html = render_to_string(node).html
  assert_eq(html, "<div>Hello, World!</div>")
}

///|
test "handlers are not rendered" {
  let node : @core.Node[Unit, String] = @core.h(
    "button",
    [
      ("onClick", @core.attr_handler(@core.event_handler())),
      ("class", @core.attr_static("btn")),
    ],
    [@core.text("Click me")],
  )
  let html = render_to_string(node).html
  // Handler should not appear in output
  assert_eq(html, "<button class=\"btn\">Click me</button>")
}

///|
test "escape attribute value" {
  let node : @core.Node[Unit, String] = @core.h(
    "div",
    [("data-value", @core.attr_static("a\"b&c"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<div data-value=\"a&quot;b&amp;c\"></div>")
}

///|
test "render with hydration markers for dynamic text" {
  let count = 5
  let node : @core.Node[Unit, String] = @core.text_dyn(fn() {
    count.to_string()
  })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--t:0-->5<!--/t-->")
}

///|
test "render with hydration markers for element with handler" {
  let node : @core.Node[Unit, String] = @core.h(
    "button",
    [("onClick", @core.attr_handler(@core.event_handler()))],
    [@core.text("Click")],
  )
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<button sol:hk=\"0\">Click</button>")
}

///|
test "render with hydration markers for show" {
  let visible = true
  let node : @core.Node[Unit, String] = @core.show(fn() { visible }, fn() {
    @core.text("Content")
  })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--s:0-->Content<!--/s-->")
}

///|
test "render with hydration markers for list" {
  let node : @core.Node[Unit, String] = @core.for_each(fn() {
    [@core.text("A"), @core.text("B")]
  })
  let html = render_to_string_with_hydration(node)
  assert_eq(
    html, "<!--f:0--><!--fi:0-->A<!--/fi:0--><!--fi:0-->B<!--/fi:0--><!--/f-->",
  )
}

///|
test "complex page render" {
  let title = "My App"
  let count = 0
  let items = ["Item 1", "Item 2"]
  let page : @core.Node[Unit, String] = @core.h(
    "div",
    [("class", @core.attr_static("app"))],
    [
      @core.h("h1", [], [@core.text(title)]),
      @core.h("p", [], [
        @core.text("Count: "),
        @core.text_dyn(fn() { count.to_string() }),
      ]),
      @core.h("ul", [], [
        @core.for_each(fn() {
          items.map(fn(item) { @core.h("li", [], [@core.text(item)]) })
        }),
      ]),
      @core.h(
        "button",
        [("onClick", @core.attr_handler(@core.event_handler()))],
        [@core.text("Increment")],
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
  let node : @core.Node[Unit, String] = @core.text("Tom & Jerry")
  let html = render_to_string(node).html
  assert_eq(html, "Tom &amp; Jerry")
}

///|
test "render text with double quote" {
  let node : @core.Node[Unit, String] = @core.text("Say \"hello\"")
  let html = render_to_string(node).html
  assert_eq(html, "Say &quot;hello&quot;")
}

///|
test "render void elements img" {
  let node : @core.Node[Unit, String] = @core.h(
    "img",
    [("src", @core.attr_static("/image.png"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<img src=\"/image.png\" />")
}

///|
test "render void element col" {
  let node : @core.Node[Unit, String] = @core.h(
    "col",
    [("span", @core.attr_static("2"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<col span=\"2\" />")
}

///|
test "render void element wbr" {
  let node : @core.Node[Unit, String] = @core.h("wbr", [], [])
  let html = render_to_string(node).html
  assert_eq(html, "<wbr />")
}

///|
test "render void element area" {
  let node : @core.Node[Unit, String] = @core.h(
    "area",
    [("shape", @core.attr_static("rect"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<area shape=\"rect\" />")
}

///|
test "render void element base" {
  let node : @core.Node[Unit, String] = @core.h(
    "base",
    [("href", @core.attr_static("/"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<base href=\"/\" />")
}

///|
test "render void element link" {
  let node : @core.Node[Unit, String] = @core.h(
    "link",
    [("rel", @core.attr_static("stylesheet"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<link rel=\"stylesheet\" />")
}

///|
test "render void element meta" {
  let node : @core.Node[Unit, String] = @core.h(
    "meta",
    [("charset", @core.attr_static("utf-8"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<meta charset=\"utf-8\" />")
}

///|
test "render void element embed" {
  let node : @core.Node[Unit, String] = @core.h(
    "embed",
    [("src", @core.attr_static("/video.swf"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<embed src=\"/video.swf\" />")
}

///|
test "render void element track" {
  let node : @core.Node[Unit, String] = @core.h(
    "track",
    [("kind", @core.attr_static("subtitles"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<track kind=\"subtitles\" />")
}

///|
test "render void element source" {
  let node : @core.Node[Unit, String] = @core.h(
    "source",
    [("src", @core.attr_static("/audio.mp3"))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<source src=\"/audio.mp3\" />")
}

///|
test "render non-void element with length 7" {
  // "section" has length 7, should not be void element
  let node : @core.Node[Unit, String] = @core.h("section", [], [
    @core.text("content"),
  ])
  let html = render_to_string(node).html
  assert_eq(html, "<section>content</section>")
}

///|
test "render dynamic style" {
  let node : @core.Node[Unit, String] = @core.h(
    "div",
    [("style", @core.attr_dynamic_style(fn() { "color: blue; margin: 10px" }))],
    [],
  )
  let html = render_to_string(node).html
  assert_eq(html, "<div style=\"color: blue; margin: 10px\"></div>")
}

///|
test "render empty dynamic style" {
  let node : @core.Node[Unit, String] = @core.h(
    "div",
    [("style", @core.attr_dynamic_style(fn() { "" }))],
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
  let node : @core.Node[Unit, String] = @core.island(
    "counter-1",
    "/components/counter.js",
    "{\"count\":5}",
    [
      @core.h("span", [("data-count", @core.attr_static(""))], [@core.text("5")]),
    ],
  )
  let html = render_to_string(node).html
  // Check comment markers
  assert_true(
    html.contains(
      "<!--luna:island:counter-1 url=/components/counter.js trigger=load-->",
    ),
  )
  assert_true(html.contains("<!--/luna:island:counter-1-->"))
  // Check wrapper div with luna:* attributes
  assert_true(html.contains("luna:id=\"counter-1\""))
  assert_true(html.contains("luna:url=\"/components/counter.js\""))
  assert_true(html.contains("luna:state=\"{&quot;count&quot;:5}\""))
  assert_true(html.contains("luna:client-trigger=\"load\""))
  // Check children are rendered
  assert_true(html.contains("<span data-count>5</span>"))
}

///|
test "render island with idle trigger" {
  let node : @core.Node[Unit, String] = @core.island(
    "lazy-1",
    "/components/lazy.js",
    "{}",
    [@core.text("Loading...")],
    trigger=@core.Idle,
  )
  let html = render_to_string(node).html
  assert_true(html.contains("luna:client-trigger=\"idle\""))
  assert_true(html.contains("trigger=idle-->"))
}

///|
test "render island with visible trigger" {
  let node : @core.Node[Unit, String] = @core.island(
    "lazy-2",
    "/components/lazy.js",
    "{}",
    [@core.text("Loading...")],
    trigger=@core.Visible,
  )
  let html = render_to_string(node).html
  assert_true(html.contains("luna:client-trigger=\"visible\""))
  assert_true(html.contains("trigger=visible-->"))
}

///|
test "render island with media trigger" {
  let node : @core.Node[Unit, String] = @core.island(
    "responsive-1",
    "/components/responsive.js",
    "{}",
    [@core.text("Content")],
    trigger=@core.Media("(min-width: 768px)"),
  )
  let html = render_to_string(node).html
  assert_true(html.contains("luna:client-trigger=\"media:(min-width: 768px)\""))
  assert_true(html.contains("trigger=media:(min-width: 768px)-->"))
}

///|
test "render nested islands" {
  let inner_island : @core.Node[Unit, String] = @core.island(
    "inner-1",
    "/components/inner.js",
    "{\"value\":42}",
    [@core.text("Inner")],
  )
  let outer_island : @core.Node[Unit, String] = @core.island(
    "outer-1",
    "/components/outer.js",
    "{}",
    [@core.h("div", [], [inner_island])],
  )
  let html = render_to_string(outer_island).html
  // Check both islands are present
  assert_true(html.contains("luna:id=\"outer-1\""))
  assert_true(html.contains("luna:id=\"inner-1\""))
  assert_true(html.contains("<!--luna:island:outer-1"))
  assert_true(html.contains("<!--luna:island:inner-1"))
  assert_true(html.contains("<!--/luna:island:outer-1-->"))
  assert_true(html.contains("<!--/luna:island:inner-1-->"))
}

///|
test "render island state escaping" {
  // State with special characters that need escaping
  let node : @core.Node[Unit, String] = @core.island(
    "escape-1",
    "/components/test.js",
    "{\"text\":\"<script>alert(1)</script>\"}",
    [@core.text("Safe")],
  )
  let html = render_to_string(node).html
  // Ensure < and > are NOT in the attribute value (they should be entity-escaped)
  // The attribute value should have &lt; and &gt; or be safe
  assert_true(!html.contains("luna:state=\"{\"text\":\"<script>"))
}

///|
test "render island escapes url and trigger attributes" {
  let node : @core.Node[Unit, String] = @core.island(
    "escape-url-1",
    "/components/test.js\" data-x=\"1",
    "{}",
    [@core.text("Safe")],
    trigger=@core.Media("(min-width: \"768px\")"),
  )
  let html = render_to_string(node).html
  assert_true(
    html.contains("luna:url=\"/components/test.js&quot; data-x=&quot;1\""),
  )
  assert_true(
    html.contains(
      "luna:client-trigger=\"media:(min-width: &quot;768px&quot;)\"",
    ),
  )
}

///|
test "render island comment escapes close token in url" {
  let node : @core.Node[Unit, String] = @core.island(
    "escape-comment-1",
    "/components/test.js--><script>alert(1)</script>",
    "{}",
    [@core.text("Safe")],
  )
  let html = render_to_string(node).html
  assert_false(html.contains("url=/components/test.js--><script"))
}

///|
test "render island with complex children" {
  let count = 3
  let node : @core.Node[Unit, String] = @core.island(
    "complex-1",
    "/components/complex.js",
    "{\"items\":[\"a\",\"b\",\"c\"]}",
    [
      @core.h("h2", [], [@core.text("Title")]),
      @core.h("ul", [], [
        @core.for_each(fn() {
          let items : Array[@core.Node[Unit, String]] = []
          for i in 0..<count {
            items.push(@core.h("li", [], [@core.text("Item " + i.to_string())]))
          }
          items
        }),
      ]),
      @core.show(fn() { true }, fn() { @core.text("Visible text") }),
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
  let node : @core.Node[Unit, String] = @core.island(
    "hyd-1",
    "/components/counter.js",
    "{\"count\":10}",
    [@core.text_dyn(fn() { "10" })],
  )
  let html = render_to_string_with_hydration(node)
  // Should have island markers
  assert_true(html.contains("<!--luna:island:hyd-1"))
  assert_true(html.contains("<!--/luna:island:hyd-1-->"))
  // Should have hydration markers for dynamic text inside
  assert_true(html.contains("<!--t:"))
  assert_true(html.contains("<!--/t-->"))
}

///|
test "TriggerType::to_string" {
  assert_eq(@core.Load.to_string(), "load")
  assert_eq(@core.Idle.to_string(), "idle")
  assert_eq(@core.Visible.to_string(), "visible")
  assert_eq(
    @core.Media("(max-width: 600px)").to_string(),
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
  assert_true(!escaped.contains("</script>"))
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
  assert_true(!is_void_element("div"))
  assert_true(!is_void_element("span"))
  assert_true(!is_void_element("p"))
  assert_true(!is_void_element("button"))
  assert_true(!is_void_element("a"))
}

///|
test "needs_html_escape" {
  assert_true(needs_html_escape("<"))
  assert_true(needs_html_escape(">"))
  assert_true(needs_html_escape("&"))
  assert_true(needs_html_escape("\""))
  assert_true(needs_html_escape("'"))
  assert_true(!needs_html_escape("hello world"))
  assert_true(!needs_html_escape(""))
}

///|
test "needs_attr_escape" {
  assert_true(needs_attr_escape("&"))
  assert_true(needs_attr_escape("\""))
  assert_true(!needs_attr_escape("'"))
  assert_true(!needs_attr_escape("<"))
  assert_true(!needs_attr_escape(">"))
  assert_true(!needs_attr_escape("hello world"))
}

// =============================================================================
// Preload URLs Tests
// =============================================================================

///|
test "render_to_string with preload collects island urls" {
  let node : @core.Node[Unit, String] = @core.fragment([
    @core.island("island-1", "/components/a.js", "{}", [@core.text("A")]),
    @core.island("island-2", "/components/b.js", "{}", [@core.text("B")]),
  ])
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 2)
  assert_true(result.preload_urls.contains("/components/a.js"))
  assert_true(result.preload_urls.contains("/components/b.js"))
}

///|
test "render_to_string with preload deduplicates urls" {
  let node : @core.Node[Unit, String] = @core.fragment([
    @core.island("island-1", "/components/shared.js", "{}", [@core.text("A")]),
    @core.island("island-2", "/components/shared.js", "{}", [@core.text("B")]),
  ])
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 1)
  assert_true(result.preload_urls.contains("/components/shared.js"))
}

///|
test "render_to_string with preload skips empty island url" {
  let node : @core.Node[Unit, String] = @core.fragment([
    @core.island("island-empty", "", "{}", [@core.text("A")]),
  ])
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 0)
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

///|
test "generate_preload_tags escapes href attribute" {
  let urls = ["/evil.js\" onload=\"alert(1)"]
  let tags = generate_preload_tags(urls)
  assert_true(tags.contains("&quot;"))
  assert_false(tags.contains("\" onload=\"alert(1)"))
}

///|
test "preload with nested islands in div hierarchy" {
  // div > div > island structure
  let node : @core.Node[Unit, String] = @core.h(
    "div",
    [("class", @core.attr_static("outer"))],
    [
      @core.h("div", [("class", @core.attr_static("middle"))], [
        @core.h("div", [("class", @core.attr_static("inner"))], [
          @core.island("nested-island", "/components/nested.js", "{}", [
            @core.text("Nested"),
          ]),
        ]),
      ]),
    ],
  )
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 1)
  assert_true(result.preload_urls.contains("/components/nested.js"))
  assert_true(result.html.contains("class=\"outer\""))
  assert_true(result.html.contains("class=\"inner\""))
}

///|
test "preload with multiple islands at different nesting levels" {
  // Islands at root, first level, and deeply nested
  let node : @core.Node[Unit, String] = @core.fragment([
    // Root level island
    @core.island("root-island", "/components/root.js", "{}", [
      @core.text("Root"),
    ]),
    // First level nesting
    @core.h("section", [], [
      @core.island("section-island", "/components/section.js", "{}", [
        @core.text("Section"),
      ]),
      // Deeply nested island
      @core.h("article", [], [
        @core.h("div", [], [
          @core.island("deep-island", "/components/deep.js", "{}", [
            @core.text("Deep"),
          ]),
        ]),
      ]),
    ]),
  ])
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 3)
  assert_true(result.preload_urls.contains("/components/root.js"))
  assert_true(result.preload_urls.contains("/components/section.js"))
  assert_true(result.preload_urls.contains("/components/deep.js"))
}

///|
test "preload with conditional show - visible branch" {
  let visible = true
  let node : @core.Node[Unit, String] = @core.show(fn() { visible }, fn() {
    @core.island("conditional-island", "/components/conditional.js", "{}", [
      @core.text("Shown"),
    ])
  })
  let result = render_to_string(node, preload=true)
  // When visible, island URL should be collected
  assert_eq(result.preload_urls.length(), 1)
  assert_true(result.preload_urls.contains("/components/conditional.js"))
}

///|
test "preload with conditional show - hidden branch" {
  let visible = false
  let node : @core.Node[Unit, String] = @core.show(fn() { visible }, fn() {
    @core.island("conditional-island", "/components/conditional.js", "{}", [
      @core.text("Hidden"),
    ])
  })
  let result = render_to_string(node, preload=true)
  // When hidden, island is not rendered so URL is not collected
  assert_eq(result.preload_urls.length(), 0)
}

///|
test "preload with mixed visible and hidden islands" {
  let show_a = true
  let show_b = false
  let show_c = true
  let node : @core.Node[Unit, String] = @core.fragment([
    @core.show(fn() { show_a }, fn() {
      @core.island("island-a", "/components/a.js", "{}", [@core.text("A")])
    }),
    @core.show(fn() { show_b }, fn() {
      @core.island("island-b", "/components/b.js", "{}", [@core.text("B")])
    }),
    @core.show(fn() { show_c }, fn() {
      @core.island("island-c", "/components/c.js", "{}", [@core.text("C")])
    }),
  ])
  let result = render_to_string(node, preload=true)
  // Only visible islands (a and c) should be collected
  assert_eq(result.preload_urls.length(), 2)
  assert_true(result.preload_urls.contains("/components/a.js"))
  assert_false(result.preload_urls.contains("/components/b.js"))
  assert_true(result.preload_urls.contains("/components/c.js"))
}

///|
test "preload with nested conditionals" {
  let outer_visible = true
  let inner_visible = true
  let node : @core.Node[Unit, String] = @core.show(fn() { outer_visible }, fn() {
    @core.h("div", [], [
      @core.island("outer-island", "/components/outer.js", "{}", [
        @core.text("Outer"),
      ]),
      @core.show(fn() { inner_visible }, fn() {
        @core.island("inner-island", "/components/inner.js", "{}", [
          @core.text("Inner"),
        ])
      }),
    ])
  })
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 2)
  assert_true(result.preload_urls.contains("/components/outer.js"))
  assert_true(result.preload_urls.contains("/components/inner.js"))
}

///|
test "preload with nested conditionals - inner hidden" {
  let outer_visible = true
  let inner_visible = false
  let node : @core.Node[Unit, String] = @core.show(fn() { outer_visible }, fn() {
    @core.h("div", [], [
      @core.island("outer-island", "/components/outer.js", "{}", [
        @core.text("Outer"),
      ]),
      @core.show(fn() { inner_visible }, fn() {
        @core.island("inner-island", "/components/inner.js", "{}", [
          @core.text("Inner"),
        ])
      }),
    ])
  })
  let result = render_to_string(node, preload=true)
  // Only outer island is collected (inner is hidden)
  assert_eq(result.preload_urls.length(), 1)
  assert_true(result.preload_urls.contains("/components/outer.js"))
  assert_false(result.preload_urls.contains("/components/inner.js"))
}

///|
test "preload with nested conditionals - outer hidden" {
  let outer_visible = false
  let inner_visible = true
  let node : @core.Node[Unit, String] = @core.show(fn() { outer_visible }, fn() {
    @core.h("div", [], [
      @core.island("outer-island", "/components/outer.js", "{}", [
        @core.text("Outer"),
      ]),
      @core.show(fn() { inner_visible }, fn() {
        @core.island("inner-island", "/components/inner.js", "{}", [
          @core.text("Inner"),
        ])
      }),
    ])
  })
  let result = render_to_string(node, preload=true)
  // When outer is hidden, nothing is rendered so no URLs collected
  assert_eq(result.preload_urls.length(), 0)
}

///|
test "preload with fragment containing islands and elements" {
  let node : @core.Node[Unit, String] = @core.fragment([
    @core.h("header", [], [@core.text("Header")]),
    @core.island("nav-island", "/components/nav.js", "{}", [@core.text("Nav")]),
    @core.h("main", [], [
      @core.h("h1", [], [@core.text("Title")]),
      @core.island("content-island", "/components/content.js", "{}", [
        @core.text("Content"),
      ]),
      @core.h("aside", [], [
        @core.island("sidebar-island", "/components/sidebar.js", "{}", [
          @core.text("Sidebar"),
        ]),
      ]),
    ]),
    @core.h("footer", [], [@core.text("Footer")]),
  ])
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 3)
  assert_true(result.preload_urls.contains("/components/nav.js"))
  assert_true(result.preload_urls.contains("/components/content.js"))
  assert_true(result.preload_urls.contains("/components/sidebar.js"))
  // Verify HTML structure
  assert_true(result.html.contains("<header>Header</header>"))
  assert_true(result.html.contains("<footer>Footer</footer>"))
}

///|
test "preload with duplicate urls in nested structure" {
  // Same component used multiple times at different nesting levels
  let node : @core.Node[Unit, String] = @core.h("div", [], [
    @core.island("counter-1", "/components/counter.js", "{\"count\":1}", [
      @core.text("1"),
    ]),
    @core.h("section", [], [
      @core.island("counter-2", "/components/counter.js", "{\"count\":2}", [
        @core.text("2"),
      ]),
      @core.h("div", [], [
        @core.island("counter-3", "/components/counter.js", "{\"count\":3}", [
          @core.text("3"),
        ]),
      ]),
    ]),
  ])
  let result = render_to_string(node, preload=true)
  // Should deduplicate - only one URL even though component is used 3 times
  assert_eq(result.preload_urls.length(), 1)
  assert_true(result.preload_urls.contains("/components/counter.js"))
}

///|
test "preload disabled returns empty urls" {
  let node : @core.Node[Unit, String] = @core.fragment([
    @core.island("island-1", "/components/a.js", "{}", [@core.text("A")]),
    @core.island("island-2", "/components/b.js", "{}", [@core.text("B")]),
  ])
  let result = render_to_string(node, preload=false)
  // When preload is disabled, URLs array should be empty
  assert_eq(result.preload_urls.length(), 0)
  // But HTML should still be rendered correctly
  assert_true(result.html.contains("luna:url=\"/components/a.js\""))
  assert_true(result.html.contains("luna:url=\"/components/b.js\""))
}

///|
test "preload with wc_island collects luna:wc-url" {
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-counter",
    "/static/wc_counter.js",
    "",
    "{\"count\":0}",
    [@core.text("0")],
  )
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 1)
  assert_true(result.preload_urls.contains("/static/wc_counter.js"))
  assert_true(result.html.contains("luna:wc-url=\"/static/wc_counter.js\""))
}

///|
test "preload with mixed island and wc_island" {
  let node : @core.Node[Unit, String] = @core.fragment([
    @core.island("counter", "/static/counter.js", "{}", [@core.text("Count")]),
    @core.wc_island("wc-timer", "/static/wc_timer.js", "", "{}", [
      @core.text("Timer"),
    ]),
  ])
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 2)
  assert_true(result.preload_urls.contains("/static/counter.js"))
  assert_true(result.preload_urls.contains("/static/wc_timer.js"))
}

///|
test "preload with nested wc_island in div" {
  let node : @core.Node[Unit, String] = @core.h("main", [], [
    @core.h("section", [], [
      @core.wc_island("wc-nested", "/static/wc_nested.js", "", "{}", [
        @core.text("Nested"),
      ]),
    ]),
  ])
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 1)
  assert_true(result.preload_urls.contains("/static/wc_nested.js"))
}

///|
test "preload with wc_island in conditional show" {
  let visible = true
  let node : @core.Node[Unit, String] = @core.show(fn() { visible }, fn() {
    @core.wc_island("wc-conditional", "/static/wc_conditional.js", "", "{}", [
      @core.text("Conditional"),
    ])
  })
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 1)
  assert_true(result.preload_urls.contains("/static/wc_conditional.js"))
}

///|
test "preload with duplicate wc_island urls" {
  let node : @core.Node[Unit, String] = @core.fragment([
    @core.wc_island("wc-counter-1", "/static/wc_counter.js", "", "{\"id\":1}", [
      @core.text("1"),
    ]),
    @core.wc_island("wc-counter-2", "/static/wc_counter.js", "", "{\"id\":2}", [
      @core.text("2"),
    ]),
    @core.wc_island("wc-counter-3", "/static/wc_counter.js", "", "{\"id\":3}", [
      @core.text("3"),
    ]),
  ])
  let result = render_to_string(node, preload=true)
  // Should deduplicate - only one URL
  assert_eq(result.preload_urls.length(), 1)
  assert_true(result.preload_urls.contains("/static/wc_counter.js"))
}

// =============================================================================
// Async Node Tests
// =============================================================================

///|
test "render async fallback in sync mode" {
  let node : @core.Node[Unit, String] = @core.async_(
    render=fn() { @core.h("div", [], [@core.text("Loaded!")]) },
    fallback=fn() { @core.h("div", [], [@core.text("Loading...")]) },
  )
  // In sync rendering, fallback is rendered
  let html = render_to_string(node).html
  assert_eq(html, "<div>Loading...</div>")
}

///|
test "render async with hydration markers" {
  let node : @core.Node[Unit, String] = @core.async_(
    render=fn() { @core.h("div", [], [@core.text("Loaded!")]) },
    fallback=fn() { @core.h("div", [], [@core.text("Loading...")]) },
  )
  let html = render_to_string_with_hydration(node)
  // Should have async marker <!--a:ID-->
  assert_true(html.contains("<!--a:"))
  assert_true(html.contains("<!--/a-->"))
  assert_true(html.contains("Loading..."))
}

///|
test "render nested async fallback" {
  let inner : @core.Node[Unit, String] = @core.async_(
    render=fn() { @core.text("Inner loaded") },
    fallback=fn() { @core.text("Inner loading...") },
  )
  let outer : @core.Node[Unit, String] = @core.h(
    "div",
    [("class", @core.attr_static("container"))],
    [inner],
  )
  let html = render_to_string(outer).html
  assert_eq(html, "<div class=\"container\">Inner loading...</div>")
}

///|
test "render async with on_error handler" {
  let node : @core.Node[Unit, String] = @core.async_(
    render=fn() { @core.text("Success") },
    fallback=fn() { @core.text("Loading...") },
    on_error=Some(fn(_e) {
      @core.h("div", [("class", @core.attr_static("error"))], [
        @core.text("Error occurred"),
      ])
    }),
  )
  // Still renders fallback in sync mode
  let html = render_to_string(node).html
  assert_eq(html, "Loading...")
}

// =============================================================================
// Web Components Island Tests
// =============================================================================

///|
test "render wc_island basic" {
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-counter",
    "/static/wc-counter.js",
    ":host { display: block; }",
    "{\"count\":5}",
    [@core.text("5")],
  )
  let html = render_to_string(node).html
  // Check custom element with data attributes
  assert_true(html.contains("<wc-counter"))
  assert_true(html.contains("luna:wc-url=\"/static/wc-counter.js\""))
  assert_true(html.contains("luna:wc-state=\"{&quot;count&quot;:5}\""))
  // Check Declarative Shadow DOM template
  assert_true(html.contains("<template shadowrootmode=\"open\">"))
  // Style tag now has hash ID for deduplication
  assert_true(html.contains("<style id=\"style-"))
  // CSS is minified: spaces around { } : ; are removed
  assert_true(html.contains(":host{display:block;}"))
  assert_true(html.contains("</style>"))
  // Check children are rendered
  assert_true(html.contains("5"))
  assert_true(html.contains("</template></wc-counter>"))
}

///|
test "render wc_island preserves spaces in css strings" {
  let styles = ".foo::before { content: \"a  b\"; }"
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-css",
    "/static/wc-css.js",
    styles,
    "{}",
    [@core.text("ok")],
  )
  let html = render_to_string(node).html
  // Minifier should keep spaces inside quoted strings
  assert_true(html.contains("content:\"a  b\""))
  // And still minify outside whitespace
  assert_true(html.contains(".foo::before{content:\"a  b\";}"))
}

///|
test "render wc_island without styles" {
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-simple",
    "/static/wc-simple.js",
    "", // empty styles
    "{}",
    [@core.text("Content")],
  )
  let html = render_to_string(node).html
  // Should not have style tag when styles is empty
  assert_true(!html.contains("<style>"))
  assert_true(
    html.contains("<template shadowrootmode=\"open\">Content</template>"),
  )
}

///|
test "render wc_island with idle trigger" {
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-lazy",
    "/static/wc-lazy.js",
    "",
    "{}",
    [@core.text("Loading...")],
    trigger=@core.Idle,
  )
  let html = render_to_string(node).html
  assert_true(html.contains("luna:wc-trigger=\"idle\""))
}

///|
test "render wc_island with visible trigger" {
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-visible",
    "/static/wc-visible.js",
    "",
    "{}",
    [@core.text("Loading...")],
    trigger=@core.Visible,
  )
  let html = render_to_string(node).html
  assert_true(html.contains("luna:wc-trigger=\"visible\""))
}

///|
test "render wc_island with media trigger" {
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-responsive",
    "/static/wc-responsive.js",
    "",
    "{}",
    [@core.text("Content")],
    trigger=@core.Media("(min-width: 768px)"),
  )
  let html = render_to_string(node).html
  assert_true(html.contains("luna:wc-trigger=\"media:(min-width: 768px)\""))
}

///|
test "render wc_island load trigger omits luna:wc-trigger" {
  // Load trigger is the default, should not render luna:wc-trigger attribute
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-default",
    "/static/wc-default.js",
    "",
    "{}",
    [@core.text("Default")],
    trigger=@core.Load,
  )
  let html = render_to_string(node).html
  // Should NOT have luna:wc-trigger for load (it's the default)
  assert_true(!html.contains("luna:wc-trigger="))
}

///|
test "render wc_island state escaping" {
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-escape",
    "/static/wc-escape.js",
    "",
    "{\"text\":\"<script>alert(1)</script>\"}",
    [@core.text("Safe")],
  )
  let html = render_to_string(node).html
  // Ensure < and > are escaped in attribute value
  assert_true(!html.contains("data-state=\"{\"text\":\"<script>"))
}

///|
test "render wc_island with complex children" {
  let items = ["A", "B", "C"]
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-list",
    "/static/wc-list.js",
    ":host { display: block; } ul { padding: 0; }",
    "{\"items\":[\"A\",\"B\",\"C\"]}",
    [
      @core.h("h2", [], [@core.text("Items")]),
      @core.h("ul", [], [
        @core.for_each(fn() {
          items.map(fn(item) { @core.h("li", [], [@core.text(item)]) })
        }),
      ]),
    ],
  )
  let html = render_to_string(node).html
  assert_true(html.contains("<h2>Items</h2>"))
  assert_true(html.contains("<li>A</li>"))
  assert_true(html.contains("<li>B</li>"))
  assert_true(html.contains("<li>C</li>"))
  // CSS is minified: spaces around { } : ; are removed
  assert_true(html.contains(":host{display:block;}"))
}

///|
test "render wc_island with hydration markers" {
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-hyd",
    "/static/wc-hyd.js",
    "",
    "{\"count\":10}",
    [@core.text_dyn(fn() { "10" })],
  )
  let html = render_to_string_with_hydration(node)
  // Should have wc marker
  assert_true(html.contains("<!--wc:"))
  assert_true(html.contains("<!--/wc-->"))
  // Should have hydration markers for dynamic text inside
  assert_true(html.contains("<!--t:"))
  assert_true(html.contains("<!--/t-->"))
}

// =============================================================================
// SSR Inline CSS Injection Tests
// =============================================================================

///|
test "wc_island CSS with :host selector" {
  let css = ":host { display: block; margin: 1rem; }"
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-host",
    "/static/wc-host.js",
    css,
    "{}",
    [@core.text("Content")],
  )
  let html = render_to_string(node).html
  // CSS should be in <template><style id="style-{hash}">
  assert_true(html.contains("<template shadowrootmode=\"open\">"))
  assert_true(html.contains("<style id=\"style-"))
  // CSS is minified
  assert_true(html.contains(":host{display:block;margin:1rem;}"))
}

///|
test "wc_island CSS with @media query" {
  let css = "@media (max-width: 768px) { :host { padding: 0.5rem; } }"
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-responsive",
    "/static/wc-responsive.js",
    css,
    "{}",
    [@core.text("Responsive")],
  )
  let html = render_to_string(node).html
  assert_true(html.contains("<style id=\"style-"))
  // CSS is minified (space after @media preserved since ( is not punctuation)
  assert_true(html.contains("@media (max-width:768px){:host{padding:0.5rem;}}"))
}

///|
test "wc_island CSS with ::slotted selector" {
  let css = "::slotted(*) { color: inherit; } ::slotted(p) { margin: 0; }"
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-slot",
    "/static/wc-slot.js",
    css,
    "{}",
    [@core.h("slot", [], [])],
  )
  let html = render_to_string(node).html
  assert_true(html.contains("::slotted(*)"))
  assert_true(html.contains("::slotted(p)"))
}

///|
test "wc_island CSS with :host-context" {
  let css = ":host-context(.dark) { background: #333; color: white; }"
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-theme",
    "/static/wc-theme.js",
    css,
    "{}",
    [@core.text("Themed")],
  )
  let html = render_to_string(node).html
  assert_true(html.contains(":host-context(.dark)"))
}

///|
test "wc_island CSS with multiple rules" {
  let css = ":host { display: block; } .title { font-size: 1.5rem; } .content { padding: 1rem; }"
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-multi",
    "/static/wc-multi.js",
    css,
    "{}",
    [
      @core.h("h1", [("class", @core.attr_static("title"))], [
        @core.text("Title"),
      ]),
      @core.h("div", [("class", @core.attr_static("content"))], [
        @core.text("Body"),
      ]),
    ],
  )
  let html = render_to_string(node).html
  // CSS is minified: spaces around { } : ; are removed
  assert_true(html.contains(":host{display:block;}"))
  assert_true(html.contains(".title{font-size:1.5rem;}"))
  assert_true(html.contains(".content{padding:1rem;}"))
}

///|
test "multiple wc_islands with different styles" {
  let node : @core.Node[Unit, String] = @core.fragment([
    @core.wc_island(
      "wc-card-a",
      "/static/wc-card.js",
      ":host { background: blue; }",
      "{\"id\":\"a\"}",
      [@core.text("Card A")],
    ),
    @core.wc_island(
      "wc-card-b",
      "/static/wc-card.js",
      ":host { background: red; }",
      "{\"id\":\"b\"}",
      [@core.text("Card B")],
    ),
  ])
  let html = render_to_string(node).html
  // Each island should have its own style (minified)
  assert_true(html.contains(":host{background:blue;}"))
  assert_true(html.contains(":host{background:red;}"))
  // Check both templates are present
  let template_count = count_occurrences(
    html, "<template shadowrootmode=\"open\">",
  )
  assert_eq(template_count, 2)
}

///|
test "wc_island CSS preserved in nested structure" {
  let node : @core.Node[Unit, String] = @core.h("main", [], [
    @core.h("section", [], [
      @core.wc_island(
        "wc-nested",
        "/static/wc-nested.js",
        ".inner { display: flex; gap: 1rem; }",
        "{}",
        [
          @core.h("div", [("class", @core.attr_static("inner"))], [
            @core.text("Nested"),
          ]),
        ],
      ),
    ]),
  ])
  let html = render_to_string(node).html
  // CSS should be properly nested inside the component's template (minified)
  assert_true(html.contains("<main>"))
  assert_true(html.contains("<section>"))
  assert_true(html.contains("<style id=\"style-"))
  assert_true(html.contains(".inner{display:flex;gap:1rem;}"))
}

///|
test "wc_island CSS with CSS variables" {
  let css = ":host { --primary: #007bff; --spacing: 1rem; } .btn { background: var(--primary); padding: var(--spacing); }"
  let node : @core.Node[Unit, String] = @core.wc_island(
    "wc-vars",
    "/static/wc-vars.js",
    css,
    "{}",
    [
      @core.h("button", [("class", @core.attr_static("btn"))], [
        @core.text("Click"),
      ]),
    ],
  )
  let html = render_to_string(node).html
  // CSS is minified: spaces around : are removed
  assert_true(html.contains("--primary:#007bff"))
  assert_true(html.contains("var(--primary)"))
}

///|
/// Helper to count occurrences of a substring
fn count_occurrences(s : String, pattern : String) -> Int {
  let mut count = 0
  let mut start = 0
  while start < s.length() {
    let view = s.sub(start~)
    match view.find(pattern) {
      Some(idx) => {
        count = count + 1
        start = start + idx + 1
      }
      None => break
    }
  }
  count
}

// =============================================================================
// Streaming Async Tests
// =============================================================================

///|
