///|
using @test {assert_eq}

// Tests for VNode

// =============================================================================
// EventHandler Tests
// =============================================================================

///|
test "EventHandler::get_callback" {
  let called : Ref[Bool] = Ref(false)
  let h = @core.handler(fn(_e : Unit) { called.val = true })
  let cb = h.get_callback()
  cb(())
  assert_true(called.val)
}

// =============================================================================
// Attr Factory Tests
// =============================================================================

///|
test "attr_static" {
  let attr : @core.Attr[Unit, String] = @core.attr_static("value")
  match attr {
    VStatic(s) => assert_eq(s, "value")
    _ => assert_true(false)
  }
}

///|
test "attr_dynamic" {
  let attr : @core.Attr[Unit, String] = @core.attr_dynamic(fn() { "dynamic" })
  match attr {
    VDynamic(getter) => assert_eq(getter(), "dynamic")
    _ => assert_true(false)
  }
}

///|
test "attr_handler" {
  let called : Ref[Bool] = Ref(false)
  let h = @core.handler(fn(_e : Unit) { called.val = true })
  let attr : @core.Attr[Unit, String] = @core.attr_handler(h)
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
  let attr : @core.Attr[Unit, String] = @core.attr_style("color: red")
  match attr {
    VStatic(s) => assert_eq(s, "color: red")
    _ => assert_true(false)
  }
}

///|
test "attr_dynamic_style" {
  let attr : @core.Attr[Unit, String] = @core.attr_dynamic_style(fn() {
    "color: blue"
  })
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
} derive(Debug)

///|
impl Show for TestAction with fn output(self, logger) {
  logger.write_string(
    match self {
      Increment => "Increment"
      Decrement => "Decrement"
      Click => "Click"
    },
  )
}

///|
test "action with enum - Increment" {
  let attr : @core.Attr[Unit, String] = @core.action(Increment)
  match attr {
    VAction(name) => assert_eq(name, "Increment")
    _ => assert_true(false)
  }
}

///|
test "action with enum - Decrement" {
  let attr : @core.Attr[Unit, String] = @core.action(Decrement)
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
  let node : @core.Node[Unit, String] = @core.h("div", [], [])
  match node {
    Element(elem) => assert_eq(elem.tag, "div")
    _ => assert_true(false)
  }
}

///|
test "text creates Text node" {
  let node : @core.Node[Unit, String] = @core.text("hello")
  match node {
    Text(content) => assert_eq(content, "hello")
    _ => assert_true(false)
  }
}

///|
test "text_dyn creates DynamicText node" {
  let node : @core.Node[Unit, String] = @core.text_dyn(fn() { "dynamic" })
  match node {
    DynamicText(getter) => assert_eq(getter(), "dynamic")
    _ => assert_true(false)
  }
}

///|
test "fragment creates Fragment node" {
  let node : @core.Node[Unit, String] = @core.fragment([
    @core.text("a"),
    @core.text("b"),
  ])
  match node {
    Fragment(children) => assert_eq(children.length(), 2)
    _ => assert_true(false)
  }
}

///|
test "raw_trusted_html requires explicit trusted wrapper" {
  let trusted = @core.unsafe_trusted_html("<strong>trusted</strong>")
  assert_eq(trusted.to_string(), "<strong>trusted</strong>")
  let node : @core.Node[Unit, String] = @core.raw_trusted_html(trusted)
  match node {
    RawHtml(content) => assert_eq(content, "<strong>trusted</strong>")
    _ => assert_true(false)
  }
}

///|
test "show creates Show node" {
  let node : @core.Node[Unit, String] = @core.show(fn() { true }, fn() {
    @core.text("shown")
  })
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
  let node : @core.Node[Unit, String] = @core.for_each(fn() {
    [@core.text("a"), @core.text("b")]
  })
  match node {
    For(render~) => assert_eq(render().length(), 2)
    _ => assert_true(false)
  }
}

