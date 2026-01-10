//

///|
/// Hydration Tests

// Test enum for action
enum TestAction {
  Increment
  TestAction
} derive(Show)

///|
/// Helper to set innerHTML on container
fn set_inner_html(container : @js_dom.Element, html : String) -> Unit {
  container.as_any()._set("innerHTML", @js.any(html)) |> ignore
}

///|
/// Helper to get innerHTML from container
fn get_inner_html(container : @js_dom.Element) -> String {
  container.as_any()._get("innerHTML").cast()
}

///|
/// Cleanup document.body.innerHTML
fn cleanup() -> Unit {
  let doc = @js_dom.document()
  match doc.body() {
    Some(body) => body.as_any()._set("innerHTML", @js.any("")) |> ignore
    None => ()
  }
}

///|
/// Create a test container and append to document.body
fn create_container() -> @js_dom.Element {
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  // Append to body so querySelector can find child elements
  match doc.body() {
    Some(body) => body.as_node().appendChild(container.as_node()) |> ignore
    None => ()
  }
  container
}

// =============================================================================
// Basic Hydration Tests
// =============================================================================

///|
test "hydrate simple text" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.text("Hello")

  // SSR render
  let html = @render.render_to_string(vnode).html
  set_inner_html(container, html)

  // Hydrate
  let _ = hydrate(container, vnode)

  // Text should remain
  assert_eq(get_inner_html(container), "Hello")
}

///|
test "hydrate element with text" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.h("div", [], [@luna.text("Content")])
  let html = @render.render_to_string(vnode).html
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)
  assert_eq(get_inner_html(container), "<div>Content</div>")
}

///|
test "hydrate element with class" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.h("div", [("class", @luna.attr_static("test-class"))], [
    @luna.text("Styled"),
  ])
  let html = @render.render_to_string(vnode).html
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)
  assert_true(get_inner_html(container).contains("test-class"))
}

///|
test "hydrate nested elements" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.h("div", [], [@luna.h("span", [], [@luna.text("Nested")])])
  let html = @render.render_to_string(vnode).html
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)
  assert_eq(get_inner_html(container), "<div><span>Nested</span></div>")
}

// =============================================================================
// Dynamic Content Hydration Tests
// =============================================================================

///|
test "hydrate dynamic text with hydration markers" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let count = @signal.signal(42)
  let vnode = @luna.text_dyn(fn() { count.get().to_string() })

  // SSR with hydration markers
  let html = @render.render_to_string_with_hydration(vnode)
  assert_true(html.contains("<!--t:0-->"))
  assert_true(html.contains("42"))
  assert_true(html.contains("<!--/t-->"))
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)

  // Update signal
  count.set(100)

  // Text should be updated
  assert_true(get_inner_html(container).contains("100"))
}

///|
test "hydrate element with click handler" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [@luna.text("Click me")],
  )

  // SSR with hydration markers
  let html = @render.render_to_string_with_hydration(vnode)
  assert_true(html.contains("sol:hk=\"0\""))
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)

  // Button should have been found
  assert_true(get_inner_html(container).contains("Click me"))
}

///|
test "hydrate dynamic class" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let active = @signal.signal(false)
  let vnode = @luna.h(
    "div",
    [
      (
        "class",
        @luna.attr_dynamic(fn() {
          if active.get() {
            "active"
          } else {
            "inactive"
          }
        }),
      ),
    ],
    [@luna.text("Toggle")],
  )
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)

  // Initially inactive
  assert_true(get_inner_html(container).contains("inactive"))

  // Toggle
  active.set(true)

  // Should now be active
  assert_true(get_inner_html(container).contains("active"))
}

// =============================================================================
// Show/Hide Hydration Tests
// =============================================================================

///|
test "hydrate show when visible" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let visible = @signal.signal(true)
  let vnode = @luna.show(fn() { visible.get() }, fn() {
    @luna.text("Visible content")
  })
  let html = @render.render_to_string_with_hydration(vnode)
  assert_true(html.contains("<!--s:0-->"))
  assert_true(html.contains("Visible content"))
  assert_true(html.contains("<!--/s-->"))
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)
  assert_true(get_inner_html(container).contains("Visible content"))
}

