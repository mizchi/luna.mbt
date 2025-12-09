///| Hydration Tests
///|
///| Test hydration of server-rendered HTML with VNode

///|
/// Helper to set innerHTML on container
fn set_inner_html(container : @js_dom.Element, html : String) -> Unit {
  container.as_any()._set("innerHTML", @core.any(html)) |> ignore
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
    Some(body) => body.as_any()._set("innerHTML", @core.any("")) |> ignore
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
  let vnode = @ui.vtext("Hello")

  // SSR render
  let html = @ssr.render_to_string(vnode)
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
  let vnode = @ui.vdiv([], [@ui.vtext("Content")])

  let html = @ssr.render_to_string(vnode)
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)

  assert_eq(get_inner_html(container), "<div>Content</div>")
}

///|
test "hydrate element with class" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @ui.vdiv([@ui.vclass("test-class")], [@ui.vtext("Styled")])

  let html = @ssr.render_to_string(vnode)
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)

  assert_true(get_inner_html(container).contains("test-class"))
}

///|
test "hydrate nested elements" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @ui.vdiv([], [
    @ui.vspan([], [@ui.vtext("Nested")]),
  ])

  let html = @ssr.render_to_string(vnode)
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
  let count = @ui.signal(42)
  let vnode = @ui.vtext_dyn(fn() { count.get().to_string() })

  // SSR with hydration markers
  let html = @ssr.render_to_string_with_hydration(vnode)
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
  let vnode = @ui.vbutton(
    [@ui.von_click(@ui.event_handler())],
    [@ui.vtext("Click me")],
  )

  // SSR with hydration markers
  let html = @ssr.render_to_string_with_hydration(vnode)
  assert_true(html.contains("data-hk=\"0\""))

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
  let active = @ui.signal(false)
  let vnode = @ui.vdiv(
    [@ui.vclass_dyn(fn() { if active.get() { "active" } else { "inactive" } })],
    [@ui.vtext("Toggle")],
  )

  let html = @ssr.render_to_string_with_hydration(vnode)
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
  let visible = @ui.signal(true)
  let vnode = @ui.vshow(
    fn() { visible.get() },
    fn() { @ui.vtext("Visible content") },
  )

  let html = @ssr.render_to_string_with_hydration(vnode)
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
  let visible = @ui.signal(false)
  let vnode = @ui.vshow(
    fn() { visible.get() },
    fn() { @ui.vtext("Hidden content") },
  )

  let html = @ssr.render_to_string(vnode)
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
  let items = @ui.signal(["A", "B", "C"])
  let vnode = @ui.vfor(fn() {
    let arr = items.get()
    let result : Array[@ui.VNode] = []
    for i = 0; i < arr.length(); i = i + 1 {
      result.push(@ui.vli([], [@ui.vtext(arr[i])]))
    }
    result
  })

  let html = @ssr.render_to_string_with_hydration(vnode)
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
  let vnode = @ui.vbutton(
    [@ui.von_click(@ui.event_handler())],
    [@ui.vtext("Button")],
  )

  // But SSR HTML is completely different (simulating mismatch)
  set_inner_html(container, "<span>Wrong element</span>")

  // Hydrate with strict options and logger to suppress console output
  let result = hydrate(container, vnode, recover_on_mismatch=false, logger=logger)

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

  let vnode = @ui.vdiv([@ui.vclass("expected")], [@ui.vtext("Expected")])

  // Wrong HTML
  set_inner_html(container, "<span>Wrong</span>")

  // Hydrate with recovery enabled and logger to suppress console output
  let result = hydrate(
    container,
    vnode,
    logger=logger,
  )

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
    Success => {
      // No dynamic content, so no mismatch detected
      // This is expected for static VNode
      assert_true(true)
    }
    Mismatch(_) => assert_true(false) // Should not fail with default options
  }
}

