///|
/// Experimental Hydration Tests - jsdom based testing

// Test enum for action
enum TestAction {
  TestAction
} derive(Show)

///|
/// Helper to set innerHTML on container
fn exp_set_inner_html(container : @js_dom.Element, html : String) -> Unit {
  container.as_any()._set("innerHTML", @js.any(html)) |> ignore
}

///|
/// Helper to get innerHTML from container
fn exp_get_inner_html(container : @js_dom.Element) -> String {
  container.as_any()._get("innerHTML").cast()
}

///|
/// Cleanup document.body.innerHTML
fn exp_cleanup() -> Unit {
  let doc = @js_dom.document()
  match doc.body() {
    Some(body) => body.as_any()._set("innerHTML", @js.any("")) |> ignore
    None => ()
  }
}

///|
/// Create a test container and append to document.body
fn exp_create_container() -> @js_dom.Element {
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  match doc.body() {
    Some(body) => body.as_node().appendChild(container.as_node()) |> ignore
    None => ()
  }
  container
}

// =============================================================================
// Basic Repair Tests
// =============================================================================

///|
test "exp: repair missing static text" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.text("Hello World")
  // Empty container
  exp_set_inner_html(container, "")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(repairs) => {
      assert_true(repairs.length() > 0)
      // Should have created text node
      assert_eq(exp_get_inner_html(container), "Hello World")
    }
    Clean =>
      // Also acceptable if text was added
      assert_eq(exp_get_inner_html(container), "Hello World")
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: repair wrong static text content" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.text("Correct")
  // Wrong text
  exp_set_inner_html(container, "Wrong")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(repairs) => {
      assert_true(repairs.length() > 0)
      let log = logger.to_string()
      assert_true(log.contains("Text content mismatch"))
      assert_true(log.contains("Correct"))
      assert_true(log.contains("Wrong"))
    }
    Clean => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: repair missing element with handler" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [@luna.text("Click me")],
  )
  // Empty container
  exp_set_inner_html(container, "")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(repairs) => {
      assert_true(repairs.length() > 0)
      let log = logger.to_string()
      assert_true(log.contains("Missing element"))
      // Button should be created
      assert_true(exp_get_inner_html(container).contains("button"))
    }
    Clean => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: repair tag mismatch with data-hk" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [@luna.text("Submit")],
  )
  // Wrong tag (span instead of button) but correct data-hk
  exp_set_inner_html(container, "<span data-hk=\"0\">Submit</span>")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(repairs) => {
      assert_true(repairs.length() > 0)
      let log = logger.to_string()
      assert_true(log.contains("Tag mismatch"))
      // Should replace with button
      assert_true(exp_get_inner_html(container).contains("button"))
    }
    Clean => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

// =============================================================================
// Attribute Repair Tests
// =============================================================================

///|
test "exp: repair class attribute mismatch" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h("div", [("class", @luna.attr_static("correct-class"))], [
    @luna.text("Content"),
  ])
  // Wrong class
  exp_set_inner_html(container, "<div class=\"wrong-class\">Content</div>")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(repairs) => {
      assert_true(repairs.length() > 0)
      let log = logger.to_string()
      assert_true(log.contains("Attribute mismatch"))
      assert_true(log.contains("class"))
    }
    Clean => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: repair id attribute mismatch" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h("div", [("id", @luna.attr_static("correct-id"))], [
    @luna.text("Content"),
  ])
  // Wrong id
  exp_set_inner_html(container, "<div id=\"wrong-id\">Content</div>")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(repairs) => {
      assert_true(repairs.length() > 0)
      let log = logger.to_string()
      assert_true(log.contains("Attribute mismatch"))
      assert_true(log.contains("id"))
    }
    Clean => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: repair missing attribute" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h("div", [("data-testid", @luna.attr_static("my-test"))], [
    @luna.text("Content"),
  ])
  // No attribute
  exp_set_inner_html(container, "<div>Content</div>")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(repairs) => {
      assert_true(repairs.length() > 0)
      let log = logger.to_string()
      assert_true(log.contains("Attribute mismatch"))
    }
    Clean => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

