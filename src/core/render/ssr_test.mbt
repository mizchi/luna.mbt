///|
/// SSR Tests - Pure MoonBit
///
/// Type alias for SSR nodes (Event type = Unit)

///|
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
  let node : @luna.Node[Unit] = @luna.visland(
    "lazy-1",
    "/components/lazy.js",
    "{}",
    [@luna.vtext("Loading...")],
    trigger=@luna.Idle,
  )
  let html = render_to_string(node).html
  assert_true(html.contains("luna:client-trigger=\"idle\""))
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
  assert_true(html.contains("luna:client-trigger=\"visible\""))
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
  assert_true(html.contains("luna:client-trigger=\"media:(min-width: 768px)\""))
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
  let node : @luna.Node[Unit] = @luna.visland(
    "escape-1",
    "/components/test.js",
    "{\"text\":\"<script>alert(1)</script>\"}",
    [@luna.vtext("Safe")],
  )
  let html = render_to_string(node).html
  // Ensure < and > are NOT in the attribute value (they should be entity-escaped)
  // The attribute value should have &lt; and &gt; or be safe
  assert_true(not(html.contains("luna:state=\"{\"text\":\"<script>")))
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
  assert_true(html.contains("<!--luna:island:hyd-1"))
  assert_true(html.contains("<!--/luna:island:hyd-1-->"))
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