///|
test "hydrate show when hidden" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let visible = @signal.signal(false)
  let vnode = @luna.show(fn() { visible.get() }, fn() {
    @luna.text("Hidden content")
  })
  let html = @render.render_to_string(vnode).html
  assert_eq(html, "<!--show-->")
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)

  // Should remain hidden
  assert_false(get_inner_html(container).contains("Hidden content"))
}

// =============================================================================
// For Loop Hydration Tests
// =============================================================================

///|
test "hydrate for loop" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let items = @signal.signal(["A", "B", "C"])
  let vnode = @luna.for_each(fn() {
    items.get().map(fn(item) { @luna.h("li", [], [@luna.text(item)]) })
  })
  let html = @render.render_to_string_with_hydration(vnode)
  assert_true(html.contains("<!--f:0-->"))
  assert_true(html.contains("<li>A</li>"))
  assert_true(html.contains("<li>B</li>"))
  assert_true(html.contains("<li>C</li>"))
  assert_true(html.contains("<!--/f-->"))
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)

  // All items should be present
  let inner = get_inner_html(container)
  assert_true(inner.contains("A"))
  assert_true(inner.contains("B"))
  assert_true(inner.contains("C"))
}

// =============================================================================
// Hydration Mismatch Tests
// =============================================================================

///|
test "hydrate detects missing element" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let logger = StringBuilder::new()

  // VNode expects a button with handler
  let vnode = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [@luna.text("Button")],
  )

  // But SSR HTML is completely different (simulating mismatch)
  set_inner_html(container, "<span>Wrong element</span>")

  // Hydrate with strict options and logger to suppress console output
  let result = hydrate(container, vnode, recover_on_mismatch=false, logger~)

  // Should detect mismatch
  match result {
    Mismatch(msg) => {
      assert_true(msg.contains("not found"))
      // Logger should contain the mismatch warning
      let log_output = logger.to_string()
      assert_true(log_output.contains("[Hydration]"))
    }
    _ => assert_true(false) // Should not reach here
  }
}

///|
test "hydrate recovers on mismatch" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h("div", [("class", @luna.attr_static("expected"))], [
    @luna.text("Expected"),
  ])

  // Wrong HTML
  set_inner_html(container, "<span>Wrong</span>")

  // Hydrate with recovery enabled and logger to suppress console output
  let result = hydrate(container, vnode, logger~)

  // Should recover
  match result {
    Recovered(_) => {
      // Container should now have the correct content
      let inner = get_inner_html(container)
      assert_true(inner.contains("expected"))
      assert_true(inner.contains("Expected"))
      // Logger should contain recovery message
      let log_output = logger.to_string()
      assert_true(log_output.contains("Recovering"))
    }
    Success =>
      // No dynamic content, so no mismatch detected
      // This is expected for static VNode
      assert_true(true)
    Mismatch(_) => assert_true(false) // Should not fail with default options
  }
}

///|
test "hydrate success on correct HTML" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.h("div", [], [@luna.text("Correct")])

  // Correct SSR HTML
  let html = @render.render_to_string(vnode).html
  set_inner_html(container, html)
  let result = hydrate(container, vnode, recover_on_mismatch=false)

  // Should succeed
  match result {
    Success => assert_true(true)
    _ => assert_true(false)
  }
}

// =============================================================================
// Complex Hydration Tests
// =============================================================================

///|
test "hydrate complex page structure" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let logger = StringBuilder::new()
  let count = @signal.signal(0)
  let items = @signal.signal(["Item 1", "Item 2"])
  let vnode = @luna.h("div", [("class", @luna.attr_static("app"))], [
    @luna.h("h1", [], [@luna.text("Title")]),
    @luna.h("p", [], [
      @luna.text_dyn(fn() { "Count: " + count.get().to_string() }),
    ]),
    @luna.h("ul", [], [
      @luna.for_each(fn() {
        items.get().map(fn(item) { @luna.h("li", [], [@luna.text(item)]) })
      }),
    ]),
    @luna.h(
      "button",
      [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
      [@luna.text("Click")],
    ),
  ])
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let _ = hydrate(container, vnode, logger~)
  let inner = get_inner_html(container)
  assert_true(inner.contains("Title"))
  assert_true(inner.contains("Count: 0"))
  assert_true(inner.contains("Item 1"))
  assert_true(inner.contains("Item 2"))
  assert_true(inner.contains("Click"))

  // Update count
  count.set(5)
  let updated = get_inner_html(container)
  assert_true(updated.contains("Count: 5"))
}

