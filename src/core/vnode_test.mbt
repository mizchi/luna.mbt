///| Tests for VNode

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
test "vtext creates Text node" {
  let node : Node[Unit] = vtext("hello")
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
test "vtext_sig creates DynamicText node from signal" {
  let sig = @signal.signal(42)
  let node : Node[Unit] = vtext_sig(sig)
  match node {
    DynamicText(getter) => assert_eq(getter(), "42")
    _ => assert_true(false)
  }
}

///|
test "vfragment creates Fragment node" {
  let node : Node[Unit] = vfragment([vtext("a"), vtext("b")])
  match node {
    Fragment(children) => assert_eq(children.length(), 2)
    _ => assert_true(false)
  }
}

///|
test "vshow creates Show node" {
  let node : Node[Unit] = vshow(fn() { true }, fn() { vtext("shown") })
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
test "vfor creates For node" {
  let node : Node[Unit] = vfor(fn() { [vtext("a"), vtext("b")] })
  match node {
    For(render~) => assert_eq(render().length(), 2)
    _ => assert_true(false)
  }
}

///|
test "vcomponent creates Component node" {
  let node : Node[Unit] = vcomponent(fn() { vtext("component") })
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
test "visland creates Island node" {
  let node : Node[Unit] = visland("id1", "/app.js", "{}", [vtext("child")])
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
test "visland with custom trigger" {
  let node : Node[Unit] = visland(
    "id1",
    "/app.js",
    "{}",
    [],
    trigger=IslandTrigger::Idle,
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
test "vasync creates Async node" {
  let node : Node[Unit] = vasync(render=async fn() { vtext("resolved") }, fallback=fn() {
    vtext("loading")
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
  let node : Node[Unit] = error_boundary(children=fn() { vtext("content") }, fallback=fn(
    _err,
    _reset,
  ) {
    vtext("error")
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
    vtext("matched")
  })
  assert_true((case_.when)())
  match (case_.render)() {
    Text(s) => assert_eq(s, "matched")
    _ => assert_true(false)
  }
}

///|
test "vswitch creates Switch node" {
  let node : Node[Unit] = vswitch(
    cases=[
      match_case(when=fn() { false }, render=fn() { vtext("first") }),
      match_case(when=fn() { true }, render=fn() { vtext("second") }),
    ],
    fallback=Some(fn() { vtext("fallback") }),
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
// IslandTrigger Tests
// =============================================================================

///|
test "trigger_to_string" {
  assert_eq(trigger_to_string(Load), "load")
  assert_eq(trigger_to_string(Idle), "idle")
  assert_eq(trigger_to_string(Visible), "visible")
  assert_eq(
    trigger_to_string(Media("(min-width: 768px)")),
    "media:(min-width: 768px)",
  )
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