///|
test "component creates Component node" {
  let node : @core.Node[Unit, String] = @core.component(fn() {
    @core.text("component")
  })
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
test "async_ creates Async node" {
  let node : @core.Node[Unit, String] = @core.async_(
    render=fn() { @core.text("resolved") },
    fallback=fn() { @core.text("loading") },
  )
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
  let node : @core.Node[Unit, String] = @core.error_boundary(
    children=fn() { @core.text("content") },
    fallback=fn(_err, _reset) { @core.text("error") },
  )
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
  let case_ : @core.MatchCase[Unit, String] = @core.match_case(
    when=fn() { true },
    render=fn() { @core.text("matched") },
  )
  assert_true((case_.when)())
  match (case_.render)() {
    Text(s) => assert_eq(s, "matched")
    _ => assert_true(false)
  }
}

///|
test "switch_ creates Switch node" {
  let node : @core.Node[Unit, String] = @core.switch_(
    cases=[
      @core.match_case(when=fn() { false }, render=fn() { @core.text("first") }),
      @core.match_case(when=fn() { true }, render=fn() { @core.text("second") }),
    ],
    fallback=Some(fn() { @core.text("fallback") }),
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
  assert_eq(@core.TriggerType::Load.to_string(), "load")
  assert_eq(@core.TriggerType::Idle.to_string(), "idle")
  assert_eq(@core.TriggerType::Visible.to_string(), "visible")
  assert_eq(
    @core.TriggerType::Media("(min-width: 768px)").to_string(),
    "media:(min-width: 768px)",
  )
  assert_eq(@core.TriggerType::None.to_string(), "none")
}

// =============================================================================
// has_dynamic_content Tests
// =============================================================================

///|
test "has_dynamic_content returns false for static attrs" {
  let attrs : Array[(String, @core.Attr[Unit, String])] = [
    ("class", @core.attr_static("foo")),
    ("id", @core.attr_static("bar")),
  ]
  assert_true(!@core.has_dynamic_content(attrs))
}

///|
test "has_dynamic_content returns true for VDynamic" {
  let attrs : Array[(String, @core.Attr[Unit, String])] = [
    ("class", @core.attr_static("foo")),
    ("value", @core.attr_dynamic(fn() { "dynamic" })),
  ]
  assert_true(@core.has_dynamic_content(attrs))
}

///|
test "has_dynamic_content returns true for VHandler" {
  let attrs : Array[(String, @core.Attr[Unit, String])] = [
    ("onclick", @core.attr_handler(@core.handler(fn(_) { () }))),
  ]
  assert_true(@core.has_dynamic_content(attrs))
}

///|
test "has_dynamic_content returns true for VAction" {
  let attrs : Array[(String, @core.Attr[Unit, String])] = [
    ("onclick", @core.action(Click)),
  ]
  assert_true(@core.has_dynamic_content(attrs))
}

///|
test "has_dynamic_content empty attrs" {
  let attrs : Array[(String, @core.Attr[Unit, String])] = []
  assert_true(!@core.has_dynamic_content(attrs))
}

// =============================================================================
// SSR Convenience Functions
// =============================================================================

///|
test "event_handler creates noop handler" {
  let h = @core.event_handler()
  // Should not throw
  h.get_callback()(())
}

///|
test "handler_from_callback creates handler from callback" {
  let called : Ref[Bool] = Ref(false)
  let h = @core.handler_from_callback(fn() { called.val = true })
  h.get_callback()(())
  assert_true(called.val)
}

// =============================================================================
// ComponentRef Tests
// =============================================================================

///|
test "component_ref creates Web Components ref" {
  let cref : @core.ComponentRef[Int] = @core.component_ref(
    "/static/counter.js", 42,
  )
  assert_eq(cref.url, "/static/counter.js")
  assert_eq(cref.props, 42)
  match cref.trigger {
    Load => ()
    _ => assert_true(false)
  }
}

///|
test "component_ref with custom trigger" {
  let cref : @core.ComponentRef[Int] = @core.component_ref(
    "/static/counter.js",
    42,
    trigger=Idle,
  )
  match cref.trigger {
    Idle => ()
    _ => assert_true(false)
  }
}

// =============================================================================
// InternalRef Tests
// =============================================================================

///|
test "internal_ref creates InternalRef node" {
  let node : @core.Node[Unit, String] = @core.internal_ref(
    "/static/wc-counter.js", "{\"count\":0}",
  )
  match node {
    InternalRef(iref) => {
      assert_eq(iref.url, "/static/wc-counter.js")
      assert_eq(iref.state, "{\"count\":0}")
      assert_eq(iref.styles, "")
      assert_eq(iref.children.length(), 0)
    }
    _ => assert_true(false)
  }
}

///|
test "internal_ref with styles and children" {
  let node : @core.Node[Unit, String] = @core.internal_ref(
    "/static/wc_counter.js",
    "{}",
    styles=":host { display: block; }",
    children=[@core.text("child")],
  )
  match node {
    InternalRef(iref) => {
      assert_eq(iref.url, "/static/wc_counter.js")
      assert_eq(iref.styles, ":host { display: block; }")
      assert_eq(iref.children.length(), 1)
    }
    _ => assert_true(false)
  }
}

///|
test "internal_ref with custom trigger" {
  let node : @core.Node[Unit, String] = @core.internal_ref(
    "/static/counter.js",
    "{}",
    trigger=Idle,
  )
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
  let t : @core.Trigger = Load
  match t {
    Load => ()
    _ => assert_true(false)
  }
}