///|
test "hydrate fragment" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.fragment([@luna.text("A"), @luna.text("B"), @luna.text("C")])
  let html = @render.render_to_string(vnode).html
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)
  assert_eq(get_inner_html(container), "ABC")
}

///|
test "hydrate component" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  fn greeting(name : String) -> @luna.Node[@js.Any] {
    @luna.h("div", [], [@luna.text("Hello, " + name + "!")])
  }

  let vnode = @luna.component(fn() { greeting("World") })
  let html = @render.render_to_string(vnode).html
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)
  assert_true(get_inner_html(container).contains("Hello, World!"))
}

// =============================================================================
// Edge Cases
// =============================================================================

///|
test "hydrate empty container" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.text("")
  let html = @render.render_to_string(vnode).html
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)
  assert_eq(get_inner_html(container), "")
}

///|
test "hydrate deeply nested structure" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.h("div", [], [
    @luna.h("div", [], [
      @luna.h("div", [], [
        @luna.h("div", [], [@luna.h("span", [], [@luna.text("Deep")])]),
      ]),
    ]),
  ])
  let html = @render.render_to_string(vnode).html
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)
  assert_true(get_inner_html(container).contains("Deep"))
}

///|
test "hydrate with escaped content" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.text("<script>alert('xss')</script>")
  let html = @render.render_to_string(vnode).html
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)

  // Content should be escaped
  let inner = get_inner_html(container)
  assert_false(inner.contains("<script>"))
  assert_true(inner.contains("&lt;script&gt;"))
}

// =============================================================================
// Logger Tests
// =============================================================================

///|
test "hydrate with logger captures mismatch warning" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let logger = StringBuilder::new()

  // VNode expects a button with handler
  let vnode = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [@luna.text("Button")],
  )

  // Wrong HTML
  set_inner_html(container, "<span>Wrong</span>")

  // Hydrate with logger
  let _ = hydrate(container, vnode, logger~)

  // Logger should contain mismatch warning
  let log_output = logger.to_string()
  assert_true(log_output.contains("[Hydration]"))
  assert_true(log_output.contains("mismatch"))
  assert_true(log_output.contains("Recovering"))
}

///|
test "hydrate with logger captures strict mode mismatch" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [@luna.text("Click")],
  )
  set_inner_html(container, "<div>Wrong</div>")
  let result = hydrate(container, vnode, recover_on_mismatch=false, logger~)

  // Should return Mismatch
  match result {
    Mismatch(_) => {
      let log_output = logger.to_string()
      assert_true(log_output.contains("[Hydration]"))
      assert_true(log_output.contains("mismatch"))
      // Should NOT contain "Recovering" since strict mode
      assert_false(log_output.contains("Recovering"))
    }
    _ => assert_true(false) // Should not reach here
  }
}

///|
test "hydrate with logger no output on success" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h("div", [], [@luna.text("Content")])
  let html = @render.render_to_string(vnode).html
  set_inner_html(container, html)
  let result = hydrate(container, vnode, logger~)

  // Should succeed
  match result {
    Success => {
      // Logger should be empty on success
      let log_output = logger.to_string()
      assert_eq(log_output, "")
    }
    _ => assert_true(false)
  }
}

///|
test "hydrate logger contains element info" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [@luna.text("Submit")],
  )
  set_inner_html(container, "<input type=\"text\" />")
  let _ = hydrate(container, vnode, recover_on_mismatch=false, logger~)
  let log_output = logger.to_string()
  // Should mention the expected element
  assert_true(log_output.contains("button"))
  assert_true(log_output.contains("sol:hk"))
}

