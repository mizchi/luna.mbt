///|
/// SSR Tests - Pure MoonBit
///
/// Type alias for SSR nodes (Event type = Unit)


test "render simple text" {
  let node : @luna.Node[Unit] = @luna.vtext("Hello, World!")
  let html = render_to_string(node)
  assert_eq(html, "Hello, World!")
}

///|
test "render escaped text" {
  let node : @luna.Node[Unit] = @luna.vtext("<script>alert('xss')</script>")
  let html = render_to_string(node)
  assert_eq(html, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
}

///|
test "render simple element" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [])
  let html = render_to_string(node)
  assert_eq(html, "<div></div>")
}

///|
test "render element with text child" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [@luna.vtext("Hello")])
  let html = render_to_string(node)
  assert_eq(html, "<div>Hello</div>")
}

///|
test "render element with class" {
  let node : @luna.Node[Unit] = @luna.h("div", [("class", @luna.attr_static("container"))], [])
  let html = render_to_string(node)
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
  let html = render_to_string(node)
  assert_eq(html, "<div id=\"main\" class=\"container\"></div>")
}

///|
test "render nested elements" {
  let node : @luna.Node[Unit] = @luna.h("div", [], [
    @luna.h("span", [], [@luna.vtext("nested")]),
  ])
  let html = render_to_string(node)
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
  let html = render_to_string(node)
  assert_eq(html, "<input type=\"text\" placeholder=\"Enter name\" />")
}

///|
test "render br and hr" {
  let node : @luna.Node[Unit] = @luna.vfragment([
    @luna.h("br", [], []),
    @luna.h("hr", [], []),
  ])
  let html = render_to_string(node)
  assert_eq(html, "<br /><hr />")
}

///|
test "render fragment" {
  let node : @luna.Node[Unit] = @luna.vfragment([
    @luna.vtext("A"),
    @luna.vtext("B"),
    @luna.vtext("C"),
  ])
  let html = render_to_string(node)
  assert_eq(html, "ABC")
}

///|
test "render dynamic text" {
  let count = 42
  let node : @luna.Node[Unit] = @luna.text_dyn(fn() { "Count: " + count.to_string() })
  let html = render_to_string(node)
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
  let html = render_to_string(node)
  assert_eq(html, "<div class=\"active\"></div>")
}

///|
test "render style attribute" {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [("style", @luna.attr_style("color: red; font-size: 16px"))],
    [],
  )
  let html = render_to_string(node)
  assert_eq(html, "<div style=\"color: red; font-size: 16px\"></div>")
}

///|
test "render disabled attribute true" {
  let node : @luna.Node[Unit] = @luna.h("button", [("disabled", @luna.attr_static(""))], [
    @luna.vtext("Submit"),
  ])
  let html = render_to_string(node)
  assert_eq(html, "<button disabled>Submit</button>")
}

///|
test "render disabled attribute false" {
  let node : @luna.Node[Unit] = @luna.h("button", [], [@luna.vtext("Submit")])
  let html = render_to_string(node)
  assert_eq(html, "<button>Submit</button>")
}

///|
test "render show when true" {
  let visible = true
  let node : @luna.Node[Unit] = @luna.vshow(fn() { visible }, fn() { @luna.vtext("Visible!") })
  let html = render_to_string(node)
  assert_eq(html, "Visible!")
}

///|
test "render show when false" {
  let visible = false
  let node : @luna.Node[Unit] = @luna.vshow(fn() { visible }, fn() { @luna.vtext("Visible!") })
  let html = render_to_string(node)
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
  let html = render_to_string(node)
  assert_eq(html, "<li>A</li><li>B</li><li>C</li>")
}

///|
test "render component" {
  fn greeting(name : String) -> @luna.Node[Unit] {
    @luna.h("div", [], [@luna.vtext("Hello, " + name + "!")])
  }

  let node : @luna.Node[Unit] = @luna.vcomponent(fn() { greeting("World") })
  let html = render_to_string(node)
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
  let html = render_to_string(node)
  // Handler should not appear in output
  assert_eq(html, "<button class=\"btn\">Click me</button>")
}

///|
test "escape attribute value" {
  let node : @luna.Node[Unit] = @luna.h("div", [("data-value", @luna.attr_static("a\"b&c"))], [])
  let html = render_to_string(node)
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
  let node : @luna.Node[Unit] = @luna.vshow(fn() { visible }, fn() { @luna.vtext("Content") })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--s:0-->Content<!--/s-->")
}

