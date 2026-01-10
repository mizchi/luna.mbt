// Tests for VNode

// =============================================================================
// EventHandler Tests
// =============================================================================

///|
test "EventHandler::get_callback" {
  let called : Ref[Bool] = { val: false }
  let h = handler(fn(_e : Unit) { called.val = true })
  let cb = h.get_callback()
  cb(())
  assert_true(called.val)
}

// =============================================================================
// Attr Factory Tests
// =============================================================================

///|
test "attr_static" {
  let attr : Attr[Unit] = attr_static("value")
  match attr {
    VStatic(s) => assert_eq(s, "value")
    _ => assert_true(false)
  }
}

///|
test "attr_dynamic" {
  let attr : Attr[Unit] = attr_dynamic(fn() { "dynamic" })
  match attr {
    VDynamic(getter) => assert_eq(getter(), "dynamic")
    _ => assert_true(false)
  }
}

///|
test "attr_handler" {
  let called : Ref[Bool] = { val: false }
  let h = handler(fn(_e : Unit) { called.val = true })
  let attr : Attr[Unit] = attr_handler(h)
  match attr {
    VHandler(handler) => {
      handler.get_callback()(())
      assert_true(called.val)
    }
    _ => assert_true(false)
  }
}

///|
test "attr_style" {
  let attr : Attr[Unit] = attr_style("color: red")
  match attr {
    VStatic(s) => assert_eq(s, "color: red")
    _ => assert_true(false)
  }
}

///|
test "attr_dynamic_style" {
  let attr : Attr[Unit] = attr_dynamic_style(fn() { "color: blue" })
  match attr {
    VDynamic(getter) => assert_eq(getter(), "color: blue")
    _ => assert_true(false)
  }
}

// Test enum for action

///|
enum TestAction {
  Increment
  Decrement
  Click
} derive(Show)

///|
test "action with enum - Increment" {
  let attr : Attr[Unit] = action(Increment)
  match attr {
    VAction(name) => assert_eq(name, "Increment")
    _ => assert_true(false)
  }
}

///|
test "action with enum - Decrement" {
  let attr : Attr[Unit] = action(Decrement)
  match attr {
    VAction(name) => assert_eq(name, "Decrement")
    _ => assert_true(false)
  }
}

// =============================================================================
// VNode Factory Tests
// =============================================================================

///|
test "h creates Element node" {
  let node : Node[Unit] = h("div", [], [])
  match node {
    Element(elem) => assert_eq(elem.tag, "div")
    _ => assert_true(false)
  }
}

///|
test "text creates Text node" {
  let node : Node[Unit] = text("hello")
  match node {
    Text(content) => assert_eq(content, "hello")
    _ => assert_true(false)
  }
}

///|
test "text_dyn creates DynamicText node" {
  let node : Node[Unit] = text_dyn(fn() { "dynamic" })
  match node {
    DynamicText(getter) => assert_eq(getter(), "dynamic")
    _ => assert_true(false)
  }
}

///|
test "text_of creates DynamicText node from signal" {
  let sig = @signal.signal(42)
  let node : Node[Unit] = text_of(sig)
  match node {
    DynamicText(getter) => assert_eq(getter(), "42")
    _ => assert_true(false)
  }
}

///|
test "fragment creates Fragment node" {
  let node : Node[Unit] = fragment([text("a"), text("b")])
  match node {
    Fragment(children) => assert_eq(children.length(), 2)
    _ => assert_true(false)
  }
}

///|
test "show creates Show node" {
  let node : Node[Unit] = show(fn() { true }, fn() { text("shown") })
  match node {
    Show(condition~, child~) => {
      assert_true(condition())
      match child() {
        Text(s) => assert_eq(s, "shown")
        _ => assert_true(false)
      }
    }
    _ => assert_true(false)
  }
}

///|
test "for_each creates For node" {
  let node : Node[Unit] = for_each(fn() { [text("a"), text("b")] })
  match node {
    For(render~) => assert_eq(render().length(), 2)
    _ => assert_true(false)
  }
}