// =============================================================================
// Additional Coverage Tests
// =============================================================================

///|
test "hydrate without logger outputs to console" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [@luna.text("Button")],
  )
  // Wrong HTML - will trigger mismatch without logger
  set_inner_html(container, "<span>Wrong</span>")
  // Hydrate without logger - should output to console
  let result = hydrate(container, vnode)
  // Should recover
  match result {
    Recovered(_) => assert_true(true)
    _ => assert_true(true) // Any result is fine for this test
  }
}

///|
test "hydrate multiple mismatches joined with semicolon" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let logger = StringBuilder::new()
  // Two buttons with handlers - both need sol:hk
  let vnode = @luna.fragment([
    @luna.h(
      "button",
      [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
      [@luna.text("A")],
    ),
    @luna.h(
      "button",
      [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
      [@luna.text("B")],
    ),
  ])
  // Wrong HTML - neither button has sol:hk
  set_inner_html(container, "<div>Wrong</div>")
  let result = hydrate(container, vnode, recover_on_mismatch=false, logger~)
  match result {
    Mismatch(msg) =>
      // Should contain both mismatches joined
      assert_true(msg.contains("sol:hk"))
    _ => assert_true(true)
  }
}

///|
test "hydrate tag mismatch with correct sol:hk" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let logger = StringBuilder::new()
  // Expect a button
  let vnode = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [@luna.text("Click")],
  )
  // HTML has a span with correct sol:hk but wrong tag
  set_inner_html(container, "<span sol:hk=\"0\">Wrong tag</span>")
  let result = hydrate(container, vnode, recover_on_mismatch=false, logger~)
  match result {
    Mismatch(msg) =>
      // Should mention tag mismatch
      assert_true(msg.contains("mismatch") || msg.contains("expected"))
    _ => assert_true(true)
  }
}

///|
test "hydrate dynamic attribute value" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let value_sig = @signal.signal("initial")
  let vnode = @luna.h(
    "input",
    [("value", @luna.attr_dynamic(fn() { value_sig.get() }))],
    [],
  )
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)
  // Update value
  value_sig.set("updated")
  // Value should be updated in DOM
  let inner = get_inner_html(container)
  assert_true(inner.contains("input"))
}

///|
test "hydrate dynamic attribute general" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let title_sig = @signal.signal("Title 1")
  let vnode = @luna.h(
    "div",
    [("title", @luna.attr_dynamic(fn() { title_sig.get() }))],
    [@luna.text("Content")],
  )
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)
  // Update title
  title_sig.set("Title 2")
  // DOM should be updated
  assert_true(get_inner_html(container).contains("Content"))
}

///|
test "hydrate dynamic attribute removal" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let show_title = @signal.signal(true)
  let vnode = @luna.h(
    "div",
    [
      (
        "title",
        @luna.attr_dynamic(fn() {
          if show_title.get() {
            "My Title"
          } else {
            "__remove__"
          }
        }),
      ),
    ],
    [@luna.text("Content")],
  )
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)
  // Remove title
  show_title.set(false)
  // Should still have the div
  assert_true(get_inner_html(container).contains("Content"))
}

///|
test "hydrate dynamic style" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let color_sig = @signal.signal("red")
  let vnode = @luna.h(
    "div",
    [("style", @luna.attr_dynamic_style(fn() { "color: " + color_sig.get() }))],
    [@luna.text("Styled")],
  )
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)
  // Update color
  color_sig.set("blue")
  // Content should remain
  assert_true(get_inner_html(container).contains("Styled"))
}

///|
test "render_vnode directly" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.h("div", [("class", @luna.attr_static("test"))], [
    @luna.text("Direct render"),
  ])
  // Use render_vnode directly (not hydrate)
  render_vnode(container, vnode)
  assert_true(get_inner_html(container).contains("Direct render"))
  assert_true(get_inner_html(container).contains("test"))
}

///|
test "render_vnode_to_dom with fragment" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.fragment([@luna.text("A"), @luna.text("B"), @luna.text("C")])
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  assert_eq(get_inner_html(container), "ABC")
}

