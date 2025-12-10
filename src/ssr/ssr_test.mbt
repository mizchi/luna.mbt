///|
/// SSR Tests - Pure MoonBit
test "render simple text" {
  let node = @kaguya.vtext("Hello, World!")
  let html = render_to_string(node)
  assert_eq(html, "Hello, World!")
}

///|
test "render escaped text" {
  let node = @kaguya.vtext("<script>alert('xss')</script>")
  let html = render_to_string(node)
  assert_eq(html, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
}

///|
test "render simple element" {
  let node = @element.div([], [])
  let html = render_to_string(node)
  assert_eq(html, "<div></div>")
}

///|
test "render element with text child" {
  let node = @element.div([], [@kaguya.vtext("Hello")])
  let html = render_to_string(node)
  assert_eq(html, "<div>Hello</div>")
}

///|
test "render element with class" {
  let node = @element.div([@element.class("container")], [])
  let html = render_to_string(node)
  assert_eq(html, "<div class=\"container\"></div>")
}

///|
test "render element with multiple attrs" {
  let node = @element.div([@element.id("main"), @element.class("container")], [])
  let html = render_to_string(node)
  assert_eq(html, "<div id=\"main\" class=\"container\"></div>")
}

///|
test "render nested elements" {
  let node = @element.div([], [@element.span([], [@kaguya.vtext("nested")])])
  let html = render_to_string(node)
  assert_eq(html, "<div><span>nested</span></div>")
}

///|
test "render void element" {
  let node = @element.input([
    @element.type_("text"),
    @element.placeholder("Enter name"),
  ])
  let html = render_to_string(node)
  assert_eq(html, "<input type=\"text\" placeholder=\"Enter name\" />")
}

///|
test "render br and hr" {
  let node = @kaguya.vfragment([@element.br(), @element.hr()])
  let html = render_to_string(node)
  assert_eq(html, "<br /><hr />")
}

///|
test "render fragment" {
  let node = @kaguya.vfragment([@kaguya.vtext("A"), @kaguya.vtext("B"), @kaguya.vtext("C")])
  let html = render_to_string(node)
  assert_eq(html, "ABC")
}

///|
test "render dynamic text" {
  let count = 42
  let node = @kaguya.text_dyn(fn() { "Count: " + count.to_string() })
  let html = render_to_string(node)
  assert_eq(html, "Count: 42")
}

///|
test "render dynamic attribute" {
  let active = true
  let node = @element.div(
    [@element.class_dyn(fn() { if active { "active" } else { "inactive" } })],
    [],
  )
  let html = render_to_string(node)
  assert_eq(html, "<div class=\"active\"></div>")
}

///|
test "render style attribute" {
  let node = @element.div(
    [@element.style([("color", "red"), ("fontSize", "16px")])],
    [],
  )
  let html = render_to_string(node)
  assert_eq(html, "<div style=\"color: red; font-size: 16px\"></div>")
}

///|
test "render disabled attribute true" {
  let node = @element.button([@element.disabled(true)], [@kaguya.vtext("Submit")])
  let html = render_to_string(node)
  assert_eq(html, "<button disabled>Submit</button>")
}

///|
test "render disabled attribute false" {
  let node = @element.button([@element.disabled(false)], [@kaguya.vtext("Submit")])
  let html = render_to_string(node)
  assert_eq(html, "<button>Submit</button>")
}

///|
test "render show when true" {
  let visible = true
  let node = @kaguya.vshow(fn() { visible }, fn() { @kaguya.vtext("Visible!") })
  let html = render_to_string(node)
  assert_eq(html, "Visible!")
}

///|
test "render show when false" {
  let visible = false
  let node = @kaguya.vshow(fn() { visible }, fn() { @kaguya.vtext("Visible!") })
  let html = render_to_string(node)
  assert_eq(html, "<!--show-->")
}

///|
test "render for list" {
  let items = ["A", "B", "C"]
  let node = @kaguya.vfor(fn() {
    let result : Array[@kaguya.Node] = []
    for i = 0; i < items.length(); i = i + 1 {
      result.push(@element.li([], [@kaguya.vtext(items[i])]))
    }
    result
  })
  let html = render_to_string(node)
  assert_eq(html, "<li>A</li><li>B</li><li>C</li>")
}

///|
test "render component" {
  fn greeting(name : String) -> @kaguya.Node {
    @element.div([], [@kaguya.vtext("Hello, " + name + "!")])
  }

  let node = @kaguya.vcomponent(fn() { greeting("World") })
  let html = render_to_string(node)
  assert_eq(html, "<div>Hello, World!</div>")
}

///|
test "handlers are not rendered" {
  let node = @element.button(
    [@element.on_click(@kaguya.event_handler()), @element.class("btn")],
    [@kaguya.vtext("Click me")],
  )
  let html = render_to_string(node)
  // Handler should not appear in output
  assert_eq(html, "<button class=\"btn\">Click me</button>")
}

///|
test "escape attribute value" {
  let node = @element.div([@element.attr("data-value", "a\"b&c")], [])
  let html = render_to_string(node)
  assert_eq(html, "<div data-value=\"a&quot;b&amp;c\"></div>")
}

///|
test "render with hydration markers for dynamic text" {
  let count = 5
  let node = @kaguya.text_dyn(fn() { count.to_string() })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--t:0-->5<!--/t-->")
}

///|
test "render with hydration markers for element with handler" {
  let node = @element.button([@element.on_click(@kaguya.event_handler())], [
    @kaguya.vtext("Click"),
  ])
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<button data-hk=\"0\">Click</button>")
}

