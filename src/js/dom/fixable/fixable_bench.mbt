///|
///| Experimental Hydration (Fixable) Benchmarks
///| Measures performance of morphdom-like DOM diffing/patching during hydration

// =============================================================================
// Helper Functions
// =============================================================================

///|
fn setup_container_with_html(html : String) -> @js_dom.Element {
  let doc = @js_dom.document()
  let container = doc.createElement("div")
  js_set_inner_html(container, html)
  match doc.body() {
    Some(body) => body.appendChild(container.as_node()) |> ignore
    None => ()
  }
  container
}

///|
extern "js" fn js_set_inner_html(elem : @js_dom.Element, html : String) -> Unit =
  #| (elem, html) => { elem.innerHTML = html; }

// =============================================================================
// Clean Hydration (No Repairs Needed)
// =============================================================================

///|
test "fixable_clean_simple" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vnode("div", [], [@ui.vtext("Hello")])
  let html = @ssr.render_to_string(node)
  let logger = StringBuilder::new()
  b.bench(name="fixable_clean_simple", fn() {
    let container = setup_container_with_html(html)
    b.keep(experimental_hydrate(container, node, logger=logger))
  })
}

///|
test "fixable_clean_nested" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vnode(
    "div",
    [],
    [
      @ui.vnode(
        "section",
        [],
        [@ui.vnode("p", [], [@ui.vtext("Nested content")])],
      ),
    ],
  )
  let html = @ssr.render_to_string(node)
  let logger = StringBuilder::new()
  b.bench(name="fixable_clean_nested", fn() {
    let container = setup_container_with_html(html)
    b.keep(experimental_hydrate(container, node, logger=logger))
  })
}

///|
fn create_fixable_list_node(count : Int) -> @ui.Node {
  let items : Array[@ui.Node] = []
  for i = 0; i < count; i = i + 1 {
    items.push(@ui.vnode("li", [], [@ui.vtext("Item " + i.to_string())]))
  }
  @ui.vnode("ul", [], items)
}

///|
test "fixable_clean_list_50" (b : @bench.T) {
  @global_jsdom.register()
  let node = create_fixable_list_node(50)
  let html = @ssr.render_to_string(node)
  let logger = StringBuilder::new()
  b.bench(name="fixable_clean_list_50", fn() {
    let container = setup_container_with_html(html)
    b.keep(experimental_hydrate(container, node, logger=logger))
  })
}

// =============================================================================
// Repair: Text Mismatch
// =============================================================================

///|
test "fixable_repair_text_mismatch" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vnode("div", [], [@ui.vtext("Expected Text")])
  // Simulate server HTML with different text
  let html = "<div>Different Text</div>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_text_mismatch", fn() {
    let container = setup_container_with_html(html)
    b.keep(experimental_hydrate(container, node, logger=logger))
  })
}

///|
test "fixable_repair_text_missing" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vnode("div", [], [@ui.vtext("Expected Text")])
  // Simulate server HTML with empty element
  let html = "<div></div>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_text_missing", fn() {
    let container = setup_container_with_html(html)
    b.keep(experimental_hydrate(container, node, logger=logger))
  })
}

// =============================================================================
// Repair: Element Missing
// =============================================================================

///|
test "fixable_repair_element_missing" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vnode(
    "div",
    [],
    [@ui.vnode("span", [], [@ui.vtext("Child")])],
  )
  // Empty container
  let html = ""
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_element_missing", fn() {
    let container = setup_container_with_html(html)
    b.keep(experimental_hydrate(container, node, logger=logger))
  })
}

// =============================================================================
// Repair: Attribute Mismatch
// =============================================================================

///|
test "fixable_repair_attr_mismatch" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vnode(
    "div",
    [("class", @ui.attr_static("expected-class"))],
    [@ui.vtext("Content")],
  )
  // Simulate server HTML with different class
  let html = "<div class=\"wrong-class\">Content</div>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_attr_mismatch", fn() {
    let container = setup_container_with_html(html)
    b.keep(experimental_hydrate(container, node, logger=logger))
  })
}

// =============================================================================
// Repair: Dynamic Content Markers Missing
// =============================================================================

///|
test "fixable_repair_dynamic_text_marker" (b : @bench.T) {
  @global_jsdom.register()
  let count = @ui.signal(42)
  let node = @ui.text_dyn(fn() { "Count: " + count.get().to_string() })
  // Simulate server HTML without markers
  let html = "Count: 42"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_dynamic_text_marker", fn() {
    let container = setup_container_with_html(html)
    b.keep(experimental_hydrate(container, node, logger=logger))
  })
}

