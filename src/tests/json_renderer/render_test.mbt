//

///|
/// Tests for JSON Renderer

// Test enum for action
enum TestAction {
  Increment
} derive(Show)

///|
test "render simple text" {
  let node = @luna.text("Hello")
  let json = render_to_json(node)
  match json {
    Text(content) => assert_eq(content, "Hello")
    _ => assert_true(false)
  }
}

///|
test "render dynamic text" {
  let count = @signal.signal(42)
  let node = @luna.text_dyn(fn() { count.get().to_string() })
  let json = render_to_json(node)
  match json {
    Text(content) => assert_eq(content, "42")
    _ => assert_true(false)
  }
}

///|
test "render element with static attrs" {
  let node = @luna.h(
    "div",
    [
      ("class", @luna.attr_static("container")),
      ("id", @luna.attr_static("main")),
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
  let node = @luna.h(
    "div",
    [("style", @luna.attr_dynamic(fn() { "color: " + color.get() }))],
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
  let node = @luna.h("div", [], [
    @luna.text("First"),
    @luna.h("span", [], [@luna.text("Second")]),
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
  let node = @luna.fragment([@luna.text("A"), @luna.text("B"), @luna.text("C")])
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
  let node = @luna.show(fn() { visible.get() }, fn() { @luna.text("Visible") })
  let json = render_to_json(node)
  match json {
    Text(content) => assert_eq(content, "Visible")
    _ => assert_true(false)
  }
}

///|
test "render show when false" {
  let visible = @signal.signal(false)
  let node = @luna.show(fn() { visible.get() }, fn() { @luna.text("Hidden") })
  let json = render_to_json(node)
  match json {
    Fragment(children) => assert_eq(children.length(), 0)
    _ => assert_true(false)
  }
}

///|
test "render for loop" {
  let items = @signal.signal(["A", "B", "C"])
  let node = @luna.for_each(fn() {
    items.get().map(fn(item) { @luna.text(item) })
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
  fn my_component() -> @luna.Node[Unit] {
    @luna.h("div", [("class", @luna.attr_static("component"))], [
      @luna.text("Content"),
    ])
  }

  let node = @luna.component(my_component)
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
  let node = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.event_handler()))],
    [@luna.text("Click")],
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
  let node = @luna.h("div", [("id", @luna.attr_static("test"))], [
    @luna.text("Hello"),
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
  let node = @luna.h("div", [("class", @luna.attr_static("outer"))], [
    @luna.h("div", [("class", @luna.attr_static("inner"))], [
      @luna.h("span", [], [@luna.text("Deep")]),
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
  let node = @luna.text("Hello \"World\"\nNew line")
  let json_str = render_to_json_string(node)
  assert_true(json_str.contains("\\\""))
  assert_true(json_str.contains("\\n"))
}

///|
test "signal reactivity captured at render time" {
  let count = @signal.signal(10)
  let node = @luna.text_dyn(fn() { count.get().to_string() })

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

// =============================================================================
// Additional Coverage Tests
// =============================================================================

///|
test "render island node" {
  let node : @luna.Node[Unit] = @luna.island(
    "island-1",
    "/components/counter.js",
    "{\"count\":5}",
    [@luna.text("content")],
  )
  let json = render_to_json(node)
  match json {
    Element(elem) => {
      assert_eq(elem.tag, "div")
      // Check luna:* attributes
      match elem.attrs.get("luna:id") {
        Some(Static(v)) => assert_eq(v, "island-1")
        _ => assert_true(false)
      }
      match elem.attrs.get("luna:url") {
        Some(Static(v)) => assert_eq(v, "/components/counter.js")
        _ => assert_true(false)
      }
      match elem.attrs.get("luna:state") {
        Some(Static(v)) => assert_eq(v, "{\"count\":5}")
        _ => assert_true(false)
      }
      match elem.attrs.get("luna:client-trigger") {
        Some(Static(v)) => assert_eq(v, "load")
        _ => assert_true(false)
      }
      // Check children
      assert_eq(elem.children.length(), 1)
    }
    _ => assert_true(false)
  }
}

///|
test "render island with idle trigger" {
  let node : @luna.Node[Unit] = @luna.island(
    "lazy-1",
    "/lazy.js",
    "{}",
    [],
    trigger=@luna.Idle,
  )
  let json = render_to_json(node)
  match json {
    Element(elem) =>
      match elem.attrs.get("luna:client-trigger") {
        Some(Static(v)) => assert_eq(v, "idle")
        _ => assert_true(false)
      }
    _ => assert_true(false)
  }
}

///|
test "render async fallback" {
  let node : @luna.Node[Unit] = @luna.async_(
    render=async fn() { @luna.text("Loaded") },
    fallback=fn() { @luna.text("Loading...") },
  )
  let json = render_to_json(node)
  // Should render fallback
  match json {
    Text(content) => assert_eq(content, "Loading...")
    _ => assert_true(false)
  }
}

///|
test "render error_boundary success" {
  let node : @luna.Node[Unit] = @luna.error_boundary(
    children=fn() { @luna.h("div", [], [@luna.text("Success")]) },
    fallback=fn(_err, _reset) { @luna.text("Error") },
  )
  let json = render_to_json(node)
  match json {
    Element(elem) => {
      assert_eq(elem.tag, "div")
      assert_eq(elem.children.length(), 1)
    }
    _ => assert_true(false)
  }
}

///|
test "render switch first case match" {
  let node : @luna.Node[Unit] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { true }, render=fn() { @luna.text("First") }),
      @luna.match_case(when=fn() { true }, render=fn() { @luna.text("Second") }),
    ],
    fallback=Some(fn() { @luna.text("Fallback") }),
  )
  let json = render_to_json(node)
  match json {
    Text(content) => assert_eq(content, "First")
    _ => assert_true(false)
  }
}

///|
test "render switch second case match" {
  let node : @luna.Node[Unit] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() { @luna.text("First") }),
      @luna.match_case(when=fn() { true }, render=fn() { @luna.text("Second") }),
    ],
    fallback=Some(fn() { @luna.text("Fallback") }),
  )
  let json = render_to_json(node)
  match json {
    Text(content) => assert_eq(content, "Second")
    _ => assert_true(false)
  }
}

///|
test "render switch fallback" {
  let node : @luna.Node[Unit] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() { @luna.text("Never") }),
    ],
    fallback=Some(fn() { @luna.text("Fallback") }),
  )
  let json = render_to_json(node)
  match json {
    Text(content) => assert_eq(content, "Fallback")
    _ => assert_true(false)
  }
}

///|
test "render switch no fallback" {
  let node : @luna.Node[Unit] = @luna.switch_(cases=[
    @luna.match_case(when=fn() { false }, render=fn() { @luna.text("Never") }),
  ])
  let json = render_to_json(node)
  // Returns empty fragment when no case matches and no fallback
  match json {
    Fragment(children) => assert_eq(children.length(), 0)
    _ => assert_true(false)
  }
}

///|
test "render action attribute" {
  let node : @luna.Node[Unit] = @luna.h(
    "button",
    [("onclick", @luna.action(Increment))],
    [@luna.text("Click")],
  )
  let json = render_to_json(node)
  match json {
    Element(elem) =>
      match elem.attrs.get("onclick") {
        Some(Dynamic(v)) => assert_eq(v, "action:Increment")
        _ => assert_true(false)
      }
    _ => assert_true(false)
  }
}

///|
test "json_node_to_string element" {
  let node = json_element("span", { "id": attr_static("test") }, [
    json_text("content"),
  ])
  let str = json_node_to_string(node)
  assert_true(str.contains("\"type\":\"element\""))
  assert_true(str.contains("\"tag\":\"span\""))
  assert_true(str.contains("\"id\""))
  assert_true(str.contains("content"))
}

///|
test "json_node_to_string fragment" {
  let node = json_fragment([json_text("A"), json_text("B")])
  let str = json_node_to_string(node)
  assert_true(str.contains("\"type\":\"fragment\""))
  assert_true(str.contains("\"children\""))
}

///|
test "json_node_to_string dynamic attr" {
  let node = json_element(
    "div",
    { "value": attr_dynamic_value("dynamic-value") },
    [],
  )
  let str = json_node_to_string(node)
  assert_true(str.contains("\"type\":\"dynamic\""))
  assert_true(str.contains("dynamic-value"))
}

///|
test "json_node_to_string handler attr" {
  let node = json_element("button", { "onclick": attr_handler_value() }, [])
  let str = json_node_to_string(node)
  assert_true(str.contains("\"type\":\"handler\""))
}

///|
test "json string special char escaping" {
  let node = @luna.text("tab\there\rcarriage\nreturn\\backslash")
  let str = render_to_json_string(node)
  assert_true(str.contains("\\t"))
  assert_true(str.contains("\\r"))
  assert_true(str.contains("\\n"))
  assert_true(str.contains("\\\\"))
}

///|
test "json string with multiple attrs" {
  let node = @luna.h(
    "div",
    [
      ("id", @luna.attr_static("myid")),
      ("class", @luna.attr_static("myclass")),
      ("data-x", @luna.attr_dynamic(fn() { "dynamic" })),
    ],
    [],
  )
  let str = render_to_json_string(node)
  assert_true(str.contains("\"id\""))
  assert_true(str.contains("\"class\""))
  assert_true(str.contains("\"data-x\""))
}

///|
test "json_element children rendered in order" {
  let node = json_element("ul", {}, [
    json_text("first"),
    json_text("second"),
    json_text("third"),
  ])
  let str = json_node_to_string(node)
  // Check all are present in expected order
  assert_true(str.contains("first"))
  assert_true(str.contains("second"))
  assert_true(str.contains("third"))
}