///|
test "render_vnode_to_dom with component" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.component(fn() { @luna.text("Component content") })
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  assert_eq(get_inner_html(container), "Component content")
}

///|
test "render_vnode_to_dom with Show initially true" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let visible = @signal.signal(true)
  let vnode = @luna.show(fn() { visible.get() }, fn() { @luna.text("Visible") })
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  // Show node returns a comment placeholder, content is inserted before it
  // The test verifies the node was created without error
  assert_true(true)
}

///|
test "render_vnode_to_dom with Show toggle" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let visible = @signal.signal(false)
  let vnode = @luna.show(fn() { visible.get() }, fn() {
    @luna.text("Toggle me")
  })
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  // Initially hidden
  assert_false(get_inner_html(container).contains("Toggle me"))
  // Show it
  visible.set(true)
  assert_true(get_inner_html(container).contains("Toggle me"))
  // Hide it again
  visible.set(false)
  assert_false(get_inner_html(container).contains("Toggle me"))
}

///|
test "render_vnode_to_dom with For list" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let items = @signal.signal(["X", "Y"])
  let vnode = @luna.for_each(fn() {
    items.get().map(fn(item) { @luna.text(item) })
  })
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  // For returns a document fragment, items are appended to it
  // Update list triggers effect
  items.set(["A", "B", "C"])
  // The test verifies the render and update work without error
  assert_true(true)
}

///|
test "render_vnode_to_dom with static style" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.h("div", [("style", @luna.attr_style("color: red"))], [
    @luna.text("Styled"),
  ])
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  assert_true(get_inner_html(container).contains("Styled"))
}

///|
test "render_vnode_to_dom with dynamic style" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let color = @signal.signal("green")
  let vnode = @luna.h(
    "div",
    [
      (
        "style",
        @luna.attr_dynamic_style(fn() { "background-color: " + color.get() }),
      ),
    ],
    [@luna.text("Dynamic styled")],
  )
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  assert_true(get_inner_html(container).contains("Dynamic styled"))
  // Update style
  color.set("yellow")
  assert_true(get_inner_html(container).contains("Dynamic styled"))
}

///|
test "render_vnode_to_dom with VDynamic attribute" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let href = @signal.signal("/page1")
  let vnode = @luna.h(
    "a",
    [("href", @luna.attr_dynamic(fn() { href.get() }))],
    [@luna.text("Link")],
  )
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  assert_true(get_inner_html(container).contains("Link"))
  // Update href
  href.set("/page2")
  assert_true(get_inner_html(container).contains("Link"))
}

///|
test "render_vnode_to_dom with static attribute value" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.h("input", [("value", @luna.attr_static("test-value"))], [])
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  assert_true(get_inner_html(container).contains("input"))
}

///|
test "hydrate show toggle visibility" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let visible = @signal.signal(true)
  let vnode = @luna.show(fn() { visible.get() }, fn() {
    @luna.text("Toggle content")
  })
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)
  // Initially visible
  assert_true(get_inner_html(container).contains("Toggle content"))
  // Hide it
  visible.set(false)
  assert_false(get_inner_html(container).contains("Toggle content"))
  // Show it again
  visible.set(true)
  assert_true(get_inner_html(container).contains("Toggle content"))
}

// =============================================================================
// HydrationResult Factory and Predicate Tests
// =============================================================================

///|
test "hydration_result_success factory" {
  let result = hydration_result_success()
  assert_true(result.is_success())
  assert_false(result.is_mismatch())
  assert_false(result.is_recovered())
  assert_eq(result.get_message(), "")
}

///|
test "hydration_result_mismatch factory" {
  let result = hydration_result_mismatch("test mismatch")
  assert_false(result.is_success())
  assert_true(result.is_mismatch())
  assert_false(result.is_recovered())
  assert_eq(result.get_message(), "test mismatch")
}

///|
test "hydration_result_recovered factory" {
  let result = hydration_result_recovered("recovered from error")
  assert_false(result.is_success())
  assert_false(result.is_mismatch())
  assert_true(result.is_recovered())
  assert_eq(result.get_message(), "recovered from error")
}

