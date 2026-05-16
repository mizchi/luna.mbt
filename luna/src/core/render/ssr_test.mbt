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