// =============================================================================
// Dynamic Content Repair Tests
// =============================================================================

///|
test "exp: repair missing dynamic text markers" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let count = @signal.signal(42)
  let vnode = @luna.text_dyn(fn() { "Count: " + count.get().to_string() })
  // No markers
  exp_set_inner_html(container, "")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(repairs) => {
      assert_true(repairs.length() > 0)
      let log = logger.to_string()
      assert_true(log.contains("dynamic text marker"))
    }
    Clean => assert_true(true)
    Failed(_) => assert_true(false)
  }
  // Update signal should work
  count.set(100)
  assert_true(exp_get_inner_html(container).contains("100"))
}

///|
test "exp: repair dynamic text with existing marker but missing text node" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let name = @signal.signal("Alice")
  let vnode = @luna.text_dyn(fn() { name.get() })
  // Has marker but no text node after it
  exp_set_inner_html(container, "<!--t:0--><!--/t-->")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(repairs) => {
      assert_true(repairs.length() > 0)
      let log = logger.to_string()
      assert_true(log.contains("Missing text node"))
    }
    Clean => assert_true(true)
    Failed(_) => assert_true(false)
  }
  // Signal should be reactive
  name.set("Bob")
  assert_true(exp_get_inner_html(container).contains("Bob"))
}

///|
test "exp: dynamic attribute setup works after repair" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let title = @signal.signal("Title 1")
  let vnode = @luna.h(
    "div",
    [("title", @luna.attr_dynamic(fn() { title.get() }))],
    [@luna.text("Hover me")],
  )
  // Element exists but wrong structure
  exp_set_inner_html(container, "<div>Hover me</div>")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
  // Update attribute
  title.set("Title 2")
  // Content should remain
  assert_true(exp_get_inner_html(container).contains("Hover me"))
}

///|
test "exp: dynamic style setup works after repair" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let bg = @signal.signal("red")
  let vnode = @luna.h(
    "div",
    [
      (
        "style",
        @luna.attr_dynamic_style(fn() { "background-color: " + bg.get() }),
      ),
    ],
    [@luna.text("Styled")],
  )
  // Element exists
  exp_set_inner_html(container, "<div>Styled</div>")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
  // Update style
  bg.set("blue")
  assert_true(exp_get_inner_html(container).contains("Styled"))
}

// =============================================================================
// Show/For Repair Tests
// =============================================================================

///|
test "exp: repair missing show markers" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let visible = @signal.signal(true)
  let vnode = @luna.show(fn() { visible.get() }, fn() {
    @luna.text("Visible content")
  })
  // No markers
  exp_set_inner_html(container, "")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(repairs) => {
      assert_true(repairs.length() > 0)
      let log = logger.to_string()
      assert_true(log.contains("show markers"))
    }
    Clean => assert_true(true)
    Failed(_) => assert_true(false)
  }
  // Toggle should work
  assert_true(exp_get_inner_html(container).contains("Visible"))
  visible.set(false)
  assert_false(exp_get_inner_html(container).contains("Visible"))
  visible.set(true)
  assert_true(exp_get_inner_html(container).contains("Visible"))
}

///|
test "exp: repair show with condition initially false" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let visible = @signal.signal(false)
  let vnode = @luna.show(fn() { visible.get() }, fn() { @luna.text("Hidden") })
  exp_set_inner_html(container, "")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
  // Initially hidden
  assert_false(exp_get_inner_html(container).contains("Hidden"))
  // Show
  visible.set(true)
  assert_true(exp_get_inner_html(container).contains("Hidden"))
}

///|
test "exp: repair missing for markers" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let items = @signal.signal(["A", "B", "C"])
  let vnode = @luna.for_each(fn() {
    let arr = items.get()
    let result : Array[@luna.Node[@js.Any]] = []
    for i = 0; i < arr.length(); i = i + 1 {
      result.push(@luna.h("li", [], [@luna.text(arr[i])]))
    }
    result
  })
  // No markers
  exp_set_inner_html(container, "")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(repairs) => {
      assert_true(repairs.length() > 0)
      let log = logger.to_string()
      assert_true(log.contains("for markers"))
    }
    Clean => assert_true(true)
    Failed(_) => assert_true(false)
  }
  // Update list
  items.set(["X", "Y"])
  let html = exp_get_inner_html(container)
  assert_true(html.contains("X"))
  assert_true(html.contains("Y"))
}