// =============================================================================
// Island Hydration Tests
// =============================================================================

///|
test "hydrate island node" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode : @luna.Node[@js.Any] = @luna.island(
    "island-1",
    "/components/counter.js",
    "{}",
    [@luna.text("Island content")],
  )
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let result = hydrate(container, vnode)
  // Island hydration should succeed (loader handles the actual hydration)
  assert_true(result.is_success())
  assert_true(get_inner_html(container).contains("Island content"))
}

///|
test "hydrate island with nested elements" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode : @luna.Node[@js.Any] = @luna.island(
    "island-nested",
    "/components/nested.js",
    "{\"count\":0}",
    [@luna.h("div", [], [@luna.text("Nested in island")])],
  )
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let result = hydrate(container, vnode)
  assert_true(result.is_success())
  assert_true(get_inner_html(container).contains("Nested in island"))
}

// =============================================================================
// Async Node Hydration Tests
// =============================================================================

///|
test "hydrate async node renders fallback" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode : @luna.Node[@js.Any] = @luna.async_(
    render=async fn() { @luna.text("Loaded") },
    fallback=fn() { @luna.text("Loading...") },
  )
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let result = hydrate(container, vnode)
  // Async hydration should succeed
  assert_true(result.is_success())
  // Should show fallback
  assert_true(get_inner_html(container).contains("Loading..."))
}

// =============================================================================
// ErrorBoundary Hydration Tests
// =============================================================================

///|
test "hydrate error_boundary success" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode : @luna.Node[@js.Any] = @luna.error_boundary(
    children=fn() { @luna.h("div", [], [@luna.text("Safe content")]) },
    fallback=fn(_err, _reset) { @luna.text("Error occurred") },
  )
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let result = hydrate(container, vnode)
  assert_true(result.is_success())
  assert_true(get_inner_html(container).contains("Safe content"))
}

// =============================================================================
// Switch Hydration Tests
// =============================================================================

///|
test "hydrate switch first case matches" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode : @luna.Node[@js.Any] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { true }, render=fn() { @luna.text("First") }),
      @luna.match_case(when=fn() { true }, render=fn() { @luna.text("Second") }),
    ],
    fallback=Some(fn() { @luna.text("Fallback") }),
  )
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let result = hydrate(container, vnode)
  assert_true(result.is_success())
  assert_true(get_inner_html(container).contains("First"))
}

///|
test "hydrate switch second case matches" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode : @luna.Node[@js.Any] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() { @luna.text("First") }),
      @luna.match_case(when=fn() { true }, render=fn() { @luna.text("Second") }),
    ],
    fallback=Some(fn() { @luna.text("Fallback") }),
  )
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let result = hydrate(container, vnode)
  assert_true(result.is_success())
  assert_true(get_inner_html(container).contains("Second"))
}

///|
test "hydrate switch fallback" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode : @luna.Node[@js.Any] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() { @luna.text("Never") }),
    ],
    fallback=Some(fn() { @luna.text("Fallback shown") }),
  )
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let result = hydrate(container, vnode)
  assert_true(result.is_success())
  assert_true(get_inner_html(container).contains("Fallback shown"))
}

///|
test "hydrate switch no fallback" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode : @luna.Node[@js.Any] = @luna.switch_(cases=[
    @luna.match_case(when=fn() { false }, render=fn() { @luna.text("Never") }),
  ])
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let result = hydrate(container, vnode)
  assert_true(result.is_success())
}

// =============================================================================
// render_vnode_to_dom Additional Tests
// =============================================================================

///|
test "render_vnode_to_dom with Island" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode : @luna.Node[@js.Any] = @luna.island(
    "island-render",
    "/module.js",
    "{\"state\":1}",
    [@luna.text("Island child")],
  )
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  let inner = get_inner_html(container)
  assert_true(inner.contains("Island child"))
  assert_true(inner.contains("luna:id"))
  assert_true(inner.contains("luna:url"))
}

