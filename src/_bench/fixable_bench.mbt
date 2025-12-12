///|

///| Experimental Hydration (Fixable) Benchmarks

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
  let node = @kaguya.h("div", [], [@kaguya.vtext("Hello")])
  let html = @ssr.render_to_string(node)
  let logger = StringBuilder::new()
  b.bench(name="fixable_clean_simple", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
test "fixable_clean_nested" (b : @bench.T) {
  @global_jsdom.register()
  let node = @kaguya.h("div", [], [
    @kaguya.h("section", [], [
      @kaguya.h("p", [], [@kaguya.vtext("Nested content")]),
    ]),
  ])
  let html = @ssr.render_to_string(node)
  let logger = StringBuilder::new()
  b.bench(name="fixable_clean_nested", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate(container, node, logger~))
  })
}

///|
fn create_fixable_list_node(count : Int) -> @kaguya.Node[@core.Any] {
  let items : Array[@kaguya.Node[@core.Any]] = []
  for i = 0; i < count; i = i + 1 {
    items.push(@kaguya.h("li", [], [@kaguya.vtext("Item " + i.to_string())]))
  }
  @kaguya.h("ul", [], items)
}

///|
test "fixable_clean_list_50" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_fixable_list_node(50)
  let html = @ssr.render_to_string(node)
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
  let node = @kaguya.h("div", [], [@kaguya.vtext("Expected Text")])
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
  let node = @kaguya.h("div", [], [@kaguya.vtext("Expected Text")])
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
  let node = @kaguya.h("div", [], [
    @kaguya.h("span", [], [@kaguya.vtext("Child")]),
  ])
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
  let node = @kaguya.h(
    "div",
    [("class", @kaguya.attr_static("expected-class"))],
    [@kaguya.vtext("Content")],
  )
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
  let node = @kaguya.text_dyn(fn() { "Count: " + count.get().to_string() })
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
  let node = @kaguya.vshow(fn() { visible.get() }, fn() {
    @kaguya.h("div", [], [@kaguya.vtext("Visible")])
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
  let node = @kaguya.vfor(fn() {
    items_sig.get().map(fn(item) { @kaguya.h("li", [], [@kaguya.vtext(item)]) })
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
  let node = @kaguya.vfor(fn() {
    items_sig.get().map(fn(item) { @kaguya.h("li", [], [@kaguya.vtext(item)]) })
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
fn create_fixable_card(title : String, content : String) -> @kaguya.Node[@core.Any] {
  @kaguya.h("div", [("class", @kaguya.attr_static("card"))], [
    @kaguya.h("h3", [("class", @kaguya.attr_static("card-title"))], [
      @kaguya.vtext(title),
    ]),
    @kaguya.h("p", [("class", @kaguya.attr_static("card-content"))], [
      @kaguya.vtext(content),
    ]),
  ])
}

///|
test "fixable_repair_multiple_cards" (b : @bench.T) {
  @global_jsdom.register()
  let cards : Array[@kaguya.Node[@core.Any]] = []
  for i = 0; i < 5; i = i + 1 {
    cards.push(
      create_fixable_card("Card " + i.to_string(), "Content " + i.to_string()),
    )
  }
  let node = @kaguya.h(
    "div",
    [("class", @kaguya.attr_static("container"))],
    cards,
  )
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
  let node = @kaguya.h("div", [], [@kaguya.vtext("Hello")])
  let html = @ssr.render_to_string(node)
  let logger = StringBuilder::new()
  b.bench(name="fixable_with_report_clean", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.experimental_hydrate_with_report(container, node, logger~))
  })
}

///|
test "fixable_with_report_repairs" (b : @bench.T) {
  @global_jsdom.register()
  let node = @kaguya.h("div", [("class", @kaguya.attr_static("expected"))], [
    @kaguya.vtext("Expected"),
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
  let node = @kaguya.h("div", [], [@kaguya.vtext("Content")])
  let html = "<span>Wrong tag</span>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_hydrate_with_fallback", fn() {
    let container = setup_fixable_container(html)
    b.keep(@fixable.hydrate_with_fallback(container, node, logger~))
  })
}
