///| Tests for JSON Renderer

///|
test "render simple text" {
  let node = @kaguya.vtext("Hello")
  let json = render_to_json(node)
  match json {
    Text(content) => assert_eq(content, "Hello")
    _ => assert_true(false)
  }
}

///|
test "render dynamic text" {
  let count = @signal.signal(42)
  let node = @kaguya.text_dyn(fn() { count.get().to_string() })
  let json = render_to_json(node)
  match json {
    Text(content) => assert_eq(content, "42")
    _ => assert_true(false)
  }
}

///|
test "render element with static attrs" {
  let node = @kaguya.h(
    "div",
    [
      ("class", @kaguya.attr_static("container")),
      ("id", @kaguya.attr_static("main")),
    ],
    [],
  )
  let json = render_to_json(node)
  match json {
    Element(elem) => {
      assert_eq(elem.tag, "div")
      match elem.attrs.get("class") {
        Some(Static(v)) => assert_eq(v, "container")
        _ => assert_true(false)
      }
      match elem.attrs.get("id") {
        Some(Static(v)) => assert_eq(v, "main")
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

///|
test "render element with dynamic attr" {
  let color = @signal.signal("red")
  let node = @kaguya.h(
    "div",
    [("style", @kaguya.attr_dynamic(fn() { "color: " + color.get() }))],
    [],
  )
  let json = render_to_json(node)
  match json {
    Element(elem) =>
      match elem.attrs.get("style") {
        Some(Dynamic(v)) => assert_eq(v, "color: red")
        _ => assert_true(false)
      }
    _ => assert_true(false)
  }
}

///|
test "render element with children" {
  let node = @kaguya.h("div", [], [
    @kaguya.vtext("First"),
    @kaguya.h("span", [], [@kaguya.vtext("Second")]),
  ])
  let json = render_to_json(node)
  match json {
    Element(elem) => {
      assert_eq(elem.tag, "div")
      assert_eq(elem.children.length(), 2)
      match elem.children[0] {
        Text(content) => assert_eq(content, "First")
        _ => assert_true(false)
      }
      match elem.children[1] {
        Element(child) => assert_eq(child.tag, "span")
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

///|
test "render fragment" {
  let node = @kaguya.vfragment([
    @kaguya.vtext("A"),
    @kaguya.vtext("B"),
    @kaguya.vtext("C"),
  ])
  let json = render_to_json(node)
  match json {
    Fragment(children) => {
      assert_eq(children.length(), 3)
      match children[0] {
        Text(content) => assert_eq(content, "A")
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

///|
test "render show when true" {
  let visible = @signal.signal(true)
  let node = @kaguya.vshow(fn() { visible.get() }, fn() {
    @kaguya.vtext("Visible")
  })
  let json = render_to_json(node)
  match json {
    Text(content) => assert_eq(content, "Visible")
    _ => assert_true(false)
  }
}

///|
test "render show when false" {
  let visible = @signal.signal(false)
  let node = @kaguya.vshow(fn() { visible.get() }, fn() {
    @kaguya.vtext("Hidden")
  })
  let json = render_to_json(node)
  match json {
    Fragment(children) => assert_eq(children.length(), 0)
    _ => assert_true(false)
  }
}

///|
test "render for loop" {
  let items = @signal.signal(["A", "B", "C"])
  let node = @kaguya.vfor(fn() {
    let arr = items.get()
    let result : Array[@kaguya.Node[Unit]] = []
    for item in arr {
      result.push(@kaguya.vtext(item))
    }
    result
  })
  let json = render_to_json(node)
  match json {
    Fragment(children) => {
      assert_eq(children.length(), 3)
      match children[0] {
        Text(content) => assert_eq(content, "A")
        _ => assert_true(false)
      }
      match children[2] {
        Text(content) => assert_eq(content, "C")
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

///|
test "render component" {
  fn my_component() -> @kaguya.Node[Unit] {
    @kaguya.h("div", [("class", @kaguya.attr_static("component"))], [
      @kaguya.vtext("Content"),
    ])
  }

  let node = @kaguya.vcomponent(my_component)
  let json = render_to_json(node)
  match json {
    Element(elem) => {
      assert_eq(elem.tag, "div")
      match elem.attrs.get("class") {
        Some(Static(v)) => assert_eq(v, "component")
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

///|
test "render event handler" {
  let node = @kaguya.h(
    "button",
    [("onClick", @kaguya.attr_handler(@kaguya.event_handler()))],
    [@kaguya.vtext("Click")],
  )
  let json = render_to_json(node)
  match json {
    Element(elem) => {
      assert_eq(elem.tag, "button")
      match elem.attrs.get("onClick") {
        Some(Handler) => assert_true(true)
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

///|
test "render to json string" {
  let node = @kaguya.h("div", [("id", @kaguya.attr_static("test"))], [
    @kaguya.vtext("Hello"),
  ])
  let json_str = render_to_json_string(node)
  assert_true(json_str.contains("\"type\":\"element\""))
  assert_true(json_str.contains("\"tag\":\"div\""))
  assert_true(json_str.contains("\"id\""))
  assert_true(json_str.contains("Hello"))
}

///|
test "json node helpers" {
  let node = json_element("div", { "class": attr_static("container") }, [
    json_text("Hello"),
  ])
  assert_eq(node.tag(), Some("div"))
  assert_eq(node.children().length(), 1)
  match node.get_attr("class") {
    Some(Static(v)) => assert_eq(v, "container")
    _ => assert_true(false)
  }
}

///|
test "text node has no children" {
  let node = json_text("Hello")
  assert_eq(node.tag(), None)
  assert_eq(node.children().length(), 0)
  assert_eq(node.get_attr("any"), None)
}

///|
test "fragment children" {
  let node = json_fragment([json_text("A"), json_text("B")])
  assert_eq(node.tag(), None)
  assert_eq(node.children().length(), 2)
}

///|
test "nested structure" {
  let node = @kaguya.h("div", [("class", @kaguya.attr_static("outer"))], [
    @kaguya.h("div", [("class", @kaguya.attr_static("inner"))], [
      @kaguya.h("span", [], [@kaguya.vtext("Deep")]),
    ]),
  ])
  let json = render_to_json(node)
  match json {
    Element(outer) => {
      assert_eq(outer.tag, "div")
      match outer.children[0] {
        Element(inner) => {
          assert_eq(inner.tag, "div")
          match inner.children[0] {
            Element(span) => {
              assert_eq(span.tag, "span")
              match span.children[0] {
                Text(content) => assert_eq(content, "Deep")
                _ => assert_true(false)
              }
            }
            _ => assert_true(false)
          }
        }
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

///|
test "json string escaping" {
  let node = @kaguya.vtext("Hello \"World\"\nNew line")
  let json_str = render_to_json_string(node)
  assert_true(json_str.contains("\\\""))
  assert_true(json_str.contains("\\n"))
}

///|
test "signal reactivity captured at render time" {
  let count = @signal.signal(10)
  let node = @kaguya.text_dyn(fn() { count.get().to_string() })

  // First render
  let json1 = render_to_json(node)
  match json1 {
    Text(content) => assert_eq(content, "10")
    _ => assert_true(false)
  }

  // Update signal
  count.set(20)

  // Second render captures new value
  let json2 = render_to_json(node)
  match json2 {
    Text(content) => assert_eq(content, "20")
    _ => assert_true(false)
  }
}
