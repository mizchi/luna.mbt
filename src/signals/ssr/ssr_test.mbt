///|
/// SSR Tests - Pure MoonBit
test "render simple text" {
  let node = @signals.vtext("Hello, World!")
  let html = render_to_string(node)
  assert_eq(html, "Hello, World!")
}

///|
test "render escaped text" {
  let node = @signals.vtext("<script>alert('xss')</script>")
  let html = render_to_string(node)
  assert_eq(html, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
}

///|
test "render simple element" {
  let node = @signals.vdiv([], [])
  let html = render_to_string(node)
  assert_eq(html, "<div></div>")
}

///|
test "render element with text child" {
  let node = @signals.vdiv([], [@signals.vtext("Hello")])
  let html = render_to_string(node)
  assert_eq(html, "<div>Hello</div>")
}

///|
test "render element with class" {
  let node = @signals.vdiv([@signals.vclass("container")], [])
  let html = render_to_string(node)
  assert_eq(html, "<div class=\"container\"></div>")
}

///|
test "render element with multiple attrs" {
  let node = @signals.vdiv(
    [@signals.vid("main"), @signals.vclass("container")],
    [],
  )
  let html = render_to_string(node)
  assert_eq(html, "<div id=\"main\" class=\"container\"></div>")
}

///|
test "render nested elements" {
  let node = @signals.vdiv([], [@signals.vspan([], [@signals.vtext("nested")])])
  let html = render_to_string(node)
  assert_eq(html, "<div><span>nested</span></div>")
}

///|
test "render void element" {
  let node = @signals.vinput([
    @signals.vtype("text"),
    @signals.vplaceholder("Enter name"),
  ])
  let html = render_to_string(node)
  assert_eq(html, "<input type=\"text\" placeholder=\"Enter name\" />")
}

///|
test "render br and hr" {
  let node = @signals.vfragment([@signals.vbr(), @signals.vhr()])
  let html = render_to_string(node)
  assert_eq(html, "<br /><hr />")
}

///|
test "render fragment" {
  let node = @signals.vfragment([
    @signals.vtext("A"),
    @signals.vtext("B"),
    @signals.vtext("C"),
  ])
  let html = render_to_string(node)
  assert_eq(html, "ABC")
}

///|
test "render dynamic text" {
  let count = 42
  let node = @signals.vtext_dyn(fn() { "Count: " + count.to_string() })
  let html = render_to_string(node)
  assert_eq(html, "Count: 42")
}

///|
test "render dynamic attribute" {
  let active = true
  let node = @signals.vdiv(
    [@signals.vclass_dyn(fn() { if active { "active" } else { "inactive" } })],
    [],
  )
  let html = render_to_string(node)
  assert_eq(html, "<div class=\"active\"></div>")
}

///|
test "render style attribute" {
  let node = @signals.vdiv(
    [@signals.vstyle([("color", "red"), ("fontSize", "16px")])],
    [],
  )
  let html = render_to_string(node)
  assert_eq(html, "<div style=\"color: red; font-size: 16px\"></div>")
}

///|
test "render disabled attribute true" {
  let node = @signals.vbutton([@signals.vdisabled(true)], [
    @signals.vtext("Submit"),
  ])
  let html = render_to_string(node)
  assert_eq(html, "<button disabled>Submit</button>")
}

///|
test "render disabled attribute false" {
  let node = @signals.vbutton([@signals.vdisabled(false)], [
    @signals.vtext("Submit"),
  ])
  let html = render_to_string(node)
  assert_eq(html, "<button>Submit</button>")
}

///|
test "render show when true" {
  let visible = true
  let node = @signals.vshow(fn() { visible }, fn() {
    @signals.vtext("Visible!")
  })
  let html = render_to_string(node)
  assert_eq(html, "Visible!")
}

///|
test "render show when false" {
  let visible = false
  let node = @signals.vshow(fn() { visible }, fn() {
    @signals.vtext("Visible!")
  })
  let html = render_to_string(node)
  assert_eq(html, "<!--show-->")
}

///|
test "render for list" {
  let items = ["A", "B", "C"]
  let node = @signals.vfor(fn() {
    let result : Array[@signals.VNode] = []
    for i = 0; i < items.length(); i = i + 1 {
      result.push(@signals.vli([], [@signals.vtext(items[i])]))
    }
    result
  })
  let html = render_to_string(node)
  assert_eq(html, "<li>A</li><li>B</li><li>C</li>")
}

///|
test "render component" {
  fn greeting(name : String) -> @signals.VNode {
    @signals.vdiv([], [@signals.vtext("Hello, " + name + "!")])
  }

  let node = @signals.vcomponent(fn() { greeting("World") })
  let html = render_to_string(node)
  assert_eq(html, "<div>Hello, World!</div>")
}

///|
test "handlers are not rendered" {
  let node = @signals.vbutton(
    [@signals.von_click(@signals.event_handler()), @signals.vclass("btn")],
    [@signals.vtext("Click me")],
  )
  let html = render_to_string(node)
  // Handler should not appear in output
  assert_eq(html, "<button class=\"btn\">Click me</button>")
}

///|
test "escape attribute value" {
  let node = @signals.vdiv([@signals.vattr("data-value", "a\"b&c")], [])
  let html = render_to_string(node)
  assert_eq(html, "<div data-value=\"a&quot;b&amp;c\"></div>")
}

///|
test "render with hydration markers for dynamic text" {
  let count = 5
  let node = @signals.vtext_dyn(fn() { count.to_string() })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--t:0-->5<!--/t-->")
}

///|
test "render with hydration markers for element with handler" {
  let node = @signals.vbutton([@signals.von_click(@signals.event_handler())], [
    @signals.vtext("Click"),
  ])
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<button data-hk=\"0\">Click</button>")
}

///|
test "render with hydration markers for show" {
  let visible = true
  let node = @signals.vshow(fn() { visible }, fn() { @signals.vtext("Content") })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--s:0-->Content<!--/s-->")
}

///|
test "render with hydration markers for list" {
  let node = @signals.vfor(fn() { [@signals.vtext("A"), @signals.vtext("B")] })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--f:0-->AB<!--/f-->")
}

///|
test "complex page render" {
  let title = "My App"
  let count = 0
  let items = ["Item 1", "Item 2"]
  let page = @signals.vdiv([@signals.vclass("app")], [
    @signals.vh1([], [@signals.vtext(title)]),
    @signals.vp([], [
      @signals.vtext("Count: "),
      @signals.vtext_dyn(fn() { count.to_string() }),
    ]),
    @signals.vul([], [
      @signals.vfor(fn() {
        let result : Array[@signals.VNode] = []
        for i = 0; i < items.length(); i = i + 1 {
          result.push(@signals.vli([], [@signals.vtext(items[i])]))
        }
        result
      }),
    ]),
    @signals.vbutton([@signals.von_click(@signals.event_handler())], [
      @signals.vtext("Increment"),
    ]),
  ])
  let html = render_to_string(page)
  assert_true(html.contains("<h1>My App</h1>"))
  assert_true(html.contains("Count: 0"))
  assert_true(html.contains("<li>Item 1</li><li>Item 2</li>"))
  assert_true(html.contains("<button>Increment</button>"))
}