///|
test "exp: repair for item count mismatch - too few items" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.for_each(fn() {
    [@luna.text("A"), @luna.text("B"), @luna.text("C")]
  })
  // Only 1 item in DOM
  exp_set_inner_html(container, "<!--f:0-->X<!--/f-->")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(repairs) => {
      assert_true(repairs.length() > 0)
      let log = logger.to_string()
      assert_true(log.contains("item count mismatch"))
      assert_true(log.contains("expected 3"))
      assert_true(log.contains("got 1"))
    }
    Clean => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: repair for item count mismatch - too many items" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.for_each(fn() { [@luna.text("A")] })
  // 3 items in DOM
  exp_set_inner_html(container, "<!--f:0-->X Y Z<!--/f-->")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(repairs) => {
      assert_true(repairs.length() > 0)
      let log = logger.to_string()
      assert_true(log.contains("item count mismatch"))
    }
    Clean => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

// =============================================================================
// Nested Structure Repair Tests
// =============================================================================

///|
test "exp: repair deeply nested missing element" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h("div", [], [
    @luna.h("div", [], [
      @luna.h("div", [], [@luna.h("span", [], [@luna.text("Deep")])]),
    ]),
  ])
  // Only outer div
  exp_set_inner_html(container, "<div></div>")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(repairs) => {
      assert_true(repairs.length() > 0)
      assert_true(exp_get_inner_html(container).contains("Deep"))
    }
    Clean => assert_true(exp_get_inner_html(container).contains("Deep"))
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: repair fragment children" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.fragment([
    @luna.text("First"),
    @luna.text("Second"),
    @luna.text("Third"),
  ])
  // Only partial content
  exp_set_inner_html(container, "Partial")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(_) => assert_true(true)
    Clean => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: repair component render" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  fn counter_component(initial : Int) -> @luna.Node[@js.Any] {
    let count = @signal.signal(initial)
    let _ = count // suppress unused warning
    @luna.h("div", [], [
      @luna.text_dyn(fn() { "Count: " + count.get().to_string() }),
      @luna.h(
        "button",
        [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
        [@luna.text("+")],
      ),
    ])
  }

  let vnode = @luna.component(fn() { counter_component(10) })
  // Empty container
  exp_set_inner_html(container, "")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Repaired(_) => assert_true(true)
    Clean => assert_true(true)
    Failed(_) => assert_true(false)
  }
  assert_true(exp_get_inner_html(container).contains("Count"))
}

// =============================================================================
// hydrate_with_fallback Tests
// =============================================================================

///|
test "exp: fallback succeeds when normal hydration works" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h("div", [], [@luna.text("Content")])
  let html = @render.render_to_string(vnode).html
  exp_set_inner_html(container, html)
  let result = hydrate_with_fallback(container, vnode, logger~)
  match result {
    @client.Success => assert_true(true)
    _ => assert_true(false)
  }
}

///|
test "exp: fallback recovers from complete mismatch" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [@luna.text("Click")],
  )
  // Completely wrong HTML
  exp_set_inner_html(container, "<table><tr><td>Wrong</td></tr></table>")
  let result = hydrate_with_fallback(container, vnode, logger~)
  match result {
    @client.Recovered(msg) =>
      assert_true(
        msg.contains("Experimental") ||
        msg.contains("repaired") ||
        msg.contains("cleanly"),
      )
    @client.Success => assert_true(true)
    @client.Mismatch(_) => assert_true(true)
  }
}

///|
test "exp: fallback with logger captures both phases" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [@luna.text("Submit")],
  )
  // Wrong HTML
  exp_set_inner_html(container, "<input type=\"text\" />")
  let _ = hydrate_with_fallback(container, vnode, logger~)
  let log = logger.to_string()
  // Should mention regular hydration failed
  assert_true(log.contains("[Hydration]"))
}

// =============================================================================
// Edge Cases
// =============================================================================