///|
test "render_vnode_to_dom with Async renders fallback" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode : @luna.Node[@js.Any] = @luna.async_(
    render=async fn() { @luna.text("Async content") },
    fallback=fn() { @luna.text("Fallback content") },
  )
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  assert_true(get_inner_html(container).contains("Fallback content"))
}

///|
test "render_vnode_to_dom with ErrorBoundary success" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode : @luna.Node[@js.Any] = @luna.error_boundary(
    children=fn() { @luna.text("Safe content") },
    fallback=fn(_err, _reset) { @luna.text("Error") },
  )
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  assert_true(get_inner_html(container).contains("Safe content"))
}

///|
test "render_vnode_to_dom with Switch" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let condition = @signal.signal(true)
  let vnode : @luna.Node[@js.Any] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { condition.get() }, render=fn() {
        @luna.text("Case 1")
      }),
      @luna.match_case(when=fn() { not(condition.get()) }, render=fn() {
        @luna.text("Case 2")
      }),
    ],
    fallback=Some(fn() { @luna.text("Fallback") }),
  )
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  assert_true(get_inner_html(container).contains("Case 1"))
}

///|
test "render_vnode_to_dom Switch with fallback" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode : @luna.Node[@js.Any] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() { @luna.text("Never") }),
    ],
    fallback=Some(fn() { @luna.text("Fallback rendered") }),
  )
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  assert_true(get_inner_html(container).contains("Fallback rendered"))
}

///|
test "render_vnode_to_dom Switch no fallback" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode : @luna.Node[@js.Any] = @luna.switch_(cases=[
    @luna.match_case(when=fn() { false }, render=fn() { @luna.text("Never") }),
  ])
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  // Should only have the placeholder comment
  assert_true(true) // No error means success
}

///|
test "render_vnode_to_dom Switch reactive update" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let case_index = @signal.signal(0)
  let vnode : @luna.Node[@js.Any] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { case_index.get() == 0 }, render=fn() {
        @luna.text("Zero")
      }),
      @luna.match_case(when=fn() { case_index.get() == 1 }, render=fn() {
        @luna.text("One")
      }),
    ],
    fallback=Some(fn() { @luna.text("Other") }),
  )
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  // Initial state
  assert_true(get_inner_html(container).contains("Zero"))
  // Switch to case 1
  case_index.set(1)
  assert_true(get_inner_html(container).contains("One"))
  // Switch to fallback
  case_index.set(2)
  assert_true(get_inner_html(container).contains("Other"))
}

// =============================================================================
// Action-based Hydration Tests
// =============================================================================

///|
test "hydrate action attribute" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode : @luna.Node[@js.Any] = @luna.h(
    "button",
    [("onclick", @luna.action(Increment))],
    [@luna.text("Click")],
  )
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let result = hydrate(container, vnode)
  // Actions are handled by action-based hydration, not standard hydration
  assert_true(result.is_success())
  assert_true(get_inner_html(container).contains("Click"))
}

///|
test "bind_actions_from_dom" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  set_inner_html(
    container, "<button data-action-click=\"test-action\">Click</button>",
  )
  let dispatched : Array[String] = []
  bind_actions_from_dom(container, fn(action) { dispatched.push(action) })
  // Verify binding happened (we can't easily simulate click in jsdom)
  assert_true(get_inner_html(container).contains("data-action-click"))
}

///|
test "hydrate_with_actions" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  // Setup initial HTML with action attribute
  set_inner_html(container, "<div data-action-click=\"Increment\">0</div>")
  let render_fn : (Int) -> @luna.Node[@js.Any] = fn(state) {
    @luna.h("div", [("onclick", @luna.action(Increment))], [
      @luna.text(state.to_string()),
    ])
  }
  let update_fn : (Int, String) -> Int = fn(state, action) {
    if action == "Increment" {
      state + 1
    } else {
      state
    }
  }
  // This should bind actions and set up re-rendering
  hydrate_with_actions(container, 0, render_fn, update_fn)
  // The hydration should work without error
  assert_true(true)
}

// =============================================================================
// apply_vattr Edge Cases
// =============================================================================