// =============================================================================
// Repair: Show Markers Missing
// =============================================================================

///|
test "fixable_repair_show_marker" (b : @bench.T) {
  @global_jsdom.register()
  let visible = @ui.signal(true)
  let node = @ui.vshow(
    fn() { visible.get() },
    fn() { @ui.vnode("div", [], [@ui.vtext("Visible")]) },
  )
  // Simulate server HTML without show markers
  let html = "<div>Visible</div>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_show_marker", fn() {
    let container = setup_container_with_html(html)
    b.keep(experimental_hydrate(container, node, logger=logger))
  })
}

// =============================================================================
// Repair: For Markers Missing
// =============================================================================

///|
test "fixable_repair_for_marker" (b : @bench.T) {
  @global_jsdom.register()
  let items_sig = @ui.signal(["a", "b", "c"])
  let node = @ui.vfor(fn() {
    items_sig.get().map(fn(item) { @ui.vnode("li", [], [@ui.vtext(item)]) })
  })
  // Simulate server HTML without for markers
  let html = "<li>a</li><li>b</li><li>c</li>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_for_marker", fn() {
    let container = setup_container_with_html(html)
    b.keep(experimental_hydrate(container, node, logger=logger))
  })
}

// =============================================================================
// Repair: For Item Count Mismatch
// =============================================================================

///|
test "fixable_repair_for_item_count" (b : @bench.T) {
  @global_jsdom.register()
  let items_sig = @ui.signal(["a", "b", "c", "d", "e"])
  let node = @ui.vfor(fn() {
    items_sig.get().map(fn(item) { @ui.vnode("li", [], [@ui.vtext(item)]) })
  })
  // Simulate server HTML with fewer items
  let html = "<!--f:0--><li>a</li><li>b</li><!--/f-->"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_for_item_count", fn() {
    let container = setup_container_with_html(html)
    b.keep(experimental_hydrate(container, node, logger=logger))
  })
}

// =============================================================================
// Complex Repair Scenarios
// =============================================================================

///|
fn create_fixable_card(title : String, content : String) -> @ui.Node {
  @ui.vnode(
    "div",
    [("class", @ui.attr_static("card"))],
    [
      @ui.vnode(
        "h3",
        [("class", @ui.attr_static("card-title"))],
        [@ui.vtext(title)],
      ),
      @ui.vnode(
        "p",
        [("class", @ui.attr_static("card-content"))],
        [@ui.vtext(content)],
      ),
    ],
  )
}

///|
test "fixable_repair_multiple_cards" (b : @bench.T) {
  @global_jsdom.register()
  let cards : Array[@ui.Node] = []
  for i = 0; i < 5; i = i + 1 {
    cards.push(create_fixable_card("Card " + i.to_string(), "Content " + i.to_string()))
  }
  let node = @ui.vnode("div", [("class", @ui.attr_static("container"))], cards)
  // Simulate partial server HTML (fewer cards, wrong classes)
  let html = "<div class=\"wrong-container\"><div class=\"card\"><h3>Card 0</h3><p>Old Content</p></div></div>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_repair_multiple_cards", fn() {
    let container = setup_container_with_html(html)
    b.keep(experimental_hydrate(container, node, logger=logger))
  })
}

// =============================================================================
// Detailed Report Benchmarks
// =============================================================================

///|
test "fixable_with_report_clean" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vnode("div", [], [@ui.vtext("Hello")])
  let html = @ssr.render_to_string(node)
  let logger = StringBuilder::new()
  b.bench(name="fixable_with_report_clean", fn() {
    let container = setup_container_with_html(html)
    b.keep(experimental_hydrate_with_report(container, node, logger=logger))
  })
}

///|
test "fixable_with_report_repairs" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vnode(
    "div",
    [("class", @ui.attr_static("expected"))],
    [@ui.vtext("Expected")],
  )
  let html = "<div class=\"wrong\">Wrong</div>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_with_report_repairs", fn() {
    let container = setup_container_with_html(html)
    b.keep(experimental_hydrate_with_report(container, node, logger=logger))
  })
}

// =============================================================================
// Fallback Strategy Benchmark
// =============================================================================

///|
test "fixable_hydrate_with_fallback" (b : @bench.T) {
  @global_jsdom.register()
  let node = @ui.vnode("div", [], [@ui.vtext("Content")])
  // Intentionally mismatched HTML to trigger fallback
  let html = "<span>Wrong tag</span>"
  let logger = StringBuilder::new()
  b.bench(name="fixable_hydrate_with_fallback", fn() {
    let container = setup_container_with_html(html)
    b.keep(hydrate_with_fallback(container, node, logger=logger))
  })
}