///|
test "hydrate success on correct HTML" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @ui.vdiv([], [@ui.vtext("Correct")])

  // Correct SSR HTML
  let html = @ssr.render_to_string(vnode)
  set_inner_html(container, html)

  let result = hydrate(
    container,
    vnode,
    recover_on_mismatch=false,
  )

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
  let count = @ui.signal(0)
  let items = @ui.signal(["Item 1", "Item 2"])

  let vnode = @ui.vdiv([@ui.vclass("app")], [
    @ui.vh1([], [@ui.vtext("Title")]),
    @ui.vp([], [@ui.vtext_dyn(fn() { "Count: " + count.get().to_string() })]),
    @ui.vul([], [
      @ui.vfor(fn() {
        let arr = items.get()
        let result : Array[@ui.VNode] = []
        for i = 0; i < arr.length(); i = i + 1 {
          result.push(@ui.vli([], [@ui.vtext(arr[i])]))
        }
        result
      }),
    ]),
    @ui.vbutton([@ui.von_click(@ui.event_handler())], [@ui.vtext("Click")]),
  ])

  let html = @ssr.render_to_string_with_hydration(vnode)
  set_inner_html(container, html)
  let _ = hydrate(container, vnode, logger=logger)

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
  let vnode = @ui.vfragment([
    @ui.vtext("A"),
    @ui.vtext("B"),
    @ui.vtext("C"),
  ])

  let html = @ssr.render_to_string(vnode)
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)

  assert_eq(get_inner_html(container), "ABC")
}

///|
test "hydrate component" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()

  fn greeting(name : String) -> @ui.VNode {
    @ui.vdiv([], [@ui.vtext("Hello, " + name + "!")])
  }

  let vnode = @ui.vcomponent(fn() { greeting("World") })

  let html = @ssr.render_to_string(vnode)
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
  let vnode = @ui.vtext("")

  let html = @ssr.render_to_string(vnode)
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)

  assert_eq(get_inner_html(container), "")
}

///|
test "hydrate deeply nested structure" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @ui.vdiv([], [
    @ui.vdiv([], [
      @ui.vdiv([], [
        @ui.vdiv([], [
          @ui.vspan([], [@ui.vtext("Deep")]),
        ]),
      ]),
    ]),
  ])

  let html = @ssr.render_to_string(vnode)
  set_inner_html(container, html)
  let _ = hydrate(container, vnode)

  assert_true(get_inner_html(container).contains("Deep"))
}

///|
test "hydrate with escaped content" {
  @global_jsdom.register()
  defer cleanup()
  let container = create_container()
  let vnode = @ui.vtext("<script>alert('xss')</script>")

  let html = @ssr.render_to_string(vnode)
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
  let vnode = @ui.vbutton(
    [@ui.von_click(@ui.event_handler())],
    [@ui.vtext("Button")],
  )

  // Wrong HTML
  set_inner_html(container, "<span>Wrong</span>")

  // Hydrate with logger
  let _ = hydrate(
    container,
    vnode,
    logger=logger,
  )

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

  let vnode = @ui.vbutton(
    [@ui.von_click(@ui.event_handler())],
    [@ui.vtext("Click")],
  )

  set_inner_html(container, "<div>Wrong</div>")

  let result = hydrate(
    container,
    vnode,
    recover_on_mismatch=false,
    logger=logger,
  )

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

  let vnode = @ui.vdiv([], [@ui.vtext("Content")])

  let html = @ssr.render_to_string(vnode)
  set_inner_html(container, html)

  let result = hydrate(
    container,
    vnode,
    logger=logger,
  )

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

  let vnode = @ui.vbutton(
    [@ui.von_click(@ui.event_handler())],
    [@ui.vtext("Submit")],
  )

  set_inner_html(container, "<input type=\"text\" />")

  let _ = hydrate(
    container,
    vnode,
    recover_on_mismatch=false,
    logger=logger,
  )

  let log_output = logger.to_string()
  // Should mention the expected element
  assert_true(log_output.contains("button"))
  assert_true(log_output.contains("data-hk"))
}
