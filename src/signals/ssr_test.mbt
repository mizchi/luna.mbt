///|
/// SSR Tests
test "render simple text" {
  let node = vtext("Hello, World!")
  let html = render_to_string(node)
  assert_eq(html, "Hello, World!")
}

///|
test "render escaped text" {
  let node = vtext("<script>alert('xss')</script>")
  let html = render_to_string(node)
  assert_eq(html, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
}

///|
test "render simple element" {
  let node = vdiv([], [])
  let html = render_to_string(node)
  assert_eq(html, "<div></div>")
}

///|
test "render element with text child" {
  let node = vdiv([], [vtext("Hello")])
  let html = render_to_string(node)
  assert_eq(html, "<div>Hello</div>")
}

///|
test "render element with class" {
  let node = vdiv([vclass("container")], [])
  let html = render_to_string(node)
  assert_eq(html, "<div class=\"container\"></div>")
}

///|
test "render element with multiple attrs" {
  let node = vdiv([vid("main"), vclass("container")], [])
  let html = render_to_string(node)
  assert_eq(html, "<div id=\"main\" class=\"container\"></div>")
}

///|
test "render nested elements" {
  let node = vdiv([], [vspan([], [vtext("nested")])])
  let html = render_to_string(node)
  assert_eq(html, "<div><span>nested</span></div>")
}

///|
test "render void element" {
  let node = vinput([vtype("text"), vplaceholder("Enter name")])
  let html = render_to_string(node)
  assert_eq(html, "<input type=\"text\" placeholder=\"Enter name\" />")
}

///|
test "render br and hr" {
  let node = vfragment([vbr(), vhr()])
  let html = render_to_string(node)
  assert_eq(html, "<br /><hr />")
}

///|
test "render fragment" {
  let node = vfragment([vtext("A"), vtext("B"), vtext("C")])
  let html = render_to_string(node)
  assert_eq(html, "ABC")
}

///|
test "render dynamic text" {
  let count = Signal::new(42)
  let node = vtext_dyn(fn() { "Count: " + count.get().to_string() })
  let html = render_to_string(node)
  assert_eq(html, "Count: 42")
}

///|
test "render dynamic text from signal" {
  let name = Signal::new("Alice")
  let node = vtext_sig(name)
  let html = render_to_string(node)
  assert_eq(html, "Alice")
}

///|
test "render dynamic attribute" {
  let active = Signal::new(true)
  let node = vdiv(
    [vclass_dyn(fn() { if active.get() { "active" } else { "inactive" } })],
    [],
  )
  let html = render_to_string(node)
  assert_eq(html, "<div class=\"active\"></div>")
}

///|
test "render style attribute" {
  let node = vdiv([vstyle([("color", "red"), ("fontSize", "16px")])], [])
  let html = render_to_string(node)
  assert_eq(html, "<div style=\"color: red; font-size: 16px\"></div>")
}

///|
test "render disabled attribute true" {
  let node = vbutton([vdisabled(true)], [vtext("Submit")])
  let html = render_to_string(node)
  assert_eq(html, "<button disabled>Submit</button>")
}

///|
test "render disabled attribute false" {
  let node = vbutton([vdisabled(false)], [vtext("Submit")])
  let html = render_to_string(node)
  assert_eq(html, "<button>Submit</button>")
}

///|
test "render show when true" {
  let visible = Signal::new(true)
  let node = vshow(fn() { visible.get() }, fn() { vtext("Visible!") })
  let html = render_to_string(node)
  assert_eq(html, "Visible!")
}

///|
test "render show when false" {
  let visible = Signal::new(false)
  let node = vshow(fn() { visible.get() }, fn() { vtext("Visible!") })
  let html = render_to_string(node)
  assert_eq(html, "<!--show-->")
}

///|
test "render for list" {
  let items = Signal::new(["A", "B", "C"])
  let node = vfor(fn() {
    let arr = items.get()
    let result : Array[VNode] = []
    for i = 0; i < arr.length(); i = i + 1 {
      result.push(vli([], [vtext(arr[i])]))
    }
    result
  })
  let html = render_to_string(node)
  assert_eq(html, "<li>A</li><li>B</li><li>C</li>")
}

///|
test "render component" {
  fn greeting(name : String) -> VNode {
    vdiv([], [vtext("Hello, " + name + "!")])
  }

  let node = vcomponent(fn() { greeting("World") })
  let html = render_to_string(node)
  assert_eq(html, "<div>Hello, World!</div>")
}

///|
test "handlers are not rendered" {
  let node = vbutton([von_click(fn(_) { () }), vclass("btn")], [
    vtext("Click me"),
  ])
  let html = render_to_string(node)
  // Handler should not appear in output
  assert_eq(html, "<button class=\"btn\">Click me</button>")
}

///|
test "escape attribute value" {
  let node = vdiv([vattr("data-value", "a\"b&c")], [])
  let html = render_to_string(node)
  assert_eq(html, "<div data-value=\"a&quot;b&amp;c\"></div>")
}

///|
test "render with hydration markers for dynamic text" {
  let count = Signal::new(5)
  let node = vtext_dyn(fn() { count.get().to_string() })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--t:0-->5<!--/t-->")
}

///|
test "render with hydration markers for element with handler" {
  let node = vbutton([von_click(fn(_) { () })], [vtext("Click")])
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<button data-hk=\"0\">Click</button>")
}

///|
test "render with hydration markers for show" {
  let visible = Signal::new(true)
  let node = vshow(fn() { visible.get() }, fn() { vtext("Content") })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--s:0-->Content<!--/s-->")
}

///|
test "render with hydration markers for list" {
  let node = vfor(fn() { [vtext("A"), vtext("B")] })
  let html = render_to_string_with_hydration(node)
  assert_eq(html, "<!--f:0-->AB<!--/f-->")
}

///|
test "complex page render" {
  let title = Signal::new("My App")
  let count = Signal::new(0)
  let items = Signal::new(["Item 1", "Item 2"])
  let page = vdiv([vclass("app")], [
    vh1([], [vtext_sig(title)]),
    vp([], [vtext("Count: "), vtext_dyn(fn() { count.get().to_string() })]),
    vul([], [
      vfor(fn() {
        let arr = items.get()
        let result : Array[VNode] = []
        for i = 0; i < arr.length(); i = i + 1 {
          result.push(vli([], [vtext(arr[i])]))
        }
        result
      }),
    ]),
    vbutton([von_click(fn(_) { count.update(fn(n) { n + 1 }) })], [
      vtext("Increment"),
    ]),
  ])
  let html = render_to_string(page)
  assert_true(html.contains("<h1>My App</h1>"))
  assert_true(html.contains("Count: 0"))
  assert_true(html.contains("<li>Item 1</li><li>Item 2</li>"))
  assert_true(html.contains("<button>Increment</button>"))
}