///|
test "render with hydration markers for list" {
  let node : @luna.Node[Unit] = @luna.vfor(fn() { [@luna.vtext("A"), @luna.vtext("B")] })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--f:0-->AB<!--/f-->")
}

///|
test "complex page render" {
  let title = "My App"
  let count = 0
  let items = ["Item 1", "Item 2"]
  let page : @luna.Node[Unit] = @luna.h("div", [("class", @luna.attr_static("app"))], [
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
  ])
  let html = render_to_string(page)
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
  let html = render_to_string(node)
  assert_eq(html, "Tom &amp; Jerry")
}

///|
test "render text with double quote" {
  let node : @luna.Node[Unit] = @luna.vtext("Say \"hello\"")
  let html = render_to_string(node)
  assert_eq(html, "Say &quot;hello&quot;")
}

///|
test "render void elements img" {
  let node : @luna.Node[Unit] = @luna.h("img", [("src", @luna.attr_static("/image.png"))], [])
  let html = render_to_string(node)
  assert_eq(html, "<img src=\"/image.png\" />")
}

///|
test "render void element col" {
  let node : @luna.Node[Unit] = @luna.h("col", [("span", @luna.attr_static("2"))], [])
  let html = render_to_string(node)
  assert_eq(html, "<col span=\"2\" />")
}

///|
test "render void element wbr" {
  let node : @luna.Node[Unit] = @luna.h("wbr", [], [])
  let html = render_to_string(node)
  assert_eq(html, "<wbr />")
}

///|
test "render void element area" {
  let node : @luna.Node[Unit] = @luna.h("area", [("shape", @luna.attr_static("rect"))], [])
  let html = render_to_string(node)
  assert_eq(html, "<area shape=\"rect\" />")
}

///|
test "render void element base" {
  let node : @luna.Node[Unit] = @luna.h("base", [("href", @luna.attr_static("/"))], [])
  let html = render_to_string(node)
  assert_eq(html, "<base href=\"/\" />")
}

///|
test "render void element link" {
  let node : @luna.Node[Unit] = @luna.h("link", [("rel", @luna.attr_static("stylesheet"))], [])
  let html = render_to_string(node)
  assert_eq(html, "<link rel=\"stylesheet\" />")
}

///|
test "render void element meta" {
  let node : @luna.Node[Unit] = @luna.h("meta", [("charset", @luna.attr_static("utf-8"))], [])
  let html = render_to_string(node)
  assert_eq(html, "<meta charset=\"utf-8\" />")
}

///|
test "render void element embed" {
  let node : @luna.Node[Unit] = @luna.h("embed", [("src", @luna.attr_static("/video.swf"))], [])
  let html = render_to_string(node)
  assert_eq(html, "<embed src=\"/video.swf\" />")
}

///|
test "render void element track" {
  let node : @luna.Node[Unit] = @luna.h("track", [("kind", @luna.attr_static("subtitles"))], [])
  let html = render_to_string(node)
  assert_eq(html, "<track kind=\"subtitles\" />")
}

///|
test "render void element source" {
  let node : @luna.Node[Unit] = @luna.h("source", [("src", @luna.attr_static("/audio.mp3"))], [])
  let html = render_to_string(node)
  assert_eq(html, "<source src=\"/audio.mp3\" />")
}

///|
test "render non-void element with length 7" {
  // "section" has length 7, should not be void element
  let node : @luna.Node[Unit] = @luna.h("section", [], [@luna.vtext("content")])
  let html = render_to_string(node)
  assert_eq(html, "<section>content</section>")
}

///|
test "render dynamic style" {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [
      (
        "style",
        @luna.attr_dynamic_style(fn() { "color: blue; margin: 10px" }),
      ),
    ],
    [],
  )
  let html = render_to_string(node)
  assert_eq(html, "<div style=\"color: blue; margin: 10px\"></div>")
}

///|
test "render empty dynamic style" {
  let node : @luna.Node[Unit] = @luna.h(
    "div",
    [("style", @luna.attr_dynamic_style(fn() { "" }))],
    [],
  )
  let html = render_to_string(node)
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
  let html = render_to_string(node)
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
  let html = render_to_string(node)
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
  let html = render_to_string(node)
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
  let html = render_to_string(node)
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
  let outer_island : @luna.Node[Unit] = @luna.visland("outer-1", "/components/outer.js", "{}", [
    @luna.h("div", [], [inner_island]),
  ])
  let html = render_to_string(outer_island)
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
  let html = render_to_string(node)
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
  let html = render_to_string(node)
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