///|
test "component creates Component node" {
  let node : Node[Unit] = component(fn() { text("component") })
  match node {
    Component(render~) =>
      match render() {
        Text(s) => assert_eq(s, "component")
        _ => assert_true(false)
      }
    _ => assert_true(false)
  }
}

///|
test "island creates Island node" {
  let node : Node[Unit] = island("id1", "/app.js", "{}", [text("child")])
  match node {
    Island(island) => {
      assert_eq(island.id, "id1")
      assert_eq(island.url, "/app.js")
      assert_eq(island.state, "{}")
      assert_eq(island.children.length(), 1)
    }
    _ => assert_true(false)
  }
}

///|
test "island with custom trigger" {
  let node : Node[Unit] = island(
    "id1",
    "/app.js",
    "{}",
    [],
    trigger=TriggerType::Idle,
  )
  match node {
    Island(island) =>
      match island.trigger {
        Idle => ()
        _ => assert_true(false)
      }
    _ => assert_true(false)
  }
}

///|
test "async_ creates Async node" {
  let node : Node[Unit] = async_(render=async fn() { text("resolved") }, fallback=fn() {
    text("loading")
  })
  match node {
    Async(async_node) =>
      match (async_node.fallback)() {
        Text(s) => assert_eq(s, "loading")
        _ => assert_true(false)
      }
    _ => assert_true(false)
  }
}

///|
test "error_boundary creates ErrorBoundary node" {
  let node : Node[Unit] = error_boundary(children=fn() { text("content") }, fallback=fn(
    _err,
    _reset,
  ) {
    text("error")
  })
  match node {
    ErrorBoundary(boundary) =>
      match (boundary.children)() {
        Text(s) => assert_eq(s, "content")
        _ => assert_true(false)
      }
    _ => assert_true(false)
  }
}

///|
test "match_case creates MatchCase" {
  let case_ : MatchCase[Unit] = match_case(when=fn() { true }, render=fn() {
    text("matched")
  })
  assert_true((case_.when)())
  match (case_.render)() {
    Text(s) => assert_eq(s, "matched")
    _ => assert_true(false)
  }
}

///|
test "switch_ creates Switch node" {
  let node : Node[Unit] = switch_(
    cases=[
      match_case(when=fn() { false }, render=fn() { text("first") }),
      match_case(when=fn() { true }, render=fn() { text("second") }),
    ],
    fallback=Some(fn() { text("fallback") }),
  )
  match node {
    Switch(switch_node) => {
      assert_eq(switch_node.cases.length(), 2)
      assert_true(switch_node.fallback is Some(_))
    }
    _ => assert_true(false)
  }
}

// =============================================================================
// TriggerType Tests
// =============================================================================

///|
test "TriggerType::to_string" {
  assert_eq(TriggerType::Load.to_string(), "load")
  assert_eq(TriggerType::Idle.to_string(), "idle")
  assert_eq(TriggerType::Visible.to_string(), "visible")
  assert_eq(
    TriggerType::Media("(min-width: 768px)").to_string(),
    "media:(min-width: 768px)",
  )
  assert_eq(TriggerType::None.to_string(), "none")
}

// =============================================================================
// has_dynamic_content Tests
// =============================================================================

///|
test "has_dynamic_content returns false for static attrs" {
  let attrs : Array[(String, Attr[Unit])] = [
    ("class", attr_static("foo")),
    ("id", attr_static("bar")),
  ]
  assert_true(not(has_dynamic_content(attrs)))
}

///|
test "has_dynamic_content returns true for VDynamic" {
  let attrs : Array[(String, Attr[Unit])] = [
    ("class", attr_static("foo")),
    ("value", attr_dynamic(fn() { "dynamic" })),
  ]
  assert_true(has_dynamic_content(attrs))
}