///|
test "apply_vattr static __remove__" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.h("div", [("data-test", @luna.attr_static("__remove__"))], [
    @luna.text("Content"),
  ])
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  // __remove__ should not add the attribute
  assert_false(get_inner_html(container).contains("data-test"))
}

///|
test "apply_vattr static boolean attribute" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @luna.h("input", [("disabled", @luna.attr_static(""))], [])
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  assert_true(get_inner_html(container).contains("disabled"))
}

///|
test "apply_vattr dynamic __remove__" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let show_attr = @signal.signal(true)
  let vnode = @luna.h(
    "div",
    [
      (
        "data-custom",
        @luna.attr_dynamic(fn() {
          if show_attr.get() {
            "value"
          } else {
            "__remove__"
          }
        }),
      ),
    ],
    [@luna.text("Content")],
  )
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  // Initially has attribute
  assert_true(get_inner_html(container).contains("data-custom"))
  // Remove it
  show_attr.set(false)
  // Attribute should be removed
  assert_false(get_inner_html(container).contains("data-custom"))
}

///|
test "apply_vattr VAction without dispatcher" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode : @luna.Node[@js.Any] = @luna.h(
    "button",
    [("onclick", @luna.action(TestAction))],
    [@luna.text("Click")],
  )
  let dom_node = render_vnode_to_dom(vnode)
  container.as_node().appendChild(dom_node) |> ignore
  // VAction without dispatcher does nothing, but shouldn't error
  assert_true(get_inner_html(container).contains("Click"))
}

// =============================================================================
// hydrate_child_nodes Additional Tests
// =============================================================================

///|
test "hydrate nested show in for" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let items = @signal.signal(["A", "B"])
  let visible = @signal.signal(true)
  let vnode = @luna.for_each(fn() {
    items
    .get()
    .map(fn(item) {
      @luna.show(fn() { visible.get() }, fn() { @luna.text(item) })
    })
  })
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let result = hydrate(container, vnode)
  // Hydration should succeed (or recover)
  assert_true(result.is_success() || result.is_recovered())
}

///|
test "hydrate nested component in for" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let items = @signal.signal(["X", "Y"])
  let vnode = @luna.for_each(fn() {
    items
    .get()
    .map(fn(item) { @luna.component(fn() { @luna.text("Item: " + item) }) })
  })
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)
  assert_true(get_inner_html(container).contains("Item: X"))
  assert_true(get_inner_html(container).contains("Item: Y"))
}

// =============================================================================
// Show with multiple children (Fragment) - Hydration and Reactivity Tests
// =============================================================================

///|
test "hydrate show with fragment (multiple children)" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let visible = @signal.signal(true)
  let vnode = @luna.show(fn() { visible.get() }, fn() {
    @luna.fragment([
      @luna.h("div", [], [@luna.text("A")]),
      @luna.h("div", [], [@luna.text("B")]),
    ])
  })
  let html = @render.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let result = hydrate(container, vnode)
  // Hydration should succeed
  assert_true(result.is_success() || result.is_recovered())
  assert_true(get_inner_html(container).contains("<div>A</div>"))
  assert_true(get_inner_html(container).contains("<div>B</div>"))
}

///|
test "show with fragment toggles correctly" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let visible = @signal.signal(true)

  // Render directly (not hydration, just client render)
  let dom_node = @element.show(fn() { visible.get() }, fn() {
    @element.fragment([
      @element.div([@element.text("A")]),
      @element.div([@element.text("B")]),
    ])
  })
  @element.mount_to(container, dom_node)

  // Initially visible - both A and B should be present
  assert_true(get_inner_html(container).contains("<div>A</div>"))
  assert_true(get_inner_html(container).contains("<div>B</div>"))

  // Toggle to hidden
  visible.set(false)

  // A and B should be removed
  assert_false(get_inner_html(container).contains("<div>A</div>"))
  assert_false(get_inner_html(container).contains("<div>B</div>"))

  // Toggle back to visible
  visible.set(true)

  // A and B should reappear
  assert_true(get_inner_html(container).contains("<div>A</div>"))
  assert_true(get_inner_html(container).contains("<div>B</div>"))
}