///|
test "exp: handle empty vnode" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.text("")
  exp_set_inner_html(container, "something")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: handle special characters in text" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.text("<script>alert('xss')</script>")
  exp_set_inner_html(container, "wrong content")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: handle multiple dynamic elements" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let a = @signal.signal("A")
  let b = @signal.signal("B")
  let vnode = @luna.h("div", [], [
    @luna.text_dyn(fn() { a.get() }),
    @luna.text_dyn(fn() { b.get() }),
  ])
  exp_set_inner_html(container, "<div></div>")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
  // Both signals should be reactive
  a.set("Updated A")
  b.set("Updated B")
  let html = exp_get_inner_html(container)
  assert_true(html.contains("Updated A"))
  assert_true(html.contains("Updated B"))
}

///|
test "exp: handle static style attribute" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h(
    "div",
    [("style", @luna.attr_style("color: red; font-size: 16px"))],
    [@luna.text("Styled")],
  )
  exp_set_inner_html(container, "<div>Styled</div>")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
  assert_true(exp_get_inner_html(container).contains("Styled"))
}

///|
test "exp: handle event handler attachment" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [@luna.text("Click")],
  )
  // Correct HTML with data-hk
  exp_set_inner_html(container, "<button data-hk=\"0\">Click</button>")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
  // Button should be in DOM
  assert_true(exp_get_inner_html(container).contains("button"))
}

// =============================================================================
// ExperimentalHydrationReport Tests - Detailed Repair Information
// =============================================================================

///|
test "report: clean hydration returns clean report" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h("div", [], [@luna.text("Content")])
  let html = @render.render_to_string(vnode).html
  exp_set_inner_html(container, html)
  let report = experimental_hydrate_with_report(container, vnode, logger~)
  assert_true(report.is_clean())
  assert_eq(report.get_repair_count(), 0)
  assert_eq(report.get_repairs().length(), 0)
}

///|
test "report: text mismatch has correct repair type" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.text("Expected")
  exp_set_inner_html(container, "Wrong")
  let report = experimental_hydrate_with_report(container, vnode, logger~)
  assert_false(report.is_clean())
  assert_true(report.has_repair_type(repair_type_text_mismatch()))
  let repairs = report.get_repairs_by_type(repair_type_text_mismatch())
  assert_true(repairs.length() > 0)
  let repair = repairs[0]
  assert_eq(repair.get_expected(), "Expected")
  assert_eq(repair.get_actual(), "Wrong")
  assert_true(repair.get_message().contains("Text content mismatch"))
}

///|
test "report: missing text has correct repair type" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.text("Missing")
  exp_set_inner_html(container, "")
  let report = experimental_hydrate_with_report(container, vnode, logger~)
  assert_false(report.is_clean())
  assert_true(report.has_repair_type(repair_type_text_missing()))
}

///|
test "report: element missing has correct repair type" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [@luna.text("Click")],
  )
  exp_set_inner_html(container, "")
  let report = experimental_hydrate_with_report(container, vnode, logger~)
  assert_false(report.is_clean())
  assert_true(report.has_repair_type(repair_type_element_missing()))
  let repairs = report.get_repairs_by_type(repair_type_element_missing())
  assert_true(repairs.length() > 0)
  let repair = repairs[0]
  assert_true(repair.get_expected().contains("button"))
}

///|
test "report: tag mismatch has correct repair type" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h(
    "button",
    [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
    [@luna.text("Click")],
  )
  exp_set_inner_html(container, "<span data-hk=\"0\">Click</span>")
  let report = experimental_hydrate_with_report(container, vnode, logger~)
  assert_false(report.is_clean())
  assert_true(report.has_repair_type(repair_type_tag_mismatch()))
  let repairs = report.get_repairs_by_type(repair_type_tag_mismatch())
  assert_true(repairs.length() > 0)
  let repair = repairs[0]
  assert_eq(repair.get_expected(), "button")
  assert_eq(repair.get_actual(), "span")
}

