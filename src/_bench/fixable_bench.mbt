//
// Experimental Hydration (Fixable) Benchmarks
//

///|
/// Measures performance of morphdom-like DOM diffing/patching during hydration

// =============================================================================
// Helper Functions
// =============================================================================

// Global container reused across benchmarks to prevent memory leak
let fixable_bench_container : Ref[@js_dom.Element?] = { val: None }

///|
fn get_or_create_fixable_container() -> @js_dom.Element {
  match fixable_bench_container.val {
    Some(c) => c
    None => {
      let doc = @js_dom.document()
      let container = doc.createElement("div")
      container.setAttribute("id", "fixable-bench-container")
      match doc.body() {
        Some(body) => body.appendChild(container.as_node()) |> ignore
        None => ()
      }
      fixable_bench_container.val = Some(container)
      container
    }
  }
}

///|
fn setup_fixable_container(html : String) -> @js_dom.Element {
  let container = get_or_create_fixable_container()
  fixable_set_inner_html(container, html)
  container
}

///|
extern "js" fn fixable_set_inner_html(
  elem : @js_dom.Element,
  html : String,
) -> Unit =
  #| (elem, html) => { elem.innerHTML = html; }

// =============================================================================
// Clean Hydration (No Repairs Needed)
// =============================================================================

///|
test "fixable_clean_simple" (b : @bench.T) {
  @global_jsdom.register()
  let node = @luna.h("div", [], [@luna.text("Hello")])
  let html = @ssr.render_to_string(node).html
  let logger = StringBuilder::new()
  b.bench(name="fixable_clean_simple", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
test "fixable_clean_nested" (b : @bench.T) {
  @global_jsdom.register()
  let node = @luna.h("div", [], [
    @luna.h("section", [], [@luna.h("p", [], [@luna.text("Nested content")])]),
  ])
  let html = @ssr.render_to_string(node).html
  let logger = StringBuilder::new()
  b.bench(name="fixable_clean_nested", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
fn create_fixable_list_node(count : Int) -> @luna.Node[@js.Any] {
  let items : Array[@luna.Node[@js.Any]] = []
  for i = 0; i < count; i = i + 1 {
    items.push(@luna.h("li", [], [@luna.text("Item " + i.to_string())]))
  }
  @luna.h("ul", [], items)
}

///|
test "fixable_clean_list_50" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_fixable_list_node(50)
  let html = @ssr.render_to_string(node).html
  let logger = StringBuilder::new()
  b.bench(name="fixable_clean_list_50", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

// =============================================================================
// Repair: Text Mismatch
// =============================================================================

///|
test "fixable_repair_text_mismatch" (b : @bench.T) {
  @global_jsdom.register()
  let node = @luna.h("div", [], [@luna.text("Expected Text")])
  let html = "<div>Different Text</div>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_text_mismatch", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
test "fixable_repair_text_missing" (b : @bench.T) {
  @global_jsdom.register()
  let node = @luna.h("div", [], [@luna.text("Expected Text")])
  let html = "<div></div>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_text_missing", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

// =============================================================================
// Repair: Element Missing
// =============================================================================

///|
test "fixable_repair_element_missing" (b : @bench.T) {
  @global_jsdom.register()
  let node = @luna.h("div", [], [@luna.h("span", [], [@luna.text("Child")])])
  let html = ""
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_element_missing", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

// =============================================================================
// Repair: Attribute Mismatch
// =============================================================================

///|
test "fixable_repair_attr_mismatch" (b : @bench.T) {
  @global_jsdom.register()
  let node = @luna.h("div", [("class", @luna.attr_static("expected-class"))], [
    @luna.text("Content"),
  ])
  let html = "<div class=\"wrong-class\">Content</div>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_attr_mismatch", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

// =============================================================================
// Repair: Dynamic Content Markers
// =============================================================================

///|
test "fixable_repair_dynamic_text_marker" (b : @bench.T) {
  @global_jsdom.register()
  let count = @signal.signal(42)
  let node = @luna.text_dyn(fn() { "Count: " + count.get().to_string() })
  let html = "Count: 42"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_dynamic_text_marker", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
test "fixable_repair_show_marker" (b : @bench.T) {
  @global_jsdom.register()
  let visible = @signal.signal(true)
  let node = @luna.show(fn() { visible.get() }, fn() {
    @luna.h("div", [], [@luna.text("Visible")])
  })
  let html = "<div>Visible</div>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_show_marker", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
test "fixable_repair_for_marker" (b : @bench.T) {
  @global_jsdom.register()
  let items_sig = @signal.signal(["a", "b", "c"])
  let node = @luna.for_each(fn() {
    items_sig.get().map(fn(item) { @luna.h("li", [], [@luna.text(item)]) })
  })
  let html = "<li>a</li><li>b</li><li>c</li>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_for_marker", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
test "fixable_repair_for_item_count" (b : @bench.T) {
  @global_jsdom.register()
  let items_sig = @signal.signal(["a", "b", "c", "d", "e"])
  let node = @luna.for_each(fn() {
    items_sig.get().map(fn(item) { @luna.h("li", [], [@luna.text(item)]) })
  })
  let html = "<!--f:0--><li>a</li><li>b</li><!--/f-->"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_for_item_count", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

// =============================================================================
// Complex Scenarios
// =============================================================================

///|
fn create_fixable_card(title : String, content : String) -> @luna.Node[@js.Any] {
  @luna.h("div", [("class", @luna.attr_static("card"))], [
    @luna.h("h3", [("class", @luna.attr_static("card-title"))], [
      @luna.text(title),
    ]),
    @luna.h("p", [("class", @luna.attr_static("card-content"))], [
      @luna.text(content),
    ]),
  ])
}

///|
test "fixable_repair_multiple_cards" (b : @bench.T) {
  @global_jsdom.register()
  let cards : Array[@luna.Node[@js.Any]] = []
  for i = 0; i < 5; i = i + 1 {
    cards.push(
      create_fixable_card("Card " + i.to_string(), "Content " + i.to_string()),
    )
  }
  let node = @luna.h("div", [("class", @luna.attr_static("container"))], cards)
  let html = "<div class=\"wrong-container\"><div class=\"card\"><h3>Card 0</h3><p>Old Content</p></div></div>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_multiple_cards", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

// =============================================================================
// Report and Fallback
// =============================================================================

///|
test "fixable_with_report_clean" (b : @bench.T) {
  @global_jsdom.register()
  let node = @luna.h("div", [], [@luna.text("Hello")])
  let html = @ssr.render_to_string(node).html
  let logger = StringBuilder::new()
  b.bench(name="fixable_with_report_clean", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate_with_report(container, node, logger~))
  })
}

///|
test "fixable_with_report_repairs" (b : @bench.T) {
  @global_jsdom.register()
  let node = @luna.h("div", [("class", @luna.attr_static("expected"))], [
    @luna.text("Expected"),
  ])
  let html = "<div class=\"wrong\">Wrong</div>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_with_report_repairs", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate_with_report(container, node, logger~))
  })
}

///|
test "fixable_hydrate_with_fallback" (b : @bench.T) {
  @global_jsdom.register()
  let node = @luna.h("div", [], [@luna.text("Content")])
  let html = "<span>Wrong tag</span>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_hydrate_with_fallback", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.hydrate_with_fallback(container, node, logger~))
  })
}