///|
test "render with hydration markers for show" {
  let visible = true
  let node = @kaguya.vshow(fn() { visible }, fn() { @kaguya.vtext("Content") })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--s:0-->Content<!--/s-->")
}

///|
test "render with hydration markers for list" {
  let node = @kaguya.vfor(fn() { [@kaguya.vtext("A"), @kaguya.vtext("B")] })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--f:0-->AB<!--/f-->")
}

///|
test "complex page render" {
  let title = "My App"
  let count = 0
  let items = ["Item 1", "Item 2"]
  let page = @element.div([@element.class("app")], [
    @element.h1([], [@kaguya.vtext(title)]),
    @element.p([], [
      @kaguya.vtext("Count: "),
      @kaguya.text_dyn(fn() { count.to_string() }),
    ]),
    @element.ul([], [
      @kaguya.vfor(fn() {
        let result : Array[@kaguya.Node] = []
        for i = 0; i < items.length(); i = i + 1 {
          result.push(@element.li([], [@kaguya.vtext(items[i])]))
        }
        result
      }),
    ]),
    @element.button([@element.on_click(@kaguya.event_handler())], [
      @kaguya.vtext("Increment"),
    ]),
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
  let node = @kaguya.vtext("Tom & Jerry")
  let html = render_to_string(node)
  assert_eq(html, "Tom &amp; Jerry")
}

///|
test "render text with double quote" {
  let node = @kaguya.vtext("Say \"hello\"")
  let html = render_to_string(node)
  assert_eq(html, "Say &quot;hello&quot;")
}

///|
test "render void elements img" {
  let node = @element.img([@element.src("/image.png")])
  let html = render_to_string(node)
  assert_eq(html, "<img src=\"/image.png\" />")
}

///|
test "render void element col" {
  let node = @kaguya.vnode("col", [@element.attr("span", "2")], [])
  let html = render_to_string(node)
  assert_eq(html, "<col span=\"2\" />")
}

///|
test "render void element wbr" {
  let node = @kaguya.vnode("wbr", [], [])
  let html = render_to_string(node)
  assert_eq(html, "<wbr />")
}

///|
test "render void element area" {
  let node = @kaguya.vnode("area", [@element.attr("shape", "rect")], [])
  let html = render_to_string(node)
  assert_eq(html, "<area shape=\"rect\" />")
}

///|
test "render void element base" {
  let node = @kaguya.vnode("base", [@element.href("/")], [])
  let html = render_to_string(node)
  assert_eq(html, "<base href=\"/\" />")
}

///|
test "render void element link" {
  let node = @kaguya.vnode("link", [@element.attr("rel", "stylesheet")], [])
  let html = render_to_string(node)
  assert_eq(html, "<link rel=\"stylesheet\" />")
}

///|
test "render void element meta" {
  let node = @kaguya.vnode("meta", [@element.attr("charset", "utf-8")], [])
  let html = render_to_string(node)
  assert_eq(html, "<meta charset=\"utf-8\" />")
}

///|
test "render void element embed" {
  let node = @kaguya.vnode("embed", [@element.src("/video.swf")], [])
  let html = render_to_string(node)
  assert_eq(html, "<embed src=\"/video.swf\" />")
}

///|
test "render void element track" {
  let node = @kaguya.vnode("track", [@element.attr("kind", "subtitles")], [])
  let html = render_to_string(node)
  assert_eq(html, "<track kind=\"subtitles\" />")
}

///|
test "render void element source" {
  let node = @kaguya.vnode("source", [@element.src("/audio.mp3")], [])
  let html = render_to_string(node)
  assert_eq(html, "<source src=\"/audio.mp3\" />")
}

///|
test "render non-void element with length 7" {
  // "section" has length 7, should not be void element
  let node = @kaguya.vnode("section", [], [@kaguya.vtext("content")])
  let html = render_to_string(node)
  assert_eq(html, "<section>content</section>")
}

///|
test "render dynamic style" {
  let node = @element.div(
    [@element.style_dyn(fn() { [("color", "blue"), ("margin", "10px")] })],
    [],
  )
  let html = render_to_string(node)
  assert_eq(html, "<div style=\"color: blue; margin: 10px\"></div>")
}

///|
test "render empty dynamic style" {
  let node = @element.div([@element.style_dyn(fn() { [] })], [])
  let html = render_to_string(node)
  assert_eq(html, "<div></div>")
}