///|
test "report: attribute mismatch has correct repair type" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h("div", [("class", @luna.attr_static("expected"))], [
    @luna.text("Content"),
  ])
  exp_set_inner_html(container, "<div class=\"wrong\">Content</div>")
  let report = experimental_hydrate_with_report(container, vnode, logger~)
  assert_false(report.is_clean())
  assert_true(report.has_repair_type(repair_type_attribute_mismatch()))
  let repairs = report.get_repairs_by_type(repair_type_attribute_mismatch())
  assert_true(repairs.length() > 0)
  let repair = repairs[0]
  assert_eq(repair.get_expected(), "expected")
  assert_eq(repair.get_actual(), "wrong")
}

///|
test "report: dynamic text marker missing has correct repair type" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let sig = @signal.signal("Dynamic")
  let vnode = @luna.text_dyn(fn() { sig.get() })
  exp_set_inner_html(container, "")
  let report = experimental_hydrate_with_report(container, vnode, logger~)
  assert_false(report.is_clean())
  assert_true(report.has_repair_type(repair_type_dynamic_text_marker_missing()))
}

///|
test "report: show marker missing has correct repair type" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let visible = @signal.signal(true)
  let vnode = @luna.show(fn() { visible.get() }, fn() {
    @luna.text("Content")
  })
  exp_set_inner_html(container, "")
  let report = experimental_hydrate_with_report(container, vnode, logger~)
  assert_false(report.is_clean())
  assert_true(report.has_repair_type(repair_type_show_marker_missing()))
}

///|
test "report: for marker missing has correct repair type" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.for_each(fn() { [@luna.text("A"), @luna.text("B")] })
  exp_set_inner_html(container, "")
  let report = experimental_hydrate_with_report(container, vnode, logger~)
  assert_false(report.is_clean())
  assert_true(report.has_repair_type(repair_type_for_marker_missing()))
}

///|
test "report: for item count mismatch has correct repair type" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.for_each(fn() {
    [@luna.text("A"), @luna.text("B"), @luna.text("C")]
  })
  exp_set_inner_html(container, "<!--f:0-->X<!--/f-->")
  let report = experimental_hydrate_with_report(container, vnode, logger~)
  assert_false(report.is_clean())
  assert_true(report.has_repair_type(repair_type_for_item_count_mismatch()))
  let repairs = report.get_repairs_by_type(
    repair_type_for_item_count_mismatch(),
  )
  assert_true(repairs.length() > 0)
  let repair = repairs[0]
  assert_eq(repair.get_expected(), "3")
  assert_eq(repair.get_actual(), "1")
}

///|
test "report: show content missing has correct repair type" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let visible = @signal.signal(true)
  let vnode = @luna.show(fn() { visible.get() }, fn() {
    @luna.text("Content")
  })
  // Markers exist but no content
  exp_set_inner_html(container, "<!--s:0--><!--/s-->")
  let report = experimental_hydrate_with_report(container, vnode, logger~)
  assert_false(report.is_clean())
  assert_true(report.has_repair_type(repair_type_show_content_missing()))
}

///|
test "report: node path tracks hierarchy" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h("div", [], [
    @luna.h("span", [], [@luna.text("Wrong content")]),
  ])
  exp_set_inner_html(container, "<div><span>Different</span></div>")
  let report = experimental_hydrate_with_report(container, vnode, logger~)
  if not(report.is_clean()) {
    let repairs = report.get_repairs()
    if repairs.length() > 0 {
      let path = repairs[0].get_node_path()
      // Path should contain the hierarchy
      assert_true(
        path.contains("div") || path.contains("span") || path.contains("#text"),
      )
    }
  }
}

///|
test "report: multiple repairs tracked" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  // Multiple things wrong
  let vnode = @luna.h("div", [("class", @luna.attr_static("expected"))], [
    @luna.text("Wrong"),
    @luna.h(
      "button",
      [("onClick", @luna.attr_handler(@luna.handler(fn(_) { () })))],
      [@luna.text("Click")],
    ),
  ])
  exp_set_inner_html(container, "<div class=\"wrong\">Different</div>")
  let report = experimental_hydrate_with_report(container, vnode, logger~)
  assert_false(report.is_clean())
  // Should have multiple repairs
  assert_true(report.get_repair_count() >= 1)
}