///|
test "has_dynamic_content returns true for VHandler" {
  let attrs : Array[(String, Attr[Unit])] = [
    ("onclick", attr_handler(handler(fn(_) { () }))),
  ]
  assert_true(has_dynamic_content(attrs))
}

///|
test "has_dynamic_content returns true for VAction" {
  let attrs : Array[(String, Attr[Unit])] = [("onclick", action(Click))]
  assert_true(has_dynamic_content(attrs))
}

///|
test "has_dynamic_content empty attrs" {
  let attrs : Array[(String, Attr[Unit])] = []
  assert_true(not(has_dynamic_content(attrs)))
}

// =============================================================================
// SSR Convenience Functions
// =============================================================================

///|
test "event_handler creates noop handler" {
  let h = event_handler()
  // Should not throw
  h.get_callback()(())
}

///|
test "handler_from_callback creates handler from callback" {
  let called : Ref[Bool] = { val: false }
  let h = handler_from_callback(fn() { called.val = true })
  h.get_callback()(())
  assert_true(called.val)
}

// =============================================================================
// ComponentRef Tests
// =============================================================================

///|
test "component_ref creates regular Island ref" {
  let cref : ComponentRef[Int] = component_ref("/static/counter.js", 42)
  assert_eq(cref.url, "/static/counter.js")
  assert_eq(cref.props, 42)
  assert_eq(cref.wc, false)
  match cref.trigger {
    Load => ()
    _ => assert_true(false)
  }
}

///|
test "component_ref with custom trigger" {
  let cref : ComponentRef[Int] = component_ref(
    "/static/counter.js",
    42,
    trigger=Idle,
  )
  match cref.trigger {
    Idle => ()
    _ => assert_true(false)
  }
}

///|
test "wc_component_ref creates Web Components ref" {
  let cref : ComponentRef[Int] = wc_component_ref("/static/wc_counter.js", 100)
  assert_eq(cref.url, "/static/wc_counter.js")
  assert_eq(cref.props, 100)
  assert_eq(cref.wc, true)
  match cref.trigger {
    Load => ()
    _ => assert_true(false)
  }
}

///|
test "wc_component_ref with custom trigger" {
  let cref : ComponentRef[String] = wc_component_ref(
    "/static/widget.js",
    "test",
    trigger=Visible,
  )
  assert_eq(cref.wc, true)
  match cref.trigger {
    Visible => ()
    _ => assert_true(false)
  }
}

// =============================================================================
// InternalRef Tests
// =============================================================================

///|
test "internal_ref creates InternalRef node" {
  let node : Node[Unit] = internal_ref("/static/counter.js", "{\"count\":0}")
  match node {
    InternalRef(iref) => {
      assert_eq(iref.url, "/static/counter.js")
      assert_eq(iref.state, "{\"count\":0}")
      assert_eq(iref.wc, false)
      assert_eq(iref.styles, "")
      assert_eq(iref.children.length(), 0)
    }
    _ => assert_true(false)
  }
}

///|
test "internal_ref with wc flag" {
  let node : Node[Unit] = internal_ref(
    "/static/wc_counter.js",
    "{}",
    wc=true,
    styles=":host { display: block; }",
    children=[text("child")],
  )
  match node {
    InternalRef(iref) => {
      assert_eq(iref.url, "/static/wc_counter.js")
      assert_eq(iref.wc, true)
      assert_eq(iref.styles, ":host { display: block; }")
      assert_eq(iref.children.length(), 1)
    }
    _ => assert_true(false)
  }
}

///|
test "internal_ref with custom trigger" {
  let node : Node[Unit] = internal_ref("/static/counter.js", "{}", trigger=Idle)
  match node {
    InternalRef(iref) =>
      match iref.trigger {
        Idle => ()
        _ => assert_true(false)
      }
    _ => assert_true(false)
  }
}

// =============================================================================
// Trigger Type Alias Test
// =============================================================================

///|
test "Trigger type alias works" {
  let t : Trigger = Load
  match t {
    Load => ()
    _ => assert_true(false)
  }
}