///|
test "preload with nested islands in div hierarchy" {
  // div > div > island structure
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [("class", @luna.attr_static("outer"))],
    [
      @luna.h("div", [("class", @luna.attr_static("middle"))], [
        @luna.h("div", [("class", @luna.attr_static("inner"))], [
          @luna.visland("nested-island", "/components/nested.js", "{}", [
            @luna.vtext("Nested"),
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
  let node : @luna.Node[Unit] = @luna.vfragment([
    // Root level island
    @luna.visland("root-island", "/components/root.js", "{}", [
      @luna.vtext("Root"),
    ]),
    // First level nesting
    @luna.h("section", [], [
      @luna.visland("section-island", "/components/section.js", "{}", [
        @luna.vtext("Section"),
      ]),
      // Deeply nested island
      @luna.h("article", [], [
        @luna.h("div", [], [
          @luna.visland("deep-island", "/components/deep.js", "{}", [
            @luna.vtext("Deep"),
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
  let node : @luna.Node[Unit] = @luna.vshow(fn() { visible }, fn() {
    @luna.visland("conditional-island", "/components/conditional.js", "{}", [
      @luna.vtext("Shown"),
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
  let node : @luna.Node[Unit] = @luna.vshow(fn() { visible }, fn() {
    @luna.visland("conditional-island", "/components/conditional.js", "{}", [
      @luna.vtext("Hidden"),
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
  let node : @luna.Node[Unit] = @luna.vfragment([
    @luna.vshow(fn() { show_a }, fn() {
      @luna.visland("island-a", "/components/a.js", "{}", [@luna.vtext("A")])
    }),
    @luna.vshow(fn() { show_b }, fn() {
      @luna.visland("island-b", "/components/b.js", "{}", [@luna.vtext("B")])
    }),
    @luna.vshow(fn() { show_c }, fn() {
      @luna.visland("island-c", "/components/c.js", "{}", [@luna.vtext("C")])
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
  let node : @luna.Node[Unit] = @luna.vshow(fn() { outer_visible }, fn() {
    @luna.h("div", [], [
      @luna.visland("outer-island", "/components/outer.js", "{}", [
        @luna.vtext("Outer"),
      ]),
      @luna.vshow(fn() { inner_visible }, fn() {
        @luna.visland("inner-island", "/components/inner.js", "{}", [
          @luna.vtext("Inner"),
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
  let node : @luna.Node[Unit] = @luna.vshow(fn() { outer_visible }, fn() {
    @luna.h("div", [], [
      @luna.visland("outer-island", "/components/outer.js", "{}", [
        @luna.vtext("Outer"),
      ]),
      @luna.vshow(fn() { inner_visible }, fn() {
        @luna.visland("inner-island", "/components/inner.js", "{}", [
          @luna.vtext("Inner"),
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
  let node : @luna.Node[Unit] = @luna.vshow(fn() { outer_visible }, fn() {
    @luna.h("div", [], [
      @luna.visland("outer-island", "/components/outer.js", "{}", [
        @luna.vtext("Outer"),
      ]),
      @luna.vshow(fn() { inner_visible }, fn() {
        @luna.visland("inner-island", "/components/inner.js", "{}", [
          @luna.vtext("Inner"),
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
  let node : @luna.Node[Unit] = @luna.vfragment([
    @luna.h("header", [], [@luna.vtext("Header")]),
    @luna.visland("nav-island", "/components/nav.js", "{}", [@luna.vtext("Nav")]),
    @luna.h("main", [], [
      @luna.h("h1", [], [@luna.vtext("Title")]),
      @luna.visland("content-island", "/components/content.js", "{}", [
        @luna.vtext("Content"),
      ]),
      @luna.h("aside", [], [
        @luna.visland("sidebar-island", "/components/sidebar.js", "{}", [
          @luna.vtext("Sidebar"),
        ]),
      ]),
    ]),
    @luna.h("footer", [], [@luna.vtext("Footer")]),
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
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.visland("counter-1", "/components/counter.js", "{\"count\":1}", [
      @luna.vtext("1"),
    ]),
    @luna.h("section", [], [
      @luna.visland("counter-2", "/components/counter.js", "{\"count\":2}", [
        @luna.vtext("2"),
      ]),
      @luna.h("div", [], [
        @luna.visland("counter-3", "/components/counter.js", "{\"count\":3}", [
          @luna.vtext("3"),
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
  let node : @luna.Node[Unit] = @luna.vfragment([
    @luna.visland("island-1", "/components/a.js", "{}", [@luna.vtext("A")]),
    @luna.visland("island-2", "/components/b.js", "{}", [@luna.vtext("B")]),
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
  let node : @luna.Node[Unit] = @luna.vwc_island(
    "wc-counter",
    "/static/wc_counter.js",
    "",
    "{\"count\":0}",
    [@luna.vtext("0")],
  )
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 1)
  assert_true(result.preload_urls.contains("/static/wc_counter.js"))
  assert_true(result.html.contains("luna:wc-url=\"/static/wc_counter.js\""))
}

///|
test "preload with mixed island and wc_island" {
  let node : @luna.Node[Unit] = @luna.vfragment([
    @luna.visland("counter", "/static/counter.js", "{}", [@luna.vtext("Count")]),
    @luna.vwc_island("wc-timer", "/static/wc_timer.js", "", "{}", [
      @luna.vtext("Timer"),
    ]),
  ])
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 2)
  assert_true(result.preload_urls.contains("/static/counter.js"))
  assert_true(result.preload_urls.contains("/static/wc_timer.js"))
}

///|
test "preload with nested wc_island in div" {
  let node : @luna.Node[Unit] = @luna.h("main", [], [
    @luna.h("section", [], [
      @luna.vwc_island("wc-nested", "/static/wc_nested.js", "", "{}", [
        @luna.vtext("Nested"),
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
  let node : @luna.Node[Unit] = @luna.vshow(fn() { visible }, fn() {
    @luna.vwc_island("wc-conditional", "/static/wc_conditional.js", "", "{}", [
      @luna.vtext("Conditional"),
    ])
  })
  let result = render_to_string(node, preload=true)
  assert_eq(result.preload_urls.length(), 1)
  assert_true(result.preload_urls.contains("/static/wc_conditional.js"))
}

///|
test "preload with duplicate wc_island urls" {
  let node : @luna.Node[Unit] = @luna.vfragment([
    @luna.vwc_island(
      "wc-counter-1",
      "/static/wc_counter.js",
      "",
      "{\"id\":1}",
      [@luna.vtext("1")],
    ),
    @luna.vwc_island(
      "wc-counter-2",
      "/static/wc_counter.js",
      "",
      "{\"id\":2}",
      [@luna.vtext("2")],
    ),
    @luna.vwc_island(
      "wc-counter-3",
      "/static/wc_counter.js",
      "",
      "{\"id\":3}",
      [@luna.vtext("3")],
    ),
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
// Web Components Island Tests
// =============================================================================

///|
test "render wc_island basic" {
  let node : @luna.Node[Unit] = @luna.vwc_island(
    "wc-counter",
    "/static/wc-counter.js",
    ":host { display: block; }",
    "{\"count\":5}",
    [@luna.vtext("5")],
  )
  let html = render_to_string(node).html
  // Check custom element with data attributes
  assert_true(html.contains("<wc-counter"))
  assert_true(html.contains("luna:wc-url=\"/static/wc-counter.js\""))
  assert_true(html.contains("luna:wc-state=\"{&quot;count&quot;:5}\""))
  // Check Declarative Shadow DOM template
  assert_true(html.contains("<template shadowrootmode=\"open\">"))
  assert_true(html.contains("<style>:host { display: block; }</style>"))
  // Check children are rendered
  assert_true(html.contains("5"))
  assert_true(html.contains("</template></wc-counter>"))
}

///|
test "render wc_island without styles" {
  let node : @luna.Node[Unit] = @luna.vwc_island(
    "wc-simple",
    "/static/wc-simple.js",
    "", // empty styles
    "{}",
    [@luna.vtext("Content")],
  )
  let html = render_to_string(node).html
  // Should not have style tag when styles is empty
  assert_true(not(html.contains("<style>")))
  assert_true(
    html.contains("<template shadowrootmode=\"open\">Content</template>"),
  )
}

///|
test "render wc_island with idle trigger" {
  let node : @luna.Node[Unit] = @luna.vwc_island(
    "wc-lazy",
    "/static/wc-lazy.js",
    "",
    "{}",
    [@luna.vtext("Loading...")],
    trigger=@luna.Idle,
  )
  let html = render_to_string(node).html
  assert_true(html.contains("luna:wc-trigger=\"idle\""))
}

///|
test "render wc_island with visible trigger" {
  let node : @luna.Node[Unit] = @luna.vwc_island(
    "wc-visible",
    "/static/wc-visible.js",
    "",
    "{}",
    [@luna.vtext("Loading...")],
    trigger=@luna.Visible,
  )
  let html = render_to_string(node).html
  assert_true(html.contains("luna:wc-trigger=\"visible\""))
}

///|
test "render wc_island with media trigger" {
  let node : @luna.Node[Unit] = @luna.vwc_island(
    "wc-responsive",
    "/static/wc-responsive.js",
    "",
    "{}",
    [@luna.vtext("Content")],
    trigger=@luna.Media("(min-width: 768px)"),
  )
  let html = render_to_string(node).html
  assert_true(html.contains("luna:wc-trigger=\"media:(min-width: 768px)\""))
}

///|
test "render wc_island load trigger omits luna:wc-trigger" {
  // Load trigger is the default, should not render luna:wc-trigger attribute
  let node : @luna.Node[Unit] = @luna.vwc_island(
    "wc-default",
    "/static/wc-default.js",
    "",
    "{}",
    [@luna.vtext("Default")],
    trigger=@luna.Load,
  )
  let html = render_to_string(node).html
  // Should NOT have luna:wc-trigger for load (it's the default)
  assert_true(not(html.contains("luna:wc-trigger=")))
}

///|
test "render wc_island state escaping" {
  let node : @luna.Node[Unit] = @luna.vwc_island(
    "wc-escape",
    "/static/wc-escape.js",
    "",
    "{\"text\":\"<script>alert(1)</script>\"}",
    [@luna.vtext("Safe")],
  )
  let html = render_to_string(node).html
  // Ensure < and > are escaped in attribute value
  assert_true(not(html.contains("data-state=\"{\"text\":\"<script>")))
}

///|
test "render wc_island with complex children" {
  let items = ["A", "B", "C"]
  let node : @luna.Node[Unit] = @luna.vwc_island(
    "wc-list",
    "/static/wc-list.js",
    ":host { display: block; } ul { padding: 0; }",
    "{\"items\":[\"A\",\"B\",\"C\"]}",
    [
      @luna.h("h2", [], [@luna.vtext("Items")]),
      @luna.h("ul", [], [
        @luna.vfor(fn() {
          let result : Array[@luna.Node[Unit]] = []
          for i = 0; i < items.length(); i = i + 1 {
            result.push(@luna.h("li", [], [@luna.vtext(items[i])]))
          }
          result
        }),
      ]),
    ],
  )
  let html = render_to_string(node).html
  assert_true(html.contains("<h2>Items</h2>"))
  assert_true(html.contains("<li>A</li>"))
  assert_true(html.contains("<li>B</li>"))
  assert_true(html.contains("<li>C</li>"))
  assert_true(html.contains(":host { display: block; }"))
}

///|
test "render wc_island with hydration markers" {
  let node : @luna.Node[Unit] = @luna.vwc_island(
    "wc-hyd",
    "/static/wc-hyd.js",
    "",
    "{\"count\":10}",
    [@luna.text_dyn(fn() { "10" })],
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
// Streaming Async Tests
// =============================================================================

///|