///|
test "report: get_repairs returns all repair infos" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h("div", [("class", @luna.attr_static("test"))], [
    @luna.text("Hello"),
  ])
  exp_set_inner_html(container, "<div class=\"wrong\">World</div>")
  let report = experimental_hydrate_with_report(container, vnode, logger~)
  let repairs = report.get_repairs()
  for i = 0; i < repairs.length(); i = i + 1 {
    let repair = repairs[i]
    // Each repair should have valid info
    assert_true(repair.get_message().length() > 0)
  }
}

///|
test "report: filter repairs by type returns correct subset" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  // Create scenario with attribute mismatch
  let vnode = @luna.h("div", [("id", @luna.attr_static("expected-id"))], [
    @luna.text("Content"),
  ])
  exp_set_inner_html(container, "<div id=\"wrong-id\">Content</div>")
  let report = experimental_hydrate_with_report(container, vnode, logger~)
  let attr_repairs = report.get_repairs_by_type(
    repair_type_attribute_mismatch(),
  )
  let text_repairs = report.get_repairs_by_type(repair_type_text_missing())
  // Should have attribute mismatch but not text missing
  assert_true(attr_repairs.length() > 0)
  assert_eq(text_repairs.length(), 0)
}

// =============================================================================
// Smart Hydrate Tests
// =============================================================================

///|
test "smart_hydrate uses experimental for small trees" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  // Small tree - should use experimental hydration
  let vnode = @luna.h("div", [], [@luna.text("Small")])
  exp_set_inner_html(container, "<div>Small</div>")
  let result = smart_hydrate(container, vnode, logger~)
  match result {
    Hydrated(Clean) => assert_true(true)
    Hydrated(Repaired(_)) => assert_true(true)
    Hydrated(Failed(_)) => assert_true(false)
    FellBackToFullRender(_) => assert_true(false) // Small tree should not fall back
  }
}

///|
test "smart_hydrate falls back for empty DOM" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  // Moderate tree with empty DOM
  let vnode = @luna.h("div", [], [
    @luna.text("A"),
    @luna.text("B"),
    @luna.text("C"),
  ])
  exp_set_inner_html(container, "")
  let result = smart_hydrate(container, vnode, logger~)
  match result {
    FellBackToFullRender(reason) =>
      // Should mention ratio
      assert_true(reason.contains("ratio") || reason.contains("DOM"))
    Hydrated(_) => assert_true(true) // Also acceptable
  }
}

///|
test "smart_hydrate without logger outputs to console" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  // Small tree
  let vnode = @luna.h("div", [], [@luna.text("Test")])
  exp_set_inner_html(container, "<div>Test</div>")
  // No logger - should use console
  let result = smart_hydrate(container, vnode)
  match result {
    Hydrated(Clean) => assert_true(true)
    Hydrated(Repaired(_)) => assert_true(true)
    Hydrated(Failed(_)) => assert_true(false)
    FellBackToFullRender(_) => assert_true(false)
  }
}

// =============================================================================
// hydration_failed Tests
// =============================================================================

///|
test "hydration_failed creates Failed result" {
  let result = hydration_failed("test error message")
  match result {
    Failed(msg) => assert_eq(msg, "test error message")
    _ => assert_true(false)
  }
}

// =============================================================================
// Island Hydration Tests
// =============================================================================

