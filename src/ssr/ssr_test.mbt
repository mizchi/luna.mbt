///|
/// SSR Tests - Pure MoonBit
test "render simple text" {
  let node = @ui.vtext("Hello, World!")
  let html = render_to_string(node)
  assert_eq(html, "Hello, World!")
}

///|
test "render escaped text" {
  let node = @ui.vtext("<script>alert('xss')</script>")
  let html = render_to_string(node)
  assert_eq(html, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
}

///|
test "render simple element" {
  let node = @element.vdiv([], [])
  let html = render_to_string(node)
  assert_eq(html, "<div></div>")
}

///|
test "render element with text child" {
  let node = @element.vdiv([], [@ui.vtext("Hello")])
  let html = render_to_string(node)
  assert_eq(html, "<div>Hello</div>")
}

///|
test "render element with class" {
  let node = @element.vdiv([@element.vclass("container")], [])
  let html = render_to_string(node)
  assert_eq(html, "<div class=\"container\"></div>")
}

///|
test "render element with multiple attrs" {
  let node = @element.vdiv([@element.vid("main"), @element.vclass("container")], [])
  let html = render_to_string(node)
  assert_eq(html, "<div id=\"main\" class=\"container\"></div>")
}

///|
test "render nested elements" {
  let node = @element.vdiv([], [@element.vspan([], [@ui.vtext("nested")])])
  let html = render_to_string(node)
  assert_eq(html, "<div><span>nested</span></div>")
}

///|
test "render void element" {
  let node = @element.vinput([@element.vtype("text"), @element.vplaceholder("Enter name")])
  let html = render_to_string(node)
  assert_eq(html, "<input type=\"text\" placeholder=\"Enter name\" />")
}

///|
test "render br and hr" {
  let node = @ui.vfragment([@element.vbr(), @element.vhr()])
  let html = render_to_string(node)
  assert_eq(html, "<br /><hr />")
}

///|
test "render fragment" {
  let node = @ui.vfragment([@ui.vtext("A"), @ui.vtext("B"), @ui.vtext("C")])
  let html = render_to_string(node)
  assert_eq(html, "ABC")
}

///|
test "render dynamic text" {
  let count = 42
  let node = @ui.vtext_dyn(fn() { "Count: " + count.to_string() })
  let html = render_to_string(node)
  assert_eq(html, "Count: 42")
}

///|
test "render dynamic attribute" {
  let active = true
  let node = @element.vdiv(
    [@element.vclass_dyn(fn() { if active { "active" } else { "inactive" } })],
    [],
  )
  let html = render_to_string(node)
  assert_eq(html, "<div class=\"active\"></div>")
}

///|
test "render style attribute" {
  let node = @element.vdiv([@element.vstyle([("color", "red"), ("fontSize", "16px")])], [])
  let html = render_to_string(node)
  assert_eq(html, "<div style=\"color: red; font-size: 16px\"></div>")
}

///|
test "render disabled attribute true" {
  let node = @element.vbutton([@element.vdisabled(true)], [@ui.vtext("Submit")])
  let html = render_to_string(node)
  assert_eq(html, "<button disabled>Submit</button>")
}

///|
test "render disabled attribute false" {
  let node = @element.vbutton([@element.vdisabled(false)], [@ui.vtext("Submit")])
  let html = render_to_string(node)
  assert_eq(html, "<button>Submit</button>")
}

///|
test "render show when true" {
  let visible = true
  let node = @ui.vshow(fn() { visible }, fn() { @ui.vtext("Visible!") })
  let html = render_to_string(node)
  assert_eq(html, "Visible!")
}

///|
test "render show when false" {
  let visible = false
  let node = @ui.vshow(fn() { visible }, fn() { @ui.vtext("Visible!") })
  let html = render_to_string(node)
  assert_eq(html, "<!--show-->")
}

///|
test "render for list" {
  let items = ["A", "B", "C"]
  let node = @ui.vfor(fn() {
    let result : Array[@ui.Node] = []
    for i = 0; i < items.length(); i = i + 1 {
      result.push(@element.vli([], [@ui.vtext(items[i])]))
    }
    result
  })
  let html = render_to_string(node)
  assert_eq(html, "<li>A</li><li>B</li><li>C</li>")
}

///|
test "render component" {
  fn greeting(name : String) -> @ui.Node {
    @element.vdiv([], [@ui.vtext("Hello, " + name + "!")])
  }

  let node = @ui.vcomponent(fn() { greeting("World") })
  let html = render_to_string(node)
  assert_eq(html, "<div>Hello, World!</div>")
}

///|
test "handlers are not rendered" {
  let node = @element.vbutton(
    [@element.von_click(@ui.event_handler()), @element.vclass("btn")],
    [@ui.vtext("Click me")],
  )
  let html = render_to_string(node)
  // Handler should not appear in output
  assert_eq(html, "<button class=\"btn\">Click me</button>")
}

///|
test "escape attribute value" {
  let node = @element.vdiv([@element.vattr("data-value", "a\"b&c")], [])
  let html = render_to_string(node)
  assert_eq(html, "<div data-value=\"a&quot;b&amp;c\"></div>")
}

///|
test "render with hydration markers for dynamic text" {
  let count = 5
  let node = @ui.vtext_dyn(fn() { count.to_string() })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--t:0-->5<!--/t-->")
}

///|
test "render with hydration markers for element with handler" {
  let node = @element.vbutton([@element.von_click(@ui.event_handler())], [
    @ui.vtext("Click"),
  ])
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<button data-hk=\"0\">Click</button>")
}

///|
test "render with hydration markers for show" {
  let visible = true
  let node = @ui.vshow(fn() { visible }, fn() { @ui.vtext("Content") })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--s:0-->Content<!--/s-->")
}

///|
test "render with hydration markers for list" {
  let node = @ui.vfor(fn() { [@ui.vtext("A"), @ui.vtext("B")] })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--f:0-->AB<!--/f-->")
}

///|
test "complex page render" {
  let title = "My App"
  let count = 0
  let items = ["Item 1", "Item 2"]
  let page = @element.vdiv([@element.vclass("app")], [
    @element.vh1([], [@ui.vtext(title)]),
    @element.vp([], [@ui.vtext("Count: "), @ui.vtext_dyn(fn() { count.to_string() })]),
    @element.vul([], [
      @ui.vfor(fn() {
        let result : Array[@ui.Node] = []
        for i = 0; i < items.length(); i = i + 1 {
          result.push(@element.vli([], [@ui.vtext(items[i])]))
        }
        result
      }),
    ]),
    @element.vbutton([@element.von_click(@ui.event_handler())], [@ui.vtext("Increment")]),
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
  let node = @ui.vtext("Tom & Jerry")
  let html = render_to_string(node)
  assert_eq(html, "Tom &amp; Jerry")
}

///|
test "render text with double quote" {
  let node = @ui.vtext("Say \"hello\"")
  let html = render_to_string(node)
  assert_eq(html, "Say &quot;hello&quot;")
}

///|
test "render void elements img" {
  let node = @element.vimg([@element.vsrc("/image.png")])
  let html = render_to_string(node)
  assert_eq(html, "<img src=\"/image.png\" />")
}

///|
test "render void element col" {
  let node = @ui.vnode("col", [@element.vattr("span", "2")], [])
  let html = render_to_string(node)
  assert_eq(html, "<col span=\"2\" />")
}

///|
test "render void element wbr" {
  let node = @ui.vnode("wbr", [], [])
  let html = render_to_string(node)
  assert_eq(html, "<wbr />")
}

///|
test "render void element area" {
  let node = @ui.vnode("area", [@element.vattr("shape", "rect")], [])
  let html = render_to_string(node)
  assert_eq(html, "<area shape=\"rect\" />")
}

///|
test "render void element base" {
  let node = @ui.vnode("base", [@element.vhref("/")], [])
  let html = render_to_string(node)
  assert_eq(html, "<base href=\"/\" />")
}

///|
test "render void element link" {
  let node = @ui.vnode("link", [@element.vattr("rel", "stylesheet")], [])
  let html = render_to_string(node)
  assert_eq(html, "<link rel=\"stylesheet\" />")
}

///|
test "render void element meta" {
  let node = @ui.vnode("meta", [@element.vattr("charset", "utf-8")], [])
  let html = render_to_string(node)
  assert_eq(html, "<meta charset=\"utf-8\" />")
}

///|
test "render void element embed" {
  let node = @ui.vnode("embed", [@element.vsrc("/video.swf")], [])
  let html = render_to_string(node)
  assert_eq(html, "<embed src=\"/video.swf\" />")
}

///|
test "render void element track" {
  let node = @ui.vnode("track", [@element.vattr("kind", "subtitles")], [])
  let html = render_to_string(node)
  assert_eq(html, "<track kind=\"subtitles\" />")
}

///|
test "render void element source" {
  let node = @ui.vnode("source", [@element.vsrc("/audio.mp3")], [])
  let html = render_to_string(node)
  assert_eq(html, "<source src=\"/audio.mp3\" />")
}

///|
test "render non-void element with length 7" {
  // "section" has length 7, should not be void element
  let node = @ui.vnode("section", [], [@ui.vtext("content")])
  let html = render_to_string(node)
  assert_eq(html, "<section>content</section>")
}

///|
test "render dynamic style" {
  let node = @element.vdiv(
    [@element.vstyle_dyn(fn() { [("color", "blue"), ("margin", "10px")] })],
    [],
  )
  let html = render_to_string(node)
  assert_eq(html, "<div style=\"color: blue; margin: 10px\"></div>")
}

///|
test "render empty dynamic style" {
  let node = @element.vdiv([@element.vstyle_dyn(fn() { [] })], [])
  let html = render_to_string(node)
  assert_eq(html, "<div></div>")
}