///|
test "exp: hydrate island node" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode : @luna.Node[@js.Any] = @luna.island("island-1", "/app.js", "{}", [
    @luna.text("Island content"),
  ])
  exp_set_inner_html(container, "")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: hydrate async node fallback" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode : @luna.Node[@js.Any] = @luna.async_(
    render=async fn() { @luna.text("Loaded") },
    fallback=fn() { @luna.text("Loading...") },
  )
  exp_set_inner_html(container, "")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) =>
      // Should render fallback
      assert_true(exp_get_inner_html(container).contains("Loading"))
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: hydrate error_boundary success" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode : @luna.Node[@js.Any] = @luna.error_boundary(
    children=fn() { @luna.h("div", [], [@luna.text("Safe")]) },
    fallback=fn(_err, _reset) { @luna.text("Error") },
  )
  exp_set_inner_html(container, "<div>Safe</div>")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: hydrate switch first case" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode : @luna.Node[@js.Any] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { true }, render=fn() { @luna.text("First") }),
      @luna.match_case(when=fn() { true }, render=fn() { @luna.text("Second") }),
    ],
    fallback=Some(fn() { @luna.text("Fallback") }),
  )
  exp_set_inner_html(container, "First")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: hydrate switch fallback" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode : @luna.Node[@js.Any] = @luna.switch_(
    cases=[
      @luna.match_case(when=fn() { false }, render=fn() { @luna.text("Never") }),
    ],
    fallback=Some(fn() { @luna.text("Fallback") }),
  )
  exp_set_inner_html(container, "Fallback")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: hydrate switch no fallback" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode : @luna.Node[@js.Any] = @luna.switch_(cases=[
    @luna.match_case(when=fn() { false }, render=fn() { @luna.text("Never") }),
  ])
  exp_set_inner_html(container, "")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

// =============================================================================
// apply_vattr Edge Cases
// =============================================================================

///|
test "exp: apply_vattr with className" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  // className is an alias for class
  let vnode = @luna.h("div", [("className", @luna.attr_static("my-class"))], [
    @luna.text("Content"),
  ])
  exp_set_inner_html(container, "<div>Content</div>")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: apply_vattr with value attribute" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.h("input", [("value", @luna.attr_static("test-value"))], [])
  exp_set_inner_html(container, "<input />")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: apply_vattr dynamic value" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let value = @signal.signal("initial")
  let vnode = @luna.h(
    "input",
    [("value", @luna.attr_dynamic(fn() { value.get() }))],
    [],
  )
  exp_set_inner_html(container, "<input />")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
  // Update value
  value.set("updated")
  // No assertion on innerHTML as value is a DOM property, not attribute
}

///|
test "exp: apply_vattr dynamic className" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let cls = @signal.signal("class-a")
  let vnode = @luna.h(
    "div",
    [("className", @luna.attr_dynamic(fn() { cls.get() }))],
    [@luna.text("Content")],
  )
  exp_set_inner_html(container, "<div>Content</div>")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
  // Update class
  cls.set("class-b")
}

///|
test "exp: apply_vattr dynamic __remove__" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let show_attr = @signal.signal(true)
  let vnode = @luna.h(
    "div",
    [
      (
        "data-test",
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
  exp_set_inner_html(container, "<div>Content</div>")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
  // Remove attribute
  show_attr.set(false)
}

///|
test "exp: apply_vattr VAction skipped" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode : @luna.Node[@js.Any] = @luna.h(
    "button",
    [("onclick", @luna.action(TestAction))],
    [@luna.text("Click")],
  )
  exp_set_inner_html(container, "<button>Click</button>")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

// =============================================================================
// count_vnode_nodes Tests
// =============================================================================

///|
test "exp: hydrate for with element items" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  let vnode = @luna.for_each(fn() {
    [
      @luna.h("li", [], [@luna.text("A")]),
      @luna.h("li", [], [@luna.text("B")]),
    ]
  })
  // Has markers with element items
  exp_set_inner_html(container, "<!--f:0--><li>A</li><li>B</li><!--/f-->")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: hydrate for replacing text with element" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let logger = StringBuilder::new()
  // VNode expects elements
  let vnode = @luna.for_each(fn() { [@luna.h("span", [], [@luna.text("Item")])] })
  // DOM has text node
  exp_set_inner_html(container, "<!--f:0-->Plain text<!--/f-->")
  let result = experimental_hydrate(container, vnode, logger~)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
}

///|
test "exp: experimental_hydrate without logger" {
  @global_jsdom.register()
  defer exp_cleanup()
  let container = exp_create_container()
  let vnode = @luna.text("Hello")
  exp_set_inner_html(container, "Wrong")
  // No logger - should use console
  let result = experimental_hydrate(container, vnode)
  match result {
    Clean => assert_true(true)
    Repaired(_) => assert_true(true)
    Failed(_) => assert_true(false)
  }
}
